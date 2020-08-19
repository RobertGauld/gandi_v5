# frozen_string_literal: true

class GandiV5
  class LiveDNS
    # A domain name within the LiveDNS system.
    # @!attribute [r] fqdn
    #   @return [String]
    # @!attribute [r] automatic_snapshots
    #   @return [Boolean]
    class Domain
      include GandiV5::Data

      members :fqdn, :automatic_snapshots

      # Refetch the information for this domain from Gandi.
      # @return [GandiV5::LiveDNS::Domain]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def refresh
        _response, data = GandiV5.get url
        from_gandi data
      end

      # Update this domain's settings.
      # @see https://api.gandi.net/docs/livedns/#patch-v5-livedns-domains-fqdn
      # @param automatic_snapshots [String, #to_s]
      #   Enable or disable the automatic creation of new snapshots when records are changed.
      # @return [String] The confirmation message from Gandi.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def update(automatic_snapshots:)
        _response, data = GandiV5.patch url, { automatic_snapshots: automatic_snapshots }.to_json
        self.automatic_snapshots = automatic_snapshots
        data['message']
      end

      # @overload fetch_records()
      #   Fetch all records for this domain.
      #   @see https://api.gandi.net/docs/livedns/#get-v5-livedns-domains-fqdn-records
      #   @param page [Integer, #each<Integer>] which page(s) of results to get.
      #     If page is not provided keep querying until an empty list is returned.
      #     If page responds to .each then iterate until an empty list is returned.
      #   @param per_page [Integer, #to_s] (optional default 100) how many results ot get per page.
      # @overload fetch_records(name)
      #   Fetch records for a name.
      #   @see https://api.gandi.net/docs/livedns/#get-v5-livedns-domains-fqdn-records-rrset_name
      #   @param name [String] the name to fetch records for.
      #   @param page [Integer, #each<Integer>] which page(s) of results to get.
      #     If page is not provided keep querying until an empty list is returned.
      #     If page responds to .each then iterate until an empty list is returned.
      #   @param per_page [Integer, #to_s] (optional default 100) how many results ot get per page.
      # @overload fetch_records(name, type)
      #   Fetch records of a type for a name.
      #   @see https://api.gandi.net/docs/livedns/#get-v5-livedns-domains-fqdn-records-rrset_name-rrset_type
      #   @param name [String] the name to fetch records for.
      #   @param type [String] the record type to fetch.
      #   @param page [Integer, #each<Integer>] which page(s) of results to get.
      #     If page is not provided keep querying until an empty list is returned.
      #     If page responds to .each then iterate until an empty list is returned.
      #   @param per_page [Integer, #to_s] (optional default 100) how many results ot get per page.
      # @return [Array<GandiV5::LiveDNS::Domain::Record>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def fetch_records(name = nil, type = nil, page: (1..), per_page: 100)
        GandiV5::LiveDNS.require_valid_record_type type if type

        url_ = "#{url}/records"
        url_ += "/#{CGI.escape name}" if name
        url_ += "/#{CGI.escape type}" if type

        all = []
        GandiV5.paginated_get(url_, page, per_page) do |data|
          all += [*data].map { |item| GandiV5::LiveDNS::Domain::Record.from_gandi item }
        end
        all
      end

      # @overload fetch_zone_lines()
      #   Fetch all records for this domain.
      #   @see https://api.gandi.net/docs/livedns/#get-v5-livedns-domains-fqdn-records
      # @overload fetch_zone_lines(name)
      #   Fetch records for a name.
      #   @see https://api.gandi.net/docs/livedns/#get-v5-livedns-domains-fqdn-records-rrset_name
      #   @param name [String] the name to fetch records for.
      # @overload fetch_zone_lines(name, type)
      #   Fetch records of a type for a name.
      #   @see https://api.gandi.net/docs/livedns/#get-v5-livedns-domains-fqdn-records-rrset_name-rrset_type
      #   @param name [String] the name to fetch records for.
      #   @param type [String] the record type to fetch.
      # @return [String]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def fetch_zone_lines(name = nil, type = nil)
        GandiV5::LiveDNS.require_valid_record_type type if type

        url_ = "#{url}/records"
        url_ += "/#{CGI.escape name}" if name
        url_ += "/#{CGI.escape type}" if type

        GandiV5.get(url_, accept: 'text/plain').last
      end

      # Add record to this domain.
      # @see https://api.gandi.net/docs/livedns/#post-v5-livedns-domains-fqdn-records
      # @param name [String]
      # @param type [String]
      # @param ttl [Integer]
      # @param values [Array<String>]
      # @return [String] The confirmation message from Gandi.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def add_record(name, type, ttl, *values)
        GandiV5::LiveDNS.require_valid_record_type type
        fail ArgumentError, 'ttl must be positive and non-zero' unless ttl.positive?
        fail ArgumentError, 'there must be at least one value' if values.none?

        body = {
          rrset_name: name,
          rrset_type: type,
          rrset_ttl: ttl,
          rrset_values: values
        }.to_json
        _response, data = GandiV5.post "#{url}/records", body
        data['message']
      end

      # @overload delete_records()
      #   Delete all records for this domain.
      #   @see https://api.gandi.net/docs/livedns/#delete-v5-livedns-domains-fqdn-records
      # @overload delete_records(name)
      #   Delete records for a name.
      #   @see https://api.gandi.net/docs/livedns/#delete-v5-livedns-domains-fqdn-records-rrset_name
      #   @param name [String] the name to delete records for.
      # @overload delete_records(name, type)
      #   Delete records of a type for a name.
      #   @see https://api.gandi.net/docs/livedns/#delete-v5-livedns-domains-fqdn-records-rrset_name-rrset_type
      #   @param name [String] the name to delete records for.
      #   @param type [String] the record type to delete.
      # @return [nil]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def delete_records(name = nil, type = nil)
        GandiV5::LiveDNS.require_valid_record_type(type) if type

        url_ = "#{url}/records"
        url_ += "/#{CGI.escape name}" if name
        url_ += "/#{CGI.escape type}" if type
        GandiV5.delete(url_).last
      end

      # Replace records for the domain.
      #   @param name [String, nil] only replaces records for this name.
      #   @param type [String, nil] only replaces record of this type (requires name).
      #   @param values [Array<String>] the values to set for the record.
      #   @raise [ArgumentError] if ttl is present and type is absent.
      # @see https://api.gandi.net/docs/livedns/#put-v5-livedns-domains-fqdn-records
      # @see https://api.gandi.net/docs/livedns/#put-v5-livedns-domains-fqdn-records-rrset_name
      # @see https://api.gandi.net/docs/livedns/#put-v5-livedns-domains-fqdn-records-rrset_name-rrset_type
      # @return [String] The confirmation message from Gandi.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      def replace_records(records, name: nil, type: nil)
        if type
          GandiV5::LiveDNS.require_valid_record_type(type) if type
          fail ArgumentError, 'missing keyword: name' if name.nil?
        end

        url_ = "#{url}/records"
        url_ += "/#{CGI.escape name}" if name
        url_ += "/#{CGI.escape type}" if type

        body = if type && name
                 { rrset_values: records }
               else
                 { items: records.map { |r| r.transform_keys { |k| "rrset_#{k}" } } }
               end

        _response, data = GandiV5.put url_, body.to_json
        data['message']
      end
      # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

      # Replace all records for this domain.
      # @see https://api.gandi.net/docs/livedns/#put-v5-livedns-domains-fqdn-records
      # @param text [String] zone file lines to replace the records with.
      # @return [String] The confirmation message from Gandi.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def replace_zone_lines(text)
        _response, data = GandiV5.put "#{url}/records", text, 'content-type': 'text/plain'
        data['message']
      end

      # The list of nameservers that this domain is using according to LiveDNS' systems.
      #  * Either there are no NS records on @ and the 3 hashed nameservers are returned
      #    (ns-{123}-{abc}.gandi.net)
      #  * Or some NS records exist on @ and it will return those
      # @see https://api.gandi.net/docs/domains#get-v5-domain-domains-domain-name$
      # @return [Array<String>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def name_servers
        @name_servers ||= fetch_name_servers
      end

      # Requery Gandi for the domain's name servers.
      # @see https://api.gandi.net/docs/domains#get-v5-domain-domains-domain-name$
      # @return [Array<String>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def fetch_name_servers
        _response, data = GandiV5.get "#{url}/nameservers"
        @name_servers = data
      end

      # The list of DNSSEC keys for the domain.
      # If you need the fingerprint, public_key or tag attributes you'll need
      # use GandiV5::LiveDNS::Domain::DnssecKey.fetch on each item.
      # @return [Array<GandiV5::LiveDNS::Domain::DnssecKey>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def dnssec_keys
        @dnssec_keys ||= fetch_dnssec_keys
      end

      # Requery Gandi for the domain's DNSSEC keys.
      # @see https://api.gandi.net/docs/livedns/#get-v5-livedns-domains-fqdn-keys
      # @return [Array<GandiV5::LiveDNS::Domain::DnssecKey>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def fetch_dnssec_keys
        @dnssec_keys = GandiV5::LiveDNS::Domain::DnssecKey.list(fqdn)
      end

      # The list of TSIG keys for the domain.
      # If you need the secret, fingerprint, public_key or tag attributes you'll need
      # to use GandiV5::LiveDNS::Domain::DnssecKey.fetch on each item.
      # @return [Array<GandiV5::LiveDNS::Domain::TsigKey>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def tsig_keys
        @tsig_keys ||= fetch_tsig_keys
      end

      # Requery Gandi for the domain's TSIG keys.
      # @see https://api.gandi.net/docs/livedns/#get-v5-livedns-domains-fqdn-axfr-tsig
      # @return [Array<GandiV5::LiveDNS::Domain::TsigKey>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def fetch_tsig_keys
        _response, data = GandiV5.get "#{url}/axfr/tsig"
        data.map { |item| GandiV5::LiveDNS::Domain::TsigKey.from_gandi item }
      end

      # Add a Tsig key to this domain.
      # @see https://api.gandi.net/docs/livedns/#put-v5-livedns-domains-fqdn-axfr-tsig-id
      # @param key [GandiV5::LiveDNS::Domain::TsigKey, #uuid, String, #to_s]
      #   the key to add.
      # @param sharing_id [nil, String, #to_s]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def add_tsig_key(key, sharing_id: nil)
        key = key.uuid if key.respond_to?(:uuid)
        url_ = "#{url}/axfr/tsig/#{key}"
        url_ += "?sharing_id=#{CGI.escape sharing_id}" if sharing_id
        _response, _data = GandiV5.put url_
      end

      # Remove a Tsig key from this domain.
      # @see https://api.gandi.net/docs/livedns/#delete-v5-livedns-domains-fqdn-axfr-tsig-id
      # @param key [GandiV5::LiveDNS::Domain::TsigKey, #uuid, String, #to_s]
      #   the key to remove.
      # @param sharing_id [nil, String, #to_s]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def remove_tsig_key(key, sharing_id: nil)
        key = key.uuid if key.respond_to?(:uuid)
        url_ = "#{url}/axfr/tsig/#{key}"
        url_ += "?sharing_id=#{CGI.escape sharing_id}" if sharing_id
        _response, _data = GandiV5.delete url_
      end

      # The list of AXFR clients for the domain.
      # @return [Array<String>] list of IP addresses.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def axfr_clients
        @axfr_clients ||= fetch_axfr_clients
      end

      # Requery Gandi for the domain's AXFR clients.
      # @see https://api.gandi.net/docs/livedns/#get-v5-livedns-domains-fqdn-axfr-slaves
      # @return [Array<String>] list of IP addresses.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def fetch_axfr_clients
        _response, data = GandiV5.get "#{url}/axfr/slaves"
        data
      end

      # Add an AXFR client to this domain.
      # @see https://api.gandi.net/docs/livedns/#put-v5-livedns-domains-fqdn-axfr-slaves-ip
      # @param ip [String, #to_s] the IP address to add.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def add_axfr_client(ip)
        _response, _data = GandiV5.put "#{url}/axfr/slaves/#{ip}"
      end

      # Remove and AXFR client from this domain.
      # @see https://api.gandi.net/docs/livedns/#delete-v5-livedns-domains-fqdn-axfr-slaves-ip
      # @param ip [String, #to_s] the IP address to remove.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def remove_axfr_client(ip)
        _response, _data = GandiV5.delete "#{url}/axfr/slaves/#{ip}"
      end

      # List the domains.
      # @see https://api.gandi.net/docs/livedns/#get-v5-livedns-domains
      # @param page [#each<Integer, #to_s>] the page(s) of results to retrieve.
      #   If page is not provided keep querying until an empty list is returned.
      #   If page responds to .each then iterate until an empty list is returned.
      # @param per_page [Integer, #to_s] (optional default 100) how many results to get per page.
      # @param sharing_id [String, #to_s] (optional) filter by domains assigned to a given user.
      # @return [Array<String>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.list(page: (1..), per_page: 100, sharing_id: nil)
        page = [page.to_i] unless page.respond_to?(:each)
        params = { per_page: per_page }
        params[:sharing_id] = sharing_id unless sharing_id.nil?

        domains = []
        page.each do |page_number|
          _resp, data = GandiV5.get url, params: params.merge(page: page_number)
          break if data.empty?

          domains += data.map { |item| item['fqdn'] }
          break if data.count < per_page
        end
        domains
      end

      # Get a domain.
      # @see https://api.gandi.net/docs/livedns/#get-v5-livedns-domains-fqdn
      # @param fqdn [String, #to_s] the fully qualified domain name to fetch.
      # @return [GandiV5::LiveDNS::Domain]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.fetch(fqdn)
        _response, data = GandiV5.get url(fqdn)
        from_gandi data
      end

      # Create a new domain in the LiveDNS system.
      # You must have sufficent permission to manage the domain to do this.
      # @see https://api.gandi.net/docs/livedns/#post-v5-livedns-domains
      # @param fqdn [String, #to_s] the fully qualified domain to add to LiveDNS.
      # @param records [Array<Hash, GandiV5::LiveDNS::Domain::Record, #to_h, nil>]
      # @param ttl [Integer, #to_s, nil] the TTL of the SOA record.
      #   Note that this is not a default TTL that will be used for the records in the zone.
      #   the records (if any) to add to the created zone.
      # @param sharing_id [nil, String, #to_s]
      # @return [GandiV5::LiveDNS::Domain]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.create(fqdn, records = nil, soa_ttl: nil, sharing_id: nil)
        body = { fqdn: fqdn, zone: {} }
        body[:zone][:ttl] = soa_ttl if soa_ttl
        if records
          body[:zone][:items] = records.map do |r|
            r.to_h.transform_keys { |k| "rrset_#{k}" }
          end
        end

        url_ = url
        url_ += "?sharing_id=#{CGI.escape sharing_id}" if sharing_id

        GandiV5.post url_, body.to_json
        fetch(fqdn)
      end

      # Fetch the list of known record types (A, CNAME, etc.)
      # @see https://api.gandi.net/docs/livedns/#get-v5-livedns-dns-rrtypes
      # @return [Array<String>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.record_types
        GandiV5.get("#{BASE}livedns/dns/rrtypes").last
      end

      # Get the LiveDNS servers to use for a domain.
      # @note Does not take into account any NS records that exist in the zone.
      # @see https://api.gandi.net/docs/livedns/#get-v5-livedns-nameservers-fqdn
      # @param fqdn [String, #to_s] the fully qualified domain to hash in
      #   in order to get the LiveDNS servers to use.
      # @return [Array<String>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.generic_name_servers(fqdn)
        GandiV5.get("#{BASE}livedns/nameservers/#{CGI.escape fqdn}").last
      end

      private

      def url
        "#{BASE}livedns/domains/#{CGI.escape fqdn}"
      end

      def self.url(fqdn = nil)
        "#{BASE}livedns/domains" + (fqdn ? "/#{CGI.escape fqdn}" : '')
      end
      private_class_method :url
    end
  end
end
