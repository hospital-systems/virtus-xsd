require 'virtus/xsd/parser/document'

module Virtus
  module Xsd
    class Parser
      class DocumentSet
        def self.load(path, root_scope = nil)
          doc = Document.load(path)
          documents = load_recursive(doc)

          new(documents, root_scope) do |scope|
            scope.register(doc.namespace, scope) if doc.namespace
            load_imports(doc, scope)
          end
        end

        def self.load_recursive(doc)
          unprocessed_documents = [doc]

          unprocessed_documents.each_with_object([]) do |current_document, scoped_documents|
            next if scoped_documents.include?(current_document)
            scoped_documents << current_document

            included_documents = current_document.includes.map { |include| Document.load(include.path) }
            unprocessed_documents.concat(included_documents)
          end
        end

        def self.load_imports(doc, scope)
          doc.imports.each do |import|
            unless scope.registered?(import.namespace)
              load(import.path, scope)
            end
          end
        end

        def root_document
          scoped_documents.first
        end

        def find_type(name)
          (@types ||= index(:types))[name]
        end

        def find_element(name)
          (@elements ||= index(:element_nodes))[name]
        end

        def find_attribute(name)
          (@attributes ||= index(:attribute_nodes))[name]
        end

        def simple_types
          @simple_types ||= xpath('xs:schema/xs:simpleType')
        end

        def complex_types
          @complex_types ||= xpath('xs:schema/xs:complexType')
        end

        def elements
          @elements ||= xpath('xs:schema/xs:element')
        end

        def attributes
          @attributes ||= xpath('xs:schema/xs:attribute')
        end

        def [](namespace)
          namespace = scoped_documents.map do |doc|
            doc.namespaces["xmlns:#{namespace}"]
          end.compact.first || namespace
          registry[namespace]
        end

        def register(namespace, document)
          registry[namespace] = document
        end

        def registered?(namespace)
          registry.key?(namespace)
        end

        attr_reader :scoped_documents, :registry

        protected

        def initialize(scoped_documents, root_scope = nil, &block)
          @scoped_documents = scoped_documents
          @registry = root_scope ? root_scope.registry : {}
          yield(self) if block_given?
        end

        def xpath(xpath)
          scoped_documents.map { |doc| doc.xpath(xpath) }.inject { |all, nodes| all + nodes }
        end

        def index(collection)
          scoped_documents.each_with_object({}) do |doc, index|
            doc.send(collection).each do |item|
              index[item['name']] = item
            end
          end
        end
      end
    end
  end
end
