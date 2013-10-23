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

      def type_renames
        @type_renames ||= @config['names'] || {}
      end

      def override_type(type)
        if (type_info = type_overrides[type.type.name])
          define_type(type, type_info.symbolize_keys)
        end
      end

      def build_type_definition(type_ref, parent_ctx = nil)
        type = type_ref.type
        define_type(type_ref, name: apply_renaming(type.name), simple: !type.complex) do |type_def|
          ctx = LookupContext.create(type_ref.document, parent_ctx)
          type_def.item_type = get_type_definition(ctx.lookup_type(type.item_type), ctx) if type.item_type
          type_def.superclass = get_type_definition(ctx.lookup_type(type.base), ctx) if type.base
          type.attributes.map { |attr_node| define_attribute(type_def, attr_node, ctx) }
        end
      end

      def apply_renaming(name)
        type_renames.fetch(name, name)
      end

      def define_attribute(type_definition, attr_node, lookup_context)
        attr_name = attr_node['name'] || without_namespace(attr_node['ref'])
        attr_type = resolve_type(lookup_context, attr_node)
        attr_typedef = get_type_definition(attr_type, lookup_context)
        multiple = attr_node['maxOccurs'] == 'unbounded'
        type_definition.attributes[attr_name] =
          Virtus::Xsd::AttributeDefinition.new(attr_name, attr_typedef, multiple: multiple)
      end

      def define_type(type, type_info)
        (type_registry[type] = Virtus::Xsd::TypeDefinition.new(type_info.delete(:name), type_info)).tap do |type_definition|
          yield(type_definition) if block_given?
        end
      end

      def without_namespace(name)
        name.split(':').last
      end

      def resolve_type(lookup_context, attr_node)
        resolve_type_by_ref(lookup_context, attr_node) || lookup_context.lookup_type(attr_node['type'])
      end

      def resolve_type_by_ref(lookup_context, attr_node)
        if (ref = attr_node['ref'])
          ref_node = lookup_context.lookup_attribute(ref) || lookup_context.lookup_element(ref)
          fail "Can't find referenced #{attr_node.name} by name '#{ref}'" if ref_node.nil?

          ref_lookup_content = LookupContext.create(ref_node.document, lookup_context)
          ref_lookup_content.lookup_type(ref_node['type'])
        end
      end

      def add_base_type(doc, type_name, opts = {})
        doc.types ||= []
        doc.types << Document::Type.new(type_name, false, nil, []).tap do |type|
          define_type(type, opts.merge(base: true, simple: true))
        end
      end

      def base_document
        Document.new.tap do |doc|
          doc.urn = 'http://www.w3.org/2001/XMLSchema'
          add_base_type(doc, 'string', name: 'String')
          add_base_type(doc, 'decimal', name: 'Numeric')
          add_base_type(doc, 'float', name: 'Float')
          add_base_type(doc, 'integer', name: 'Integer')
          add_base_type(doc, 'boolean', name: 'Boolean')
          add_base_type(doc, 'base64Binary', name: 'String')
          add_base_type(doc, 'NMTOKEN', name: 'String')
          add_base_type(doc, 'token', name: 'String')
          add_base_type(doc, 'anyURI', name: 'String')
          add_base_type(doc, 'double', name: 'Float')
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