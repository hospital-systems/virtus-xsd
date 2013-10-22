require 'active_support/core_ext/hash/keys'
require 'virtus/xsd/parser/document_set'
require 'virtus/xsd/parser/lookup_context'

module Virtus
  module Xsd
    class Parser

      def self.parse(xsd_path, config = {})
        new(xsd_path, config).parse
      end

      def initialize(xsd_path, config = {})
        @scope = DocumentSet.load(xsd_path)
        @config = config
      end

      def parse
        collect_type_definitions
        type_registry.values
      end

      protected

      attr_reader :scope
      attr_accessor :type_registry

      def fill_attributes(lookup_context, type_definition, node)
        type_definition.superclass = get_superclass(lookup_context, node)
        attributes = collect_attributes(lookup_context, node)
        attributes += collect_extended_attributes(lookup_context, node)
        attributes.each do |attr|
          type_definition.attributes[attr.name] = attr
        end
      end

      def get_superclass(lookup_context, node)
        xpath = 'xs:complexContent/*[local-name()="extension" or local-name()="restriction"]/@base'
        base = node.xpath(xpath).first
        base && get_type_definition(lookup_context.lookup_type(base.text), lookup_context)
      end

      def collect_extended_attributes(lookup_context, node)
        node.xpath('xs:complexContent/xs:extension').map do |extension_node|
          collect_attributes(lookup_context, extension_node)
        end.flatten
      end

      def collect_attributes(lookup_context, node)
        (node.xpath('xs:attribute') + node.xpath('xs:sequence/xs:element')).map do |element|
          attr_name = element['name'] || without_namespace(element['ref'])
          if (base_type_definition = base_type_definitions[element['type']])
            AttributeDefinition.new(attr_name, base_type_definition)
          else
            attr_type = resolve_type(lookup_context, element)
            attr_typedef = get_type_definition(attr_type, lookup_context)
            #raise "Unknown type: #{attr_type}" unless type_registry.key?(attr_type)
            AttributeDefinition.new(attr_name, attr_typedef)
          end
        end
      end

      def collect_type_definitions
        self.type_registry = {}
        scope.scoped_documents.each do |doc|
          doc.types.each do |type|
            build_type_definition(type)
          end
        end
        self.type_registry = type_registry.each_with_object({}) do |(_, typedef), acc|
          acc[typedef.name] = typedef
        end
      end

      def get_type_definition(type, parent_lookup_context = nil)
        type_registry[type] || build_type_definition(type, parent_lookup_context)
      end

      def build_type_definition(type, parent_lookup_context = nil)
        if @config.key?(type['name'])
          type_info = @config[type['name']].symbolize_keys
          type_registry[type] = Virtus::Xsd::TypeDefinition.new(type_info.delete(:name), type_info)
        else
          lookup_context = LookupContext.create(type.document, parent_lookup_context)
          type_definition = TypeDefinition.new(type['name'])
          type_registry[type] = type_definition
          fill_attributes(lookup_context, type_definition, type.node)
          type_definition
        end
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

      def without_namespace(name)
        name.split(':').last
      end

      def resolve_type(lookup_context, node)
        if node['ref']
          referenced_node = lookup_context.lookup_attribute(node['ref']) ||
            lookup_context.lookup_element(node['ref'])
          fail "Can't find referenced #{node.name} by name '#{node['ref']}'" if referenced_node.nil?
          LookupContext.create(referenced_node.document, lookup_context).lookup_type(referenced_node['type'])
        else
          lookup_context.lookup_type(node['type'])
        end
      end
    end
  end
end