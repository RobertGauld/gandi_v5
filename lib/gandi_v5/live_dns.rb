# frozen_string_literal: true

# Namespace for classes which access LiveDNS details.
class GandiV5
  # Gandi LiveDNS Management API.
  class LiveDNS
    BASE = 'https://dns.api.gandi.net/api/v5/'

    RECORD_TYPES = %w[
      A AAAA CNAME MX NS TXT ALIAS
      WKS SRV LOC SPF CAA DS SSHFP PTR KEY DNAME TLSA OPENPGPKEY CDS
    ].freeze

    # @see GandiV5::LiveDNS::Domain.fetch
    def self.domain(fqdn)
      GandiV5::LiveDNS::Domain.fetch(fqdn)
    end

    # @see GandiV5::LiveDNS::Domain.list
    def self.domains
      GandiV5::LiveDNS::Domain.list
    end

    # @see GandiV5::LiveDNS::Zone.fetch
    def self.zone(uuid)
      GandiV5::LiveDNS::Zone.fetch(uuid)
    end

    # @see GandiV5::LiveDNS::Zone.list
    def self.zones
      GandiV5::LiveDNS::Zone.list
    end

    # Raise an error if passed type is invalid.
    # @param type [String] the record type to check.
    # @return [nil]
    # @raise [ArgumentError]
    # rubocop:disable Style/GuardClause
    def self.require_valid_record_type(type)
      unless RECORD_TYPES.include?(type)
        fail ArgumentError, "type must be one of #{RECORD_TYPES.join(', ')}"
      end
    end
    # rubocop:enable Style/GuardClause
  end
end
