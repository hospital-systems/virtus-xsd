require 'active_support/core_ext/hash/keys'
require 'virtus/xsd/parser/scope'
require 'virtus/xsd/parser/queries'

module Virtus
  module Xsd
    class Parser
      include Queries

      def self.parse(xsd_path, config = {})
        new(xsd_path, config).parse
      end

      def initialize(xsd_path, config = {})
        @scope = Virtus::Xsd::Parser::Scope.new(xsd_path)
        @config = config
      end

      def parse
        nodes = scope.simple_types + scope.complex_types
        collect_type_definitions(nodes)
        apply_overrides
        fill_attributes(nodes)
        type_registry.values
      end

      private

      attr_reader :scope
      attr_accessor :type_registry

      def fill_attributes(nodes)
        nodes.each do |node|
          type_definition = type_registry[node['name']]
          next if type_overridden?(type_definition)
          type_definition.superclass = get_superclass(node)
          attributes = collect_attributes(node)
          attributes += collect_extended_attributes(node)
          attributes.each do |attr|
            type_definition.attributes[attr.name] = attr
          end
        end
      end

      def get_superclass(node)
        xpath = 'xs:complexContent/*[local-name()="extension" or local-name()="restriction"]/@base'
        base = node.xpath(xpath).first
        base && type_registry[base.text]
      end

      def collect_extended_attributes(node)
        node.xpath('xs:complexContent/xs:extension').map do |extension_node|
          collect_attributes(extension_node)
        end.flatten
      end

      def collect_attributes(node)
        (node.xpath('xs:attribute') + node.xpath('xs:sequence/xs:element')).map do |element|
          attr_name = element['name'] || element['ref']
          attr_type = resolve_type(element)
          raise "Unknown type: #{attr_type}" unless type_registry.key?(attr_type)
          AttributeDefinition.new(attr_name, type_registry[attr_type])
        end
      end

      def collect_type_definitions(nodes)
        self.type_registry = nodes.each_with_object({}) do |node, type_definitions|
          type_definitions[node['name']] = TypeDefinition.new(node['name'])
        end.merge(base_type_definitions)
      end

      def base_type_definitions
        @base_type_definitions ||= {
          'xs:string' => TypeDefinition.new('String'),
          'xs:decimal' => TypeDefinition.new('Numeric'),
          'xs:float' => TypeDefinition.new('Float'),
          'xs:integer' => TypeDefinition.new('Integer'),
          'xs:boolean' => TypeDefinition.new('Boolean')
        }
      end

      def type_overridden?(type_definition)
        @config.key?(type_definition.name)
      end

      def apply_overrides
        @config.each_pair do |type_name, type_info|
          type_info = type_info.symbolize_keys
          type_registry[type_name] = Virtus::Xsd::TypeDefinition.new(type_info.delete(:name), type_info)
        end
      end

      def resolve_type(node)
        if node['ref']
          referenced_node = find_attribute_or_element_by_name(node['ref'])
          fail "Can't find referenced #{node.tag_name} by name '#{node['ref']}'" if referenced_node.nil?
          referenced_node['type']
        else
          node['type']
        end
      end
    end
  end
end