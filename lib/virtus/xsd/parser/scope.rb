module Virtus
  module Xsd
    class Parser
      class Scope
        def initialize(xsd_path)
          @xsd_documents = collect_xsd_documents(xsd_path)
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

        private

        attr_reader :xsd_documents

        def xpath(xpath)
          xsd_documents.map { |doc| doc.xpath(xpath) }.inject { |all, nodes| all + nodes }
        end

        def collect_xsd_documents(path, processed_paths = Set.new)
          return [] if processed_paths.include?(path)
          processed_paths.add(path)
          document = Nokogiri::XML(File.read(path))
          nodes = document.xpath('xs:schema/xs:include')
          included_paths = nodes.map { |node| File.expand_path(node['schemaLocation'], File.dirname(path)) }
          included_documents = included_paths.inject([]) { |agg, included_path|
            agg.concat(collect_xsd_documents(included_path, processed_paths))
          }
          included_documents + [document]
        end
      end
    end
  end
end