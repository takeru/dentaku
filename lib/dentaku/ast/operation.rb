require_relative './node'

module Dentaku
  module AST
    class Operation < Node
      attr_reader :left, :right

      def self.min_param_count
        arity
      end

      def self.max_param_count
        arity
      end

      def initialize(left, right)
        @left  = left
        @right = right
      end

      def dependencies(context = {})
        (left.dependencies(context) + right.dependencies(context)).uniq
      end

      def self.right_associative?
        false
      end
    end
  end
end
