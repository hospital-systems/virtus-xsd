require 'active_support/core_ext/hash/keys'

module Virtus
  module Xsd
    class Parser
      class Config
        attr_reader :types

        def initialize(config)
          @config = config
          @types = @config['types']
        end

        def type_replacements
          @type_replacements ||= types.each_with_object({}) do |(name, info), acc|
            acc[name] = info.symbolize_keys if info['base']
          end
        end

        def type_renames
          @type_renames ||= types.each_with_object({}) { |(name, info), acc| acc[name] = info['name'] }
        end

        def ignored_prefixes_regexp
          @ignored_prefixes_regexp ||= begin
            prefixes = @config['prefixes']
            ignored_prefixes = prefixes && prefixes['remove'] || []
            /^(#{ignored_prefixes.map { |pfx| Regexp.escape(pfx) }.join('|')})/
          end
        end
      end
    end
  end
end