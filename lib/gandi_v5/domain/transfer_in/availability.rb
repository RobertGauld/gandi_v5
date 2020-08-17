# frozen_string_literal: true

class GandiV5
  class Domain
    class TransferIn
      # Information about the availabillity of a domain to be transfered into Gandi.
      # @!attribute [r] fqdn
      #   @return [String] the fully qualified domain name.
      # @!attribute [r] fqdn_unicode
      #   @return [String] the fully qualified domain name in unicode.
      # @!attribute [r] available
      #   @return [Boolean] whether the domain can be transfered.
      # @!attribute [r] corporate
      #   @return [Boolean] Optional
      # @!attribute [r] internal
      #   @return [Boolean] Optional
      # @!attribute [r] minimum_duration
      #   @return [Integer] Optional the minimum duration you can reregister the domain for.
      # @!attribute [r] maximum_duration
      #   @return [Integer] Optional the maximum duration you can reregister the domain for.
      # @!attribute [r] durations
      #   @return [Array<Integer>] Optional the durations you can reregister the domain for.
      # @!attribute [r] message
      #   @return [String, nil] Optional message explaining why the domain can't be transfered.
      class Availability
        include GandiV5::Data

        members :fqdn, :available, :corporate, :internal,
                :minimum_duration, :maximum_duration
        member :durations, array: true
        member :message, gandi_key: 'msg'
        member :fqdn_unicode, gandi_key: 'fqdn_ulabel'

        # Find out if a domain can be transfered to Gandi.
        # @see https://api.gandi.net/docs/domains/#post-v5-domain-transferin-domain-available
        # @param fqdn [String, #to_s] the fully qualified domain name to query.
        # @param auth_code [String, #to_s] authorization code (if required).
        # @return [GandiV5::Domain::TransferIn::Availabillity]
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def self.fetch(fqdn, auth_code = nil)
          url = "#{BASE}domain/transferin/#{fqdn}/available"
          body = {}
          body['authinfo'] = auth_code if auth_code

          _response, data = GandiV5.post url, body
          from_gandi data
        end
      end
    end
  end
end
