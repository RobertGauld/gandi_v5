# frozen_string_literal: true

class GandiV5
  class LiveDNS
    class Zone
      # A snapshot (backup) of a zone.
      # @!attribute [r] uuid
      #   @return [String]
      # @!attribute [r] zone_uuid
      #   @return [String]
      # @!attribute [r] created_at
      #   @return [Time]
      # @!attribute [r] records
      #   @return [Array<GandiV5::LiveDNS::RecordSet>]
      class Snapshot
        include GandiV5::Data

        members :uuid, :zone_uuid
        member :created_at, gandi_key: 'date_created', converter: GandiV5::Data::Converter::Time
        member(
          :records,
          gandi_key: 'zone_data',
          converter: GandiV5::LiveDNS::RecordSet,
          array: true
        )

        alias snapshot_uuid uuid

        # Delete this snapshot.
        # @return [String] The confirmation message from Gandi.
        # @raise [GandiV5::Error::GandiError::GandiError] if Gandi returns an error.
        def delete
          _response, data = GandiV5.delete url
          data['message']
        end

        # Get snapshot from Gandi.
        # @param zone_uuid [String, #to_s] the UUID of the zone the snapshot was made of.
        # @param snapshot_uuid [String, #to_s] the UUID of the snapshot to fetch.
        # @return [GandiV5::LiveDNS::Zone::Snapshot]
        # @raise [GandiV5::Error::GandiError::GandiError] if Gandi returns an error.
        def self.fetch(zone_uuid, snapshot_uuid)
          _response, data = GandiV5.get url(zone_uuid, snapshot_uuid)
          from_gandi data
        end

        private

        def url
          "#{BASE}zones/#{CGI.escape zone_uuid}/snapshots/#{CGI.escape uuid}"
        end

        def self.url(zone_uuid, snapshot_uuid)
          "#{BASE}zones/#{CGI.escape zone_uuid}/snapshots/#{CGI.escape snapshot_uuid}"
        end
        private_class_method :url
      end
    end
  end
end
