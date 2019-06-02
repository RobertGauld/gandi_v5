# frozen_string_literal: true

class GandiV5
  module Data
    class Converter
      # Used for applying the same converter to each item in an array.
      class ArrayOf
        # @param converter the converter to apply to each item in the array.
        def initialize(converter)
          @converter = converter
        end

        # @param value [Array<Object>]
        # @return [Array<Object>]
        def to_gandi(value)
          return nil if value.nil?

          value.map { |item| converter.to_gandi(item) }
        end

        # @param [Array<Object>]
        # @return value [Array<Object>]
        def from_gandi(value)
          return nil if value.nil?

          value.map { |item| converter.from_gandi(item) }
        end

        private

        attr_reader :converter
      end
    end
  end
end
