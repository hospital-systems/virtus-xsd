module Virtus
  module Xsd
    class XsdParser
      def self.parse(xsd_document)
        new(xsd_document).parse
      end

      def initialize(xsd_document)
        @xsd_document = xsd_document
      end

      def parse
        nodes = complex_type_nodes
        type_definitions = collect_type_definitions(nodes)
        fill_attributes(type_definitions, nodes)
        type_definitions
      end

      private

      attr_reader :xsd_document

      def fill_attributes(type_definitions, nodes)
        nodes.each do |node|
          type_definition = type_definitions[node['name']]
          node.xpath('xs:sequence/xs:element').each do |element|
            type_definition.attributes[element['name']] = AttributeDefinition.new(element['name'])
          end
        end
      end

      def collect_type_definitions(nodes)
        nodes.each_with_object({}) do |node, type_definitions|
          type_definitions[node['name']] = TypeDefinition.new(node['name'])
        end
      end

      def complex_type_nodes
        xsd_document.xpath('xs:schema/xs:complexType')
      end
    end
  end
end