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

        attr_reader :path

        def self.load(path)
          @cache ||= {}
          @cache[path] ||= Document.new(Nokogiri::XML(File.read(path)), path)
        end

        def xpath(*args)
          @document.xpath(*args)
        end

        def namespaces
          @namespaces ||= @document.namespaces.map do |prefix, urn|
            Namespace.new(prefix.sub(/^xmlns:/, ''), urn)
          end
        end

        def includes
          @includes ||= xpath('xs:schema/xs:include').map do |node|
            Include.new(expand_path(node['schemaLocation']))
          end
        end

        def imports
          @imports ||= xpath('xs:schema/xs:import').map do |node|
            Import.new(node['namespace'], expand_path(node['schemaLocation']))
          end
        end

        def types
          @types ||= find_nodes('xs:schema/*[local-name()="simpleType" or local-name()="complexType"]')
        end

        def element_nodes
          @element_nodes ||= find_nodes('xs:schema/xs:element')
        end

        def attribute_nodes
          @attribute_nodes ||= find_nodes('xs:schema/xs:attribute')
        end

        def find_nodes(xpath)
          @document.xpath(xpath).map { |node| Node.new(self, node) }
        end

        def urn
          @urn ||= @document.root['targetNamespace']
        end

        private

        def initialize(document, path)
          @document = document
          @path = path
        end

        def expand_path(relative_path)
          File.expand_path(relative_path, File.dirname(self.path))
        end
      end
    end
  end
end