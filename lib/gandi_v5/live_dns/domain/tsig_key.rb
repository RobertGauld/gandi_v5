# frozen_string_literal: true

class GandiV5
  class LiveDNS
    class Domain
      # A Tsig key.
      # @!attribute [r] uuid
      #   @return [String]
      # @!attribute [r] name
      #   @return [String]
      # @!attribute [r] secret
      #   @return [String]
      # @!attribute [r] config_examples
      #   @return [Hash<Symbol -> String>]
      class TsigKey
        include GandiV5::Data

        member :secret
        member :uuid, gandi_key: 'id'
        member :name, gandi_key: 'key_name'
        member(
          :config_examples,
          gandi_key: 'config_samples',
          converter: GandiV5::Data::Converter.new(
            from_gandi: ->(value) { value.transform_keys(&:to_sym) },
            to_gandi: ->(_value) {}
          )
        )

        # Create a new DNSSEC key for a zone.
        # @see https://api.gandi.net/docs/livedns/#post-v5-livedns-axfr-tsig
        # @param sharing_id [nil, String, #to_s]
        # @return [GandiV5::LiveDNS::Domain::DnssecKey]
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def self.create(sharing_id = nil)
          url_ = url
          url_ += "?sharing_id=#{CGI.escape sharing_id}" if sharing_id

          _response, data = GandiV5.post url_
          fetch data.fetch('id')
        end

        # Get keys from Gandi.
        # If you need the secret, fingerprint, public_key or tag attributes you'll need
        # to use GandiV5::LiveDNS::Domain::DnssecKey.fetch on each item.
        # @see https://api.gandi.net/docs/livedns/#get-v5-livedns-axfr-tsig
        # @return [Array<GandiV5::LiveDNS::Domain::TsigKey>]
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def self.list
          _response, data = GandiV5.get url
          data.map { |item| from_gandi item }
        end

        # Get Tsig key from Gandi.
        # @see https://api.gandi.net/docs/livedns/#get-v5-livedns-axfr-tsig-id
        # @param uuid [String, #to_s] the UUID of the key to fetch.
        # @return [GandiV5::LiveDNS::Domain::TsigKey]
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def self.fetch(uuid)
          _response, data = GandiV5.get url(uuid)
          from_gandi data
        end

        private

        def self.url(uuid = nil)
          "#{BASE}livedns/axfr/tsig" +
            (uuid ? "/#{CGI.escape uuid}" : '')
        end
        private_class_method :url
      end
    end
  end
end
