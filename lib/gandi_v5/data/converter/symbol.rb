# frozen_string_literal: true

class GandiV5
  module Data
    class Converter
      # Methods for converting strings to/from symbols.
      class Symbol
        # @param value [Symbol]
        # @return [String]
        def self.to_gandi(value)
          return nil if value.nil?

          value.to_s
        end

        # @param [String]
        # @return value [Symbol]
        def self.from_gandi(value)
          return nil if value.nil?

          value.to_sym
        end
      end
    end
  end
end
