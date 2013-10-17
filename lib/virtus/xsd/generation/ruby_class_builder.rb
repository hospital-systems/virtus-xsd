module Virtus
  module Xsd
    module Generation
      class RubyClassBuilder
        def initialize(output)
          @output = output
          @identation = ''
        end

        def module_(name)
          puts "module #{name}"
          ident { yield }
          puts "end"
        end

        def class_(name, superclass = nil)
          name_with_superclass = [name, superclass].compact.join(' < ')
          puts "class #{name_with_superclass}"
          ident { yield }
          puts "end"
        end

        def ident
          saved_identation, @identation = @identation, @identation + '  '
          yield
        ensure
          @identation = saved_identation
        end

        def within_module(module_name)
          parts = module_name.split('::', 2)
          module_(parts.first) do
            if parts.length > 1
              within_module(parts.second) { yield }
            else
              yield
            end
          end
        end

        private

        def puts(line)
          @output.print @identation
          @output.puts line
        end
      end
    end
  end
end