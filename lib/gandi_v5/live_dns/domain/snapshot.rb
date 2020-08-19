# frozen_string_literal: true

class GandiV5
  class LiveDNS
    class Domain
      # A snapshot (backup) of a domain's DNS records.
      # @!attribute [r] fqdn
      #   @return [String]
      # @!attribute [r] uuid
      #   @return [String]
      # @!attribute [r] name
      #   @return [String]
      # @!attribute [r] created_at
      #   @return [Time]
      # @!attribute [r] automatic
      #   @return [Boolean]
      class Snapshot
        include GandiV5::Data

        members :name, :automatic, :fqdn
        member :created_at, converter: GandiV5::Data::Converter::Time
        member :uuid, gandi_key: 'id'
        member(
          :records,
          gandi_key: 'zone_data',
          converter: GandiV5::LiveDNS::Domain::Record,
          array: true
        )

        alias snapshot_uuid uuid

        # Delete this snapshot.
        # @see https://api.gandi.net/docs/livedns/#delete-v5-livedns-domains-fqdn-snapshots-id
        # @return [String] The confirmation message from Gandi.
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def delete
          _response, data = GandiV5.delete url
          data['message']
        end

        # Update this snapshot.
        # @see https://api.gandi.net/docs/livedns/#patch-v5-livedns-domains-fqdn-snapshots-id
        # @param name [String, #to_s] new name for the snapshot.
        # @return [String] The confirmation message from Gandi.
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def update(name:)
          _response, data = GandiV5.patch url, { name: name }.to_json
          self.name = name
          data['message']
        end

        # Get snapshot details for this FQDN from Gandi.
        # @see https://api.gandi.net/docs/livedns/#get-v5-livedns-domains-fqdn-snapshots
        # @param fqdn [String, #to_s] The fully qualified domain name to get the snapshots for.
        # @param page [#each<Integer, #to_s>] the page(s) of results to retrieve.
        #   If page is not provided keep querying until an empty list is returned.
        #   If page responds to .each then iterate until an empty list is returned.
        # @param per_page [Integer, #to_s] (optional default 100) how many results to get per page.
        # @param automatic [nil, Boolean] (optional) filter by automatic or manual snapshot.
        # @return [Array<GandiV5::LiveDNS::Domain::Snapshot>]
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def self.list(fqdn, page: (1..), per_page: 100, **params)
          params.reject! { |_k, v| v.nil? }

          snapshots = []
          GandiV5.paginated_get(url(fqdn), page, per_page, params: params) do |data|
            snapshots += data.map { |item| from_gandi item.merge(fqdn: fqdn) }
          end
          snapshots
        end

        # Get snapshot from Gandi.
        # @see https://api.gandi.net/docs/livedns/#get-v5-livedns-domains-fqdn-snapshots-id
        # @param fqdn [String, #to_s] The fully qualified domain name the snapshot was made for.
        # @param uuid [String, #to_s] the UUID of the snapshot to fetch.
        # @return [GandiV5::LiveDNS::Domain::Snapshot]
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def self.fetch(fqdn, uuid)
          _response, data = GandiV5.get url(fqdn, uuid)
          from_gandi data.merge(fqdn: fqdn)
        end

        # Get the records which makeup this snapshot (fetching from Gandi if required).
        # @return [Array<GandiV5::LiveDNS::Domain::Record>]
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def records
          return @records unless @records.nil?

          @records = fetch_records
        end

        private

        def fetch_records
          _response, data = GandiV5.get url
          data.fetch('zone_data').map { |item| GandiV5::LiveDNS::Domain::Record.from_gandi item }
        end

        def url
          "#{BASE}livedns/domains/#{CGI.escape fqdn}/snapshots/#{CGI.escape uuid}"
        end

        def self.url(fqdn, snapshot_uuid = nil)
          "#{BASE}livedns/domains/#{CGI.escape fqdn}/snapshots" +
            (snapshot_uuid ? "/#{CGI.escape snapshot_uuid}" : '')
        end
        private_class_method :url
      end
    end
  end
end
