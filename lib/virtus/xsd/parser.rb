require 'ostruct'
require 'virtus/xsd/parser/document_set'
require 'virtus/xsd/parser/lookup_context'
require 'virtus/xsd/parser/config'

module Virtus
  module Xsd
    class Parser
      def self.parse(xsd_path, config = {})
        new(xsd_path, config).parse
      end

      def initialize(xsd_path, config = {})
        @scope = DocumentSet.load(xsd_path)
        @config = Config.new(config)
        @type_ref2typedef = {}
        @defined_types = {}
      end

      def parse
        scope.scoped_documents.map do |doc|
          doc.types.map { |type| get_type_definition(type, root_lookup_context) }
        end.flatten
      end

      protected

      attr_reader :scope, :config
      attr_reader :type_ref2typedef, :defined_types

      def get_type_definition(type, parent_lookup_context = nil)
        type_ref2typedef[type] || override_type(type) || build_type_definition(type, parent_lookup_context)
      end

      def override_type(type)
        if (type_replacement = config.type_replacements[type.type.name])
          define_type(type, get_or_make_typedef(type_replacement))
        end
      end

      def build_type_definition(type_ref, parent_ctx = nil)
        type = type_ref.type
        typedef = make_typedef(name: apply_renaming(type.name), simple: !type.complex)
        define_type(type_ref, typedef)
        ctx = LookupContext.create(type_ref.document, parent_ctx)
        typedef.item_type = get_type_definition(ctx.lookup_type(type.item_type), ctx) if type.item_type
        typedef.superclass = get_type_definition(ctx.lookup_type(type.base), ctx) if type.base
        type.attributes.each do |attr_node|
          build_attribute(type_ref, attr_node, ctx).tap do |attr|
            typedef.attributes[attr.name] = attr
          end
        end
        typedef
      end

      def apply_renaming(name)
        config.type_renames.fetch(name, name.sub(config.ignored_prefixes_regexp, ''))
      end

      def build_attribute(type_ref, attr_node, lookup_context)
        attr_name = attr_node['name'] || without_namespace(attr_node['ref'])
        attr_type = resolve_type(type_ref, attr_node, lookup_context)
        attr_typedef = get_type_definition(attr_type, lookup_context)
        multiple = attr_node['maxOccurs'] == 'unbounded'
        Virtus::Xsd::AttributeDefinition.new(attr_name, attr_typedef, multiple: multiple)
      end

      def define_type(type, typedef)
        existing_typedef = defined_types[typedef.name]
        if !existing_typedef.nil? && existing_typedef != typedef
          fail "Type '#{typedef.name}' is already defined"
        end
        defined_types[typedef.name] = type_ref2typedef[type] = typedef
      end

      def without_namespace(name)
        name.split(':').last
      end

      def resolve_type(type_ref, attr_node, ctx)
        attr_type_ref = resolve_anonymous_type(type_ref, attr_node) ||
          resolve_type_by_ref(type_ref, attr_node, ctx) ||
          ctx.lookup_type(attr_node['type'])
        if attr_type_ref.nil?
          fail "Can't resolve type '#{attr_node['type']}' for '#{type_ref.type.name}##{attr_node['name']}'"
        end
        attr_type_ref
      end

      def resolve_anonymous_type(type_ref, attr_node)
        if (simple_type_node = attr_node.xpath('xs:simpleType').first)
          simple_type = Document.build_simple_type(simple_type_node,
                                                   "#{type_ref.type.name}.#{attr_node['name']}")
          make_type_ref(type_ref.document, simple_type)
        end
      end

      def resolve_type_by_ref(type_ref, attr_node, ctx)
        if (ref = attr_node['ref'])
          ref_node = ctx.lookup_attribute(ref) || ctx.lookup_element(ref)
          fail "Can't find referenced #{attr_node.name} by name '#{ref}'" if ref_node.nil?
          resolve_type(type_ref, ref_node.node, LookupContext.create(ref_node.document, ctx))
        end
      end

      def make_type_ref(doc, type)
        Document::TypeRef.new(doc, type)
      end

      def base_type_ref(doc, type_name)
        make_type_ref(doc, Document::Type.new(type_name, false, nil, nil, []))
      end

      def make_typedef(type_info)
        Virtus::Xsd::TypeDefinition.new(type_info.delete(:name), type_info)
      end

      def get_or_make_typedef(type_info)
        defined_types[type_info[:name]] || make_typedef(type_info)
      end

      def add_base_type(doc, type_name, opts = {})
        doc.types ||= []
        doc.types << base_type_ref(doc, type_name).tap do |type|
          typedef = get_or_make_typedef(opts.merge(base: true, simple: true))
          define_type(type, typedef)
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
          add_base_type(doc, 'NMTOKENS', name: 'Array[String]')
          add_base_type(doc, 'token', name: 'String')
          add_base_type(doc, 'anyURI', name: 'String')
          add_base_type(doc, 'double', name: 'Float')
          add_base_type(doc, 'ID', name: 'String')
          add_base_type(doc, 'IDREF', name: 'String')
          add_base_type(doc, 'IDREFS', name: 'Array[String]')
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