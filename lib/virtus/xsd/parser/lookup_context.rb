require 'virtus/xsd/parser/document_set'

module Virtus
  module Xsd
    class Parser
      class LookupContext
        def self.create(document, parent_lookup_context = nil)
          ctx = new
          ctx.add(nil, DocumentSet.load(document.path))
          if parent_lookup_context
            document.namespaces.each do |namespace|
              parent_lookup_context.mapping.each_value do |document_set|
                ctx.add(namespace.prefix, document_set) if document_set.root_document.urn == namespace.urn
              end
            end
          end
          document.imports.each do |import|
            namespace = document.namespaces.find { |ns| ns.urn == import.namespace }
            ctx.add(namespace.prefix, DocumentSet.load(import.path))
          end
          ctx
        end

        def lookup_type(type_name)
          name, prefix = type_name.split(':').reverse
          @mapping[prefix].find_type(name)
        end

        def lookup_attribute(attribute_name)
          name, namespace = attribute_name.split(':').reverse
          @mapping[namespace].find_attribute(name)
        end

        def lookup_element(element_name)
          name, namespace = element_name.split(':').reverse
          @mapping[namespace].find_element(name)
        end

        attr_reader :mapping

        def initialize
          @mapping = {}
        end

        def add(prefix, document_set)
          mapping[prefix] = document_set
        end
      end
    end
  end
end