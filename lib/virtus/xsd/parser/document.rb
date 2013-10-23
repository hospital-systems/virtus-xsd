module Virtus
  module Xsd
    class Parser
      class Document
        Import = Struct.new(:namespace, :path)
        Include = Struct.new(:path)
        Namespace = Struct.new(:prefix, :urn)
        Node = Struct.new(:document, :node) do
          def name
            node.name
          end

          def [](attr_name)
            node[attr_name]
          end
        end

        attr_accessor :urn, :path, :namespaces, :includes, :imports, :types, :element_nodes, :attribute_nodes

        def self.load(path)
          @cache ||= {}
          @cache[path] ||= Document.new.tap do |doc|
            xml = Nokogiri::XML(File.read(path))
            doc.path = path
            doc.namespaces = xml.namespaces.map { |prefix, urn| Namespace.new(prefix.sub(/^xmlns:/, ''), urn) }
            doc.includes = xml.xpath('xs:schema/xs:include').map { |node|
              Include.new(File.expand_path(node['schemaLocation'], File.dirname(path)))
            }
            doc.imports = xml.xpath('xs:schema/xs:import').map { |node|
              Import.new(node['namespace'], File.expand_path(node['schemaLocation'], File.dirname(path)))
            }
            doc.types = find_nodes(xml, 'xs:schema/*[local-name()="simpleType" or local-name()="complexType"]', doc)
            doc.element_nodes = find_nodes(xml, 'xs:schema/xs:element', doc)
            doc.attribute_nodes = find_nodes(xml, 'xs:schema/xs:attribute', doc)
            doc.urn = xml.root['targetNamespace']
          end
        end

        private

        def self.find_nodes(xml, xpath, doc)
          xml.xpath(xpath).map { |node| Node.new(doc, node) }
        end
      end
    end
  end
end