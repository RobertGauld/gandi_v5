# frozen_string_literal: true

class GandiV5
  class LiveDNS
    # A domain name within the LiveDNS system.
    # @!attribute [r] fqdn
    #   @return [String]
    # @!attribute [r] zone_uuid
    #   @return [String]
    class Domain
      include GandiV5::Data
      include GandiV5::LiveDNS::HasZoneRecords

      members :fqdn

      member(
        :zone_uuid,
        gandi_key: 'zone',
        converter: GandiV5::Data::Converter.new(from_gandi: ->(zone) { zone&.split('/')&.last })
      )

      # Refetch the information for this domain from Gandi.
      # @return [GandiV5::LiveDNS::Domain]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def refresh
        _response, data = GandiV5.get url
        from_gandi data
      end

      # Change the zone used by this domain.
      # @param uuid [String, #uuid, #to_s] the UUID of the zone this domain should now use.
      # @return [String] The confirmation message from Gandi.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def change_zone(uuid)
        uuid = uuid.uuid if uuid.respond_to?(:uuid)
        _response, data = GandiV5.patch url, { zone_uuid: uuid }.to_json
        self.zone_uuid = uuid
        data['message']
      end

      # @see GandiV5::LiveDNS::Zone.fetch
      def fetch_zone
        GandiV5::LiveDNS::Zone.fetch zone_uuid
      end

      # The domain's zone (fetching from Gandi if required).
      # @return [GandiV5::LiveDNS::Zone]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def zone
        @zone ||= fetch_zone
      end

      # List the domains.
      # @return [Array<GandiV5::LiveDNS::Domain>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.list
        _response, data = GandiV5.get url
        data.map { |item| from_gandi item }
      end

      # Get a domain.
      # @param fqdn [String, #to_s] the fully qualified domain name to fetch.
      # @return [GandiV5::LiveDNS::Domain]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.fetch(fqdn)
        _response, data = GandiV5.get url(fqdn)
        from_gandi data
      end

      private

      def url
        "#{BASE}domains/#{CGI.escape(fqdn)}"
      end

      def self.url(fqdn = nil)
        "#{BASE}domains" + (fqdn ? "/#{CGI.escape(fqdn)}" : '')
      end
      private_class_method :url
    end
  end
end
