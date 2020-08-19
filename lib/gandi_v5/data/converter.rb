# frozen_string_literal: true

class GandiV5
  module Data
    # Namespace for converters to/from Gandi's format.
    # @api private
    class Converter
      # Initialize a new simple converter.
      # The passed procs will be run at the appropriate time.
      # @param from_gandi [Proc]
      # @param to_gandi [Proc]
      def initialize(from_gandi: nil, to_gandi: nil)
        @from_gandi_proc = from_gandi
        @to_gandi_proc = to_gandi
      end

      # @param value [Object]
      # @return [Object]
      def to_gandi(value)
        return value unless to_gandi_proc

        to_gandi_proc.call value
      end

      # @param value [Object]
      # @return [Object]
      def from_gandi(value)
        return value unless from_gandi_proc

        from_gandi_proc.call value
      end

      private

      attr_reader :from_gandi_proc, :to_gandi_proc
    end
  end
end
