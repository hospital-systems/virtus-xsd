require 'spec_helper'

describe Virtus::Xsd::XsdParser do
  let(:xsd) { Nokogiri::XML(File.read(File.expand_path('../../fixtures/sample.xsd', __FILE__))) }

  class HaveAttributeMatcher
    def initialize(name_or_opts)
      if name_or_opts.is_a?(String)
        @options = {name: name_or_opts}
      else
        @options = name_or_opts
      end
    end

    def matches?(type_definition)
      @type_definition = type_definition
      name, type = @options[:name], @options[:type]
      return unless (attribute = type_definition[name])
      attribute.name == name && attribute.type.name == type
    end

    def failure_message
      message = "expect type '#{@type_definition.name}' to has attribute '#{@options[:name]}'"
      message << " of type #{@options[:type]}" if @options[:type]
      message
    end

    def of_type(type_name)
      self.class.new(@options.merge(type: type_name))
    end
  end

  def have_attribute(name)
    HaveAttributeMatcher.new(name)
  end

  it 'should parse sample.xsd' do
    type_definitions = described_class.parse(xsd)
    country = type_definitions['Country']
    country.should_not be_nil
    country.name.should == 'Country'
    country.should have_attribute('country_name').of_type('String')
    country.should have_attribute('population').of_type('Numeric')
    country.should have_attribute('city').of_type('City')
  end
end
