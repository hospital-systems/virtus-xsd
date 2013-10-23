require 'virtus/xsd/parser/document'

module Virtus
  module Xsd
    class Parser
      class DocumentSet
        def self.load(path)
          doc = Document.load(path)
          documents = load_recursive(doc)

          new(documents)
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

        attr_reader :scoped_documents

        protected

        def initialize(scoped_documents)
          @scoped_documents = scoped_documents
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
