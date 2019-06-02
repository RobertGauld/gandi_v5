# frozen_string_literal: true

class GandiV5
  class LiveDNS
    # A record set which comes from either a domain or zone.
    # @!attribute [r] type
    #   @return [String]
    # @!attribute [r] ttl
    #   @return [Integer]
    # @!attribute [r] name
    #   @return [String]
    # @!attribute [r] values
    #   @return [Array<String>]
    class RecordSet
      include GandiV5::Data

      member :type, gandi_key: 'rrset_type'
      member :ttl, gandi_key: 'rrset_ttl'
      member :name, gandi_key: 'rrset_name'
      member :values, gandi_key: 'rrset_values'

      # Generate zone file lines for the record.
      # @return [String]
      def to_s
        values.map do |value|
          "#{name}\t#{ttl}\tIN\t#{type}\t#{value}"
        end.join("\n")
      end

      GandiV5::LiveDNS::RECORD_TYPES.each do |t|
        # Check the record type.
        # @return [Boolean]
        define_method "#{t.downcase}?" do
          type.eql?(t)
        end
      end

      # Check the TTL's value in seconds.
      # @param number [Integer] the number of second(s) to check against.
      # @return [Boolean]
      def second?(number = 1)
        ttl == number
      end
      alias seconds? second?

      # Check the TTL's value in minutes.
      # @param number [Integer] the number of minute(s) to check against.
      # @return [Boolean]
      def minute?(number = 1)
        ttl == number * 60
      end
      alias minutes? minute?

      # Check the TTL's value in hours.
      # @param number [Integer] the number of hour(s) to check against.
      # @return [Boolean]
      def hour?(number = 1)
        ttl == number * 3_600
      end
      alias hours? hour?

      # Check the TTL's value in days.
      # @param number [Integer] the number of day(s) to check against.
      # @return [Boolean]
      def day?(number = 1)
        ttl == number * 86_400
      end
      alias days? day?

      # Check the TTL's value in weeks.
      # @param number [Integer] the number of week(s) to check against.
      # @return [Boolean]
      def week?(number = 1)
        ttl == number * 604_800
      end
      alias weeks? day?
    end
  end
end
