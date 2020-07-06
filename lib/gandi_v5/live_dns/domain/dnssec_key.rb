# frozen_string_literal: true

class GandiV5
  class LiveDNS
    class Domain
      # A DNSSEC key for a domain's DNS records.
      # @!attribyte [r] uuid
      #   @return [String]
      # @!attribyte [r] status
      #   @return [String]
      # @!attribyte [r] fqdn
      #   @return [String]
      # @!attribyte [r] algorithm_id
      #   @return [Integer]
      # @!attribyte [r] algorithm_name
      #   @return [String]
      # @!attribyte [r] deleted
      #   @return [Boolean]
      # @!attribyte [r] ds
      #   @return [String]
      # @!attribyte [r] flags
      #   @return [Integer]
      # @!attribyte [r] fingerprint
      #   @return [String]
      # @!attribyte [r] public_key
      #   @return [String]
      # @!attribyte [r] tag
      #   @return [String]
      class DnssecKey
        include GandiV5::Data

        members :status, :fqdn, :deleted, :ds, :flags, :fingerprint, :public_key,
                :tag, :algorithm_name

        member :uuid, gandi_key: 'id'
        member :algorithm_id, gandi_key: 'algorithm'

        # Delete this key.
        # @return [String] The confirmation message from Gandi.
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def delete
          _response, data = GandiV5.delete url
          self.deleted = true
          data['message']
        end

        # Undelete this key.
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
        # @param fqdn [String, #to_s] The fully qualified domain name to get the keys for.
        # @return [Array<GandiV5::LiveDNS::Domain::DnssecKey>]
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def self.list(fqdn)
          _response, data = GandiV5.get url(fqdn)
          data.map { |item| from_gandi item }
        end

        # Get DNSSEC key from Gandi.
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
