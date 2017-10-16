module Saxerator
  module Parser
    class Accumulator < ::Saxerator::SaxHandler
      def initialize(config, block)
        @stack = []
        @config = config
        @block = block
        @doc_frag_active = false
      end

      def start_element(name, attrs = [])
        @doc_frag_active = true if @config.document_fragment_tags.include?(name)
        if @doc_frag_active
          @stack.push Saxerator::Builder::DocumentFragmentBuilder.new(@config, name, Hash[attrs])
        else
          @stack.push @config.output_type.new(@config, name, Hash[attrs])
        end
      end

      def end_element(_)
        last = @stack.pop
        if @stack.size > 0
          @stack[-1].add_node last
        else
          @block.call(last.block_variable)
        end
        @doc_frag_active = false if @config.document_fragment_tags.include?(last.name)
      end

      def characters(string)
        @stack[-1].add_node(string) unless string.strip.empty?
      end

      def accumulating?
        !@stack.empty?
      end
    end
  end
end
