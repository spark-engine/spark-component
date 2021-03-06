# frozen_string_literal: true

module Spark
  module Component
    class Attr < Hash
      def initialize(*args, prefix: nil)
        super(*args)
        @prefix = prefix
      end

      def add(hash)
        return self if hash.nil? || hash.keys.empty?

        deep_compact!(hash)
        dasherize_keys(hash)
        merge!(hash)
        self
      end

      # Output all attributes as [prefix-]name="value"
      def to_s
        each_with_object([]) do |(name, value), array|
          if value.is_a?(Component::Attr)
            # Flatten nested hashs and inject them unless empty
            value = value.to_s
            array << value unless value.empty?
          else
            name = [@prefix, name].compact.join("-").gsub(/[\W_]+/, "-")
            array << %(#{name}="#{value}") unless value.nil?
          end
        end.sort.join(" ")
      end

      private

      def deep_compact!(hash)
        hash.replace(deep_compact(hash))
      end

      def deep_compact(hash)
        hash.reject do |_key, val|
          val = deep_compact(val) if val.is_a?(Hash)
          (val.nil? || val.respond_to?(:empty?) && val.empty?)
        end
      end

      def dasherize_keys(hash)
        hash.merge!(hash.keys.each_with_object({}) do |key, obj|
          obj[key.to_s.gsub(/[\W_]+/, "-")] = hash.delete(key) if key.to_s.include?("_")
        end)
      end
    end
  end
end
