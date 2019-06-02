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

require_relative 'live_dns/record_set'
require_relative 'live_dns/domain'
require_relative 'live_dns/zone'
