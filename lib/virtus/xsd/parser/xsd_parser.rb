require 'active_support/core_ext/hash/keys'

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

      def fill_attributes(nodes, type_registry)
        nodes.each do |node|
          type_definition = type_registry[node['name']]
          next if type_overridden?(type_definition)
          type_definition.superclass = get_superclass(node, type_registry)
          attributes = collect_attributes(node, type_registry)
          attributes += collect_extended_attributes(node, type_registry)
          attributes.each do |attr|
            type_definition.attributes[attr.name] = attr
          end
        end
      end

      def get_superclass(node, type_registry)
        xpath = 'xs:complexContent/*[local-name()="extension" or local-name()="restriction"]/@base'
        base = node.xpath(xpath).first
        base && type_registry[base.text]
      end

      def collect_extended_attributes(node, type_registry)
        node.xpath('xs:complexContent/xs:extension').map do |extension_node|
          collect_attributes(extension_node, type_registry)
        end.flatten
      end

      def collect_attributes(node, type_registry)
        (node.xpath('xs:attribute') + node.xpath('xs:sequence/xs:element')).map do |element|
          attr_name = element['name']
          attr_type = type_registry[element['type']]
          raise "Unknown type #{element['type']}" unless attr_type
          AttributeDefinition.new(attr_name, attr_type)
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
          'xs:decimal' => TypeDefinition.new('Numeric'),
          'xs:float' => TypeDefinition.new('Float'),
          'xs:boolean' => TypeDefinition.new('Boolean')
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