module Virtus
  module Xsd
    class Parser
      class Document
        attr_reader :path

        def self.load(path)
          @cache ||= {}
          @cache[path] ||= Document.new(Nokogiri::XML(File.read(path)), path)
        end

        def xpath(*args)
          @document.xpath(*args)
        end

        def namespaces
          @document.namespaces
        end

        def includes
          @include_paths ||= xpath('xs:schema/xs:include').map { |node| expand_path(node['schemaLocation']) }
        end

        def imports
          @import_paths ||= xpath('xs:schema/xs:import').map { |node| expand_path(node['schemaLocation']) }
        end

        def namespace
          @namespace ||= @document.root['targetNamespace']
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