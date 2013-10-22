module Virtus
  module Xsd
    class Parser
      class Document
        Import = Struct.new(:namespace, :path)
        Include = Struct.new(:path)

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
          @includes ||= xpath('xs:schema/xs:include').map do |node|
            Include.new(expand_path(node['schemaLocation']))
          end
        end

        def imports
          @imports ||= xpath('xs:schema/xs:import').map do |node|
            Import.new(node['namespace'], expand_path(node['schemaLocation']))
          end
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