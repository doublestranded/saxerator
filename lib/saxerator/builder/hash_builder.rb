module Saxerator
  module Builder
    class HashBuilder
      attr_reader :name

      def initialize(config, name, attributes)
        @config = config
        @name = config.generate_key_for(name)
        @attributes = normalize_attributes(attributes)
        @children = []
        @text = false
      end

      def add_node(node)
        @text = true if node.is_a? String
        @children << node
      end

      def to_s(children: @children)
        StringElement.new(children.join, @name, @attributes)
      end

      def to_hash(children: @children)
        hash = HashElement.new(@name, @attributes)

        children.each do |child|
          name = child.name
          element = child.block_variable

          add_to_hash_element(hash, name, element)
        end

        if @config.put_attributes_in_hash?
          @attributes.each do |attribute|
            attribute.each_slice(2) do |name, element|
              add_to_hash_element(hash, name, element)
            end
          end
        end

        hash
      end

      def add_to_hash_element(hash, name, element)
        name = generate_key(name)
        if hash.key? name
          unless hash[name].is_a?(ArrayElement)
            hash[name] = ArrayElement.new([hash[name]], name)
          end
          hash[name] << element
        else
          hash[name] = element
        end
      end

      def block_variable
        text_children = []
        hash_children = []
        @children.each do |child|
          case
          when child.kind_of?(String)
            text_children << child
          when child.kind_of?(Saxerator::Builder::HashBuilder)
            hash_children << child
          else
            # TODO ?
          end
        end
        s = to_s(children: text_children)
        h = to_hash(children: hash_children)
        if s.empty? || h.empty?
          return s.empty? ? h : s
        else
          [s, h]
        end
      end

      def normalize_attributes(attributes)
        Hash[attributes.map { |key, value| [generate_key(key), value] }]
      end

      def generate_key(name)
        @config.generate_key_for(name)
      end
    end
  end
end
