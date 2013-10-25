require 'spec_helper'
require 'active_support/core_ext/enumerable'

describe Virtus::Xsd::Parser do
  let(:fixtures_dir) { File.expand_path('../../fixtures', __FILE__) }
  let(:xsd) { File.join(fixtures_dir, 'sample.xsd') }
  let(:config) { YAML::load(File.read(File.join(fixtures_dir, 'config.yml'))) }

  let(:parsed_types) { described_class.parse(xsd, config).index_by(&:name) }

  def have_attribute(name)
    HaveAttributeMatcher.new(name)
  end

  it 'should parse complex type' do
    country = parsed_types['Country']
    country.should_not be_nil
    country.name.should == 'Country'
    country.should_not be_simple
    country.should have_attribute('name').of_type('String')
    country.should have_attribute('population').of_type('quantity')
    country.should have_attribute('city').of_type('City')
  end

  it 'should apply types overrides' do
    parsed_types['Object'].should_not be_nil
    parsed_types['ANY'].should be_nil
    city = parsed_types['City']
    city.should have_attribute('crest').of_type('Object')
  end

  it 'should parse extending types' do
    parsed_types['Object'].should_not be_nil
  end

  it 'should parse simple types' do
    quantity = parsed_types['quantity']
    quantity.should be_simple
  end

  it 'should parse union types' do
    global_nation = parsed_types['Nationality']
    global_nation.should be_simple
    global_nation.superclass.name.should == 'SlavicNationality'
  end

  it 'should parse list types' do
    country = parsed_types['Country']
    country.should have_attribute('languages')
    country['languages'].type.item_type.name.should == 'Language'
  end

  it 'should generate multiple attributes' do
    country = parsed_types['Country']
    country['name'].should_not be_multiple
    country['city'].should be_multiple
  end

  it 'should parse anonymous simple type' do
    country = parsed_types['Country']
    country.should have_attribute('formOfGovernment')
    country['formOfGovernment'].type.name.should == 'Country.formOfGovernment'
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
