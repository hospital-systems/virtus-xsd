module Virtus
  module Xsd
    class XsdParser
      def self.parse(xsd_content, config = {})
        new(Nokogiri::XML(xsd_content), config).parse
      end

      def initialize(xsd_document, config = {})
        @xsd_document = xsd_document
        @config = config
      end

      def parse
        nodes = complex_type_nodes
        type_definitions = collect_type_definitions(nodes)
        apply_overrides(type_definitions)
        fill_attributes(nodes, type_definitions.merge(base_type_definitions))
        type_definitions.values
      end

      private

      attr_reader :xsd_document

      def fill_attributes(nodes, type_definitions)
        nodes.each do |node|
          type_definition = type_definitions[node['name']]
          next if type_overridden?(type_definition)
          node.xpath('xs:sequence/xs:element').each do |element|
            attr_name = element['name']
            attr_type = type_definitions[element['type']]
            raise "Unknown type #{element['type']}" unless attr_type
            type_definition.attributes[attr_name] = AttributeDefinition.new(attr_name, attr_type)
          end
        end
      end

      def collect_type_definitions(nodes)
        nodes.each_with_object({}) do |node, type_definitions|
          type_definitions[node['name']] = TypeDefinition.new(node['name'])
        end
      end

      def base_type_definitions
        @base_type_definitions ||= {
          'xs:string' => TypeDefinition.new('String'),
          'xs:decimal' => TypeDefinition.new('Numeric')
        }
      end

      def complex_type_nodes
        xsd_document.xpath('xs:schema/xs:complexType')
      end

      def type_overridden?(type_definition)
        @config.key?(type_definition.name)
      end

      def apply_overrides(type_definitions)
        @config.each_pair do |type_name, type_info|
          type_info = type_info.symbolize_keys
          type_definitions[type_name] = Virtus::Xsd::TypeDefinition.new(type_info.delete(:name), type_info)
        end
      end
    end
  end
end