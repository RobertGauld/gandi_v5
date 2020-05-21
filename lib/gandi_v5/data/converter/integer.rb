# frozen_string_literal: true

class GandiV5
  module Data
    class Converter
      # Methods for converting strings to/from integerss.
      class Integer
        # @param value [Integer]
        # @return [String]
        def self.to_gandi(value)
          return nil if value.nil?

          value.to_s
        end

        # @param [String]
        # @return value [Integer]
        def self.from_gandi(value)
          return nil if value.nil?

          value.to_i
        end
      end
    end
  end
end
