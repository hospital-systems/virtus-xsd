module Virtus
  module Xsd
    class TypeDefinition
      attr_reader :name
      attr_reader :options
      attr_accessor :superclass
      attr_accessor :item_type
      attr_accessor :determinant

      def initialize(opts = {})
        @name = opts[:name]
        @options = opts
        self.determinant = opts[:determinant]
        @attributes_hash = {}
      end

      def attributes
        @attributes_hash.values
      end

      def [](attr_name)
        @attributes_hash[attr_name] || (superclass && superclass[attr_name])
      end

      def []=(attr_name, attr)
        @attributes_hash[attr_name] = attr
      end

      def base?
        options[:base]
      end

      def simple?
        options[:simple]
      end
    end
  end
end