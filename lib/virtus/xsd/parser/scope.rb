require 'virtus/xsd/parser/document'

module Virtus
  module Xsd
    class Parser
      class Scope
        def self.load(path)
          scoped_documents = []
          unprocessed_documents = [Document.load(path)]
          until unprocessed_documents.empty?
            next_document = unprocessed_documents.shift
            next if scoped_documents.include?(next_document)
            scoped_documents << next_document
            unprocessed_documents.concat(next_document.includes)
          end
          new(scoped_documents)
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
          Scope.new([registered_documents[namespace]])
        end

        private

        attr_reader :scoped_documents

        def initialize(scoped_documents)
          @scoped_documents = []
          scoped_documents.each { |doc| add(doc) }
        end

        def xpath(xpath)
          scoped_documents.map { |doc| doc.xpath(xpath) }.inject { |all, nodes| all + nodes }
        end

        def registered_documents
          @registered_documents ||= {}
        end

        def register(namespace, document)
          registered_documents[namespace] = document
        end

        def add(document)
          scoped_documents << document
          ([document] + document.imports).each do |doc|
            register(doc.namespace, doc) if doc.namespace
          end
        end
      end
    end
  end
end
