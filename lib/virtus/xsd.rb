require "virtus/xsd/version"

module Virtus
  module Xsd
    autoload :XsdParser, 'virtus/xsd/parser/xsd_parser'
    autoload :TypeDefinition, 'virtus/xsd/type_definition'
    autoload :AttributeDefinition, 'virtus/xsd/attribute_definition'
    autoload :RubyGenerator, 'virtus/xsd/generation/ruby_generator'
  end
end
