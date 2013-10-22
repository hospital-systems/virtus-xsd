require 'virtus/xsd/parser/document'

module Virtus
  module Xsd
    class Parser
      class Scope
        def self.load(path, root_scope = nil)
          root_document = Document.load(path)
          scoped_documents = []
          unprocessed_documents = [root_document]
          until unprocessed_documents.empty?
            next_document = unprocessed_documents.shift
            next if scoped_documents.include?(next_document)
            scoped_documents << next_document
            unprocessed_documents.concat(next_document.includes.map { |include| Document.load(include) })
          end
          scope = new(scoped_documents, root_scope)
          scope.register(root_document.namespace, scope) if root_document.namespace
          root_document.xpath('xs:schema/xs:import').each do |import|
            namespace = import['namespace']
            imported_path = File.expand_path(import['schemaLocation'], File.dirname(path))
            Scope.load(imported_path, scope) unless scope.registry[namespace]
          end
          scope
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
      end
    end
  end
end
