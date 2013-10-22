require 'virtus/xsd/parser/document'

module Virtus
  module Xsd
    class Parser
      class DocumentSet
        def self.load(path, root_scope = nil)
          root_document = Document.load(path)
          scoped_documents = []
          unprocessed_documents = [root_document]
          until unprocessed_documents.empty?
            next_document = unprocessed_documents.shift
            next if scoped_documents.include?(next_document)
            scoped_documents << next_document
            unprocessed_documents.concat(next_document.includes.map { |include| Document.load(include.path) })
          end
          scope = new(scoped_documents, root_scope)
          scope.register(root_document.namespace, scope) if root_document.namespace
          root_document.imports.each do |import|
            DocumentSet.load(import.path, scope) unless scope.registry[import.namespace]
          end
          scope
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

        attr_reader :scoped_documents, :registry

        protected

        def initialize(scoped_documents, root_scope = nil)
          @scoped_documents = scoped_documents
          @registry = root_scope ? root_scope.registry : {}
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
