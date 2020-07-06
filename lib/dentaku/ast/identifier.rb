require_relative '../exceptions'
require 'dentaku/string_casing'

module Dentaku
  module AST
    class Identifier < Node
      include StringCasing
      attr_reader :identifier, :case_sensitive

      @@excel_mode = true
      @@cache_value = true

      def initialize(token, options = {})
        @case_sensitive = options.fetch(:case_sensitive, false)
        @identifier = standardize_case(token.value)
      end

      def value(context = {})
        v = context.fetch(identifier) do
          if @@excel_mode
            ""
          else
            raise UnboundVariableError.new([identifier]),
                  "no value provided for variables: #{identifier}"
          end
        end

        case v
        when Node
          if @@cache_value
            context[identifier] = v.value(context)
          else
            v.value(context)
          end
        when Proc
          v.call
        else
          v
        end
      end

      def dependencies(context = {})
        context.key?(identifier) ? dependencies_of(context[identifier]) : [identifier]
      end

      private

      def dependencies_of(node)
        node.respond_to?(:dependencies) ? node.dependencies : []
      end
    end
  end
end
