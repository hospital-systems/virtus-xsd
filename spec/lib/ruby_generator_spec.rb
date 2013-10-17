require 'spec_helper'

describe Virtus::Xsd::RubyGenerator do
  let(:spec_dir) { File.expand_path('../..', __FILE__) }
  let(:output_dir) { File.join(spec_dir, 'tmp') }
  let(:xsd) { File.read(File.join(spec_dir, 'fixtures/sample.xsd')) }
  let(:type_definitions) { Virtus::Xsd::XsdParser.parse(xsd).values }

  before do
    FileUtils.rm_f(output_dir)
  end

  subject do
    Virtus::Xsd::RubyGenerator.new(type_definitions, module_name: 'Test', output_dir: output_dir)
  end

  it 'should generate ruby classes by type definitions' do
    subject.generate_classes
    expect { load File.join(output_dir, 'test', 'country.rb') }.to_not raise_error
    Object.const_defined?(:Test).should be_true
    Test.const_defined?(:Country).should be_true
  end
end
