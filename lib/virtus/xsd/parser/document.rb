module Virtus
  module Xsd
    class Parser
      class Document
        Import = Struct.new(:namespace, :path)
        Include = Struct.new(:path)
        Namespace = Struct.new(:prefix, :urn)
        Type = Struct.new(:name, :complex, :base, :attributes)
        TypeNode = Struct.new(:document, :type) do
          def [](attr_name)
            return type.name if attr_name == 'name'
            raise "No #{attr_name.inspect}"
          end
        end
        Node = Struct.new(:document, :node) do
          def name
            node.name
          end

          def [](attr_name)
            node[attr_name]
          end
        end

        attr_accessor :urn, :path, :namespaces, :includes, :imports
        attr_accessor :types, :element_nodes, :attribute_nodes

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
            doc.types = xml.xpath('xs:schema/xs:simpleType').map do |node|
              restriction = node.xpath('xs:restriction').first
              Type.new(node['name'], false, restriction && restriction['base'], [])
            end
            doc.types += xml.xpath('xs:schema/xs:complexType').map do |node|
              extension = node.xpath('xs:complexContent/xs:extension').first
              restriction = node.xpath('xs:complexContent/xs:restriction').first
              base = extension && extension['base'] || restriction && restriction['base']
              attributes = (extension || node).xpath('xs:attribute|xs:sequence/xs:element')
              Type.new(node['name'], true, base, attributes)
            end
            #FIXME: should be in LookupContext
            doc.types = doc.types.map { |type| TypeNode.new(doc, type) }
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