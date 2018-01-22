require 'dentaku/bulk_expression_solver'
require 'dentaku/exceptions'
require 'dentaku/token'
require 'dentaku/dependency_resolver'
require 'dentaku/parser'


module Dentaku
  class Calculator
    attr_reader :result, :memory, :tokenizer

    def initialize(ast_cache={})
      clear
      @tokenizer = Tokenizer.new
      @ast_cache = ast_cache
      @disable_ast_cache = false
      @function_registry = Dentaku::AST::FunctionRegistry.new
    end

    def self.add_function(name, type, body)
      Dentaku::AST::FunctionRegistry.default.register(name, type, body)
    end

    def add_function(name, type, body)
      @function_registry.register(name, type, body)
      self
    end

    def add_functions(fns)
      fns.each { |(name, type, body)| add_function(name, type, body) }
      self
    end

    def disable_cache
      @disable_ast_cache = true
      yield(self) if block_given?
    ensure
      @disable_ast_cache = false
    end

    def evaluate(expression, data={})
      evaluate!(expression, data)
    rescue UnboundVariableError, Dentaku::ArgumentError
      yield expression if block_given?
    end

    def evaluate!(expression_or_expression_hash, data={})
      unless expression_or_expression_hash.kind_of?(Hash)
        return evaluate!({expression: expression_or_expression_hash}, data)[:expression]
      end

      expression_hash = expression_or_expression_hash
      store(data) do
        expression_hash.each_with_object({}) do |(key, expression), result|
          node = expression
          node = ast(node) unless node.is_a?(AST::Node)
          unbound = node.dependencies - memory.keys
          unless unbound.empty?
            raise UnboundVariableError.new(unbound),
                  "no value provided for variables: #{unbound.join(', ')}"
          end
          result[key] = node.value(memory)
        end
      end
    end

    def solve!(expression_hash)
      BulkExpressionSolver.new(expression_hash, self).solve!
    end

    def solve(expression_hash, &block)
      BulkExpressionSolver.new(expression_hash, self).solve(&block)
    end

    def dependencies(expression)
      ast(expression).dependencies(memory)
    end

    def ast(expression)
      @ast_cache.fetch(expression) {
        Parser.new(tokenizer.tokenize(expression), function_registry: @function_registry).parse.tap do |node|
          @ast_cache[expression] = node if cache_ast?
        end
      }
    end

    def clear_cache(pattern=:all)
      case pattern
      when :all
        @ast_cache = {}
      when String
        @ast_cache.delete(pattern)
      when Regexp
        @ast_cache.delete_if { |k,_| k =~ pattern }
      else
        raise ::ArgumentError
      end
    end

    def store(key_or_hash, value=nil)
      restore = Hash[memory]

      if value.nil?
        _flat_hash(key_or_hash).each do |key, val|
          memory[key.to_s.downcase] = val
        end
      else
        memory[key_or_hash.to_s.downcase] = value
      end

      if block_given?
        begin
          result = yield
          @memory = restore
          return result
        rescue => e
          @memory = restore
          raise e
        end
      end

      self
    end
    alias_method :bind, :store

    def store_formula(key, formula)
      store(key, ast(formula))
    end

    def clear
      @memory = {}
    end

    def empty?
      memory.empty?
    end

    def cache_ast?
      Dentaku.cache_ast? && !@disable_ast_cache
    end

    private

    def _flat_hash(hash, k = [])
      if hash.is_a?(Hash)
        hash.inject({}) { |h, v| h.merge! _flat_hash(v[-1], k + [v[0]]) }
      else
        return { k.join('.') => hash } if k.is_a?(Array)
        { k => hash }
      end
    end
  end
end
