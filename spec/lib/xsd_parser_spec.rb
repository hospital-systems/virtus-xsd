require 'spec_helper'
require 'active_support/core_ext/enumerable'

describe Virtus::Xsd::XsdParser do
  let(:fixtures_dir) { File.expand_path('../../fixtures', __FILE__) }
  let(:xsd) { File.read(File.join(fixtures_dir, 'sample.xsd')) }
  let(:config) { YAML::load(File.read(File.join(fixtures_dir, 'config.yml'))) }

  let(:parsed_types) { described_class.parse(xsd, config).index_by(&:name) }

  def have_attribute(name)
    HaveAttributeMatcher.new(name)
  end

  it 'should parse complex type' do
    country = parsed_types['Country']
    country.should_not be_nil
    country.name.should == 'Country'
    country.should have_attribute('country_name').of_type('String')
    country.should have_attribute('population').of_type('Numeric')
    country.should have_attribute('city').of_type('City')
  end

  it 'should apply types overrides' do
    parsed_types['Object'].should_not be_nil
    parsed_types['ANY'].should be_nil
    city = parsed_types['City']
    city.should have_attribute('crest').of_type('Object')
  end

  class HaveAttributeMatcher
    attr_reader :failure_message

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
      unless (attribute = type_definition[name]) && attribute.name == name
        @failure_message = "expect type '#{@type_definition.name}' to has attribute '#{@options[:name]}'"
        return
      end
      if !type.nil? && attribute.type.name != type
        @failure_message = "expect '#{@type_definition.name}##{@options[:name]}'" +
          " to has type '#{@options[:type]}', but has type '#{attribute.type.name}'"
        return
      end
      true
    end

    def of_type(type_name)
      self.class.new(@options.merge(type: type_name))
    end
  end
end
