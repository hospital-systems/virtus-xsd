require 'ostruct'
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
        @type_registry = {}
      end

      def parse
        scope.scoped_documents.map do |doc|
          doc.types.map { |type| get_type_definition(type, root_lookup_context) }
        end.flatten
      end

      protected

      attr_reader :scope
      attr_reader :type_registry

      def get_type_definition(type, parent_lookup_context = nil)
        type_registry[type] || override_type(type) || build_type_definition(type, parent_lookup_context)
      end

      def type_overrides
        @type_overrides ||= @config['types'] || {}
      end

      def override_type(type)
        if (type_info = type_overrides[type.type.name])
          define_type(type, type_info.symbolize_keys)
        end
      end

      def build_type_definition(type, parent_lookup_context = nil)
        define_type(type, name: type.type.name, simple: !type.type.complex) do |type_definition|
          lookup_context = LookupContext.create(type.document, parent_lookup_context)
          type_definition.superclass = get_superclass(lookup_context, type.type)

          fill_attributes(lookup_context, type_definition, type.type)
        end
      end

      def get_superclass(lookup_context, type)
        return unless type.base
        base_type_definitions[type.base] ||
          get_type_definition(lookup_context.lookup_type(type.base), lookup_context)
      end

      def fill_attributes(lookup_context, type_definition, type)
        collect_attributes(lookup_context, type).each do |attr|
          type_definition.attributes[attr.name] = attr
        end
      end

      def collect_attributes(lookup_context, type)
        type.attributes.map do |element|
          define_attribute(element, lookup_context)
        end
      end

      def define_attribute(element, lookup_context)
        attr_name = element['name'] || without_namespace(element['ref'])

        if (base_type_definition = base_type_definitions[element['type']])
          AttributeDefinition.new(attr_name, base_type_definition)
        else
          attr_type = resolve_type(lookup_context, element)
          attr_typedef = get_type_definition(attr_type, lookup_context)
          AttributeDefinition.new(attr_name, attr_typedef)
        end
      end

      def define_type(type, type_info)
        (type_registry[type] = Virtus::Xsd::TypeDefinition.new(type_info.delete(:name), type_info)).tap do |type_definition|
          yield(type_definition) if block_given?
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
        resolve_type_by_ref(lookup_context, node) || lookup_context.lookup_type(node['type'])
      end

      def resolve_type_by_ref(lookup_context, node)
        if (ref = node['ref'])
          ref_node = lookup_context.lookup_attribute(ref) || lookup_context.lookup_element(ref)
          fail "Can't find referenced #{node.name} by name '#{ref}'" if ref_node.nil?

          ref_lookup_content = LookupContext.create(ref_node.document, lookup_context)
          ref_lookup_content.lookup_type(ref_node['type'])
        end
      end

      def add_base_type(doc, type_name, opts = {})
        doc.types ||= []
        doc.types << OpenStruct.new(name: type_name).tap do |type|
          define_type(type, opts)
        end
      end

      def base_document
        Document.new.tap do |doc|
          doc.urn = 'http://www.w3.org/2001/XMLSchema'
          add_base_type(doc, 'string', name: 'String')
        end
      end

      def root_lookup_context
        @root_lookup_context ||= LookupContext.new.tap do |ctx|
          ctx.add('xs', DocumentSet.new([base_document]))
        end
      end
    end
  end
end