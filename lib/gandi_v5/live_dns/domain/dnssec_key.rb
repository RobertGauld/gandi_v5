# frozen_string_literal: true

class GandiV5
  class LiveDNS
    class Domain
      # A DNSSEC key for a domain's DNS records.
      # @!attribute [r] uuid
      #   @return [String]
      # @!attribute [r] status
      #   @return [String]
      # @!attribute [r] fqdn
      #   @return [String]
      # @!attribute [r] algorithm_id
      #   @return [Integer]
      # @!attribute [r] algorithm_name
      #   @return [String]
      # @!attribute [r] deleted
      #   @return [Boolean]
      # @!attribute [r] ds
      #   @return [String]
      # @!attribute [r] flags
      #   @return [Integer]
      # @!attribute [r] fingerprint
      #   @return [String]
      # @!attribute [r] public_key
      #   @return [String]
      # @!attribute [r] tag
      #   @return [String]
      class DnssecKey
        include GandiV5::Data

        members :status, :fqdn, :deleted, :ds, :flags, :fingerprint, :public_key,
                :tag, :algorithm_name

        member :uuid, gandi_key: 'id'
        member :algorithm_id, gandi_key: 'algorithm'

        # Delete this key.
        # @see https://api.gandi.net/docs/livedns/#delete-v5-livedns-domains-fqdn-keys-id
        # @return [String] The confirmation message from Gandi.
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def delete
          _response, data = GandiV5.delete url
          self.deleted = true
          data['message']
        end

        # Undelete this key.
        # @see https://api.gandi.net/docs/livedns/#patch-v5-livedns-domains-fqdn-keys-id
        # @return [String] The confirmation message from Gandi.
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def undelete
          _response, data = GandiV5.patch url, { deleted: false }.to_json
          self.deleted = false
          data['message']
        end

        # Check if this is a zone signing key
        # @return [Boolean]
        def zone_signing_key?
          flags == 256
        end

        # Check if this is a key signing key
        # @return [Boolean]
        def key_signing_key?
          flags == 257
        end

        # Create a new DNSSEC key for a zone.
        # @see https://api.gandi.net/docs/livedns/#post-v5-livedns-domains-fqdn-keys
        # @param fqdn [String, #to_s] the fully qualified domain to create the key for.
        # @param flags [Integer, :key_signing_key, :zone_signing_key] the key's flags.
        # @return [GandiV5::LiveDNS::Domain::DnssecKey]
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def self.create(fqdn, flags)
          flags = 256 if flags == :zone_signing_key
          flags = 257 if flags == :key_signing_key
          fail ArgumentError, 'flags is invalid' unless flags.is_a?(Integer)

          response, _data = GandiV5.post url(fqdn), { flags: flags }.to_json
          fetch fqdn, response.headers[:location].split('/').last
        end

        # Get keys for a FQDN from Gandi.
        # @see https://api.gandi.net/docs/livedns/#get-v5-livedns-domains-fqdn-keys
        # @param fqdn [String, #to_s] The fully qualified domain name to get the keys for.
        # @return [Array<GandiV5::LiveDNS::Domain::DnssecKey>]
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def self.list(fqdn)
          _response, data = GandiV5.get url(fqdn)
          data.map { |item| from_gandi item }
        end

        # Get DNSSEC key from Gandi.
        # @see https://api.gandi.net/docs/livedns/#get-v5-livedns-domains-fqdn-keys-id
        # @param fqdn [String, #to_s] The fully qualified domain name the key was made for.
        # @param uuid [String, #to_s] the UUID of the key to fetch.
        # @return [GandiV5::LiveDNS::Domain::DnssecKey]
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def self.fetch(fqdn, uuid)
          _response, data = GandiV5.get url(fqdn, uuid)
          from_gandi data
        end

        private

        def url
          "#{BASE}livedns/domains/#{CGI.escape fqdn}/keys/#{CGI.escape uuid}"
        end

        def self.url(fqdn, uuid = nil)
          "#{BASE}livedns/domains/#{CGI.escape fqdn}/keys" +
            (uuid ? "/#{CGI.escape uuid}" : '')
        end
        private_class_method :url
      end
    end
  end
end
