require 'spec_helper'

describe Virtus::Xsd::XsdParser do
  let(:xsd) { Nokogiri::XML(File.read(File.expand_path('../../fixtures/sample.xsd', __FILE__))) }

  class HaveAttributeMatcher
    def initialize(name)
      @name = name
    end

    def matches?(type_definition)
      @type_definition = type_definition
      type_definition[@name] != nil && type_definition[@name].name == @name
    end

    def failure_message
      "expected type '#{@type_definition.name}' to has attribute '#{@name}', but it doesn't"
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
    country.should have_attribute('country_name')
    country.should have_attribute('population')
  end
end
