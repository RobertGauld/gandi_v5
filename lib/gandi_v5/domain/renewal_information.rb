# frozen_string_literal: true

class GandiV5
  class Domain
    # Renewal information for a domain.
    # @!attribute [r] begins_at
    #   @return [Time]
    # @!attribute [r] ends_at
    #   @return [nil, Time]
    # @!attribute [r] in_renew_period
    #   @return [nil, Boolean]
    # @!attribute [r] prohibited
    #   @return [Boolean]
    # @!attribute [r] durations
    #   @return [Array<Integer>]
    # @!attribute [r] maximum
    #   @return [Integer]
    # @!attribute [r] minimum
    #   @return [Integer]
    # @!attribute [r] contracts
    #   @return [Array<GandiV5::Domain::Contract>]
    class RenewalInformation
      include GandiV5::Data

      members :in_renew_period, :prohibited, :durations, :maximum, :minimum

      member :begins_at, converter: GandiV5::Data::Converter::Time
      member :ends_at, converter: GandiV5::Data::Converter::Time
      member :contracts, converter: GandiV5::Domain::Contract, array: true

      # Check if the domain is currently renewable.
      # @return [Boolean]
      def renewable?
        return false if prohibited
        return false if begins_at > Time.now

        ends_at.nil? || ends_at >= Time.now
      end
    end
  end
end
