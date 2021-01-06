# frozen_string_literal: true

class GandiV5
  class Template
    class Payload
      # DNS Record details of a configuration template.
      # @!attribute [r] name
      #   @return [String]
      # @!attribute [r] type
      #   @return [String]
      # @!attribute [r] values
      #   @return [Array<String>]
      # @!attribute [r] ttl
      #   @return [Integer, nil] 300-2592000.
      class DNSRecord
        include GandiV5::Data

        members :name, :type, :ttl
        member :values, array: true
      end
    end
  end
end
