require 'spec_helper'
require 'virtus'
require 'yaml'

describe Virtus::Xsd::RubyGenerator do
  let(:spec_dir) { File.expand_path('../..', __FILE__) }
  let(:output_dir) { File.join(spec_dir, 'tmp') }
  let(:xsd_path) { File.join(spec_dir, 'fixtures', 'sample.xsd') }
  let(:config) { YAML::load(File.read(File.join(spec_dir, 'fixtures', 'config.yml'))) }
  let(:type_definitions) { Virtus::Xsd::Parser.parse(xsd_path, config) }

  before :each do
    FileUtils.rm_rf(output_dir)
  end

  subject do
    Virtus::Xsd::RubyGenerator.new(type_definitions, module_name: 'Test', output_dir: output_dir)
  end

  before do
    subject.generate_classes
  end

  it 'should generate ruby classes by type definitions' do
    expect { load File.join(output_dir, 'test', 'country.rb') }.to_not raise_error
    Object.const_defined?(:Test).should be_true
    Test.const_defined?(:Country).should be_true
    Test::Country.should respond_to :attribute_set
    Test::Country.attribute_set[:name].should_not be_nil
  end

  it 'should not generate base types' do
    File.exist?(File.join(output_dir, 'test', 'object.rb')).should be_false
  end
end
