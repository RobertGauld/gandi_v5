# frozen_string_literal: true

class GandiV5
  module Data
    class Converter
      # Methods for converting times to/from Gandi ("2019-02-13T11:04:18Z").
      # @api private
      class Time
        # Convert a time to Gandi's prefered string format.
        # @param value [Time]
        # @return [String]
        def self.to_gandi(value)
          return nil if value.nil?

          value.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
        end

        # Convert a time from Gandi's prefered string format.
        # @param value [String]
        # @return [Time]
        def self.from_gandi(value)
          return nil if value.nil?

          ::Time.parse value
        end
      end
    end
  end
end
