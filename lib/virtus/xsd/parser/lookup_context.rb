require 'virtus/xsd/parser/document_set'

module Virtus
  module Xsd
    class Parser
      class LookupContext
        def self.create(document, parent_lookup_context = nil)
          mapping = {nil => DocumentSet.load(document.path)}
          if parent_lookup_context
            document.namespaces.each do |namespace|
              parent_lookup_context.mapping.each_value do |document_set|
                mapping[namespace.prefix] = document_set if document_set.root_document.urn == namespace.urn
              end
            end
          end
          document.imports.each do |import|
            namespace = document.namespaces.find { |ns| ns.urn == import.namespace }
            mapping[namespace.prefix] = DocumentSet.load(import.path)
          end
          new(mapping)
        end

        def lookup_type(type_name)
          name, namespace = type_name.split(':').reverse
          @mapping[namespace].find_type(name)
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

        def initialize(mapping)
          @mapping = mapping
        end
      end
    end
  end
end