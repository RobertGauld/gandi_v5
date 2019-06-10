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

      # @overload fetch_records()
      #   Fetch all records for this domain.
      # @overload fetch_records(name)
      #   Fetch records for a name.
      #   @param name [String] the name to fetch records for.
      # @overload fetch_records(name, type)
      #   Fetch records of a type for a name.
      #   @param name [String] the name to fetch records for.
      #   @param type [String] the record type to fetch.
      # @return [Array<GandiV5::LiveDNS::RecordSet>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def fetch_records(name = nil, type = nil)
        GandiV5::LiveDNS.require_valid_record_type type if type

        url_ = "#{url}/records"
        url_ += "/#{CGI.escape name}" if name
        url_ += "/#{CGI.escape type}" if type

        _response, data = GandiV5.get url_
        data = [data] unless data.is_a?(Array)
        data.map { |item| GandiV5::LiveDNS::RecordSet.from_gandi item }
      end

      # @overload fetch_zone_lines()
      #   Fetch all records for this domain.
      # @overload fetch_zone_lines(name)
      #   Fetch records for a name.
      #   @param name [String] the name to fetch records for.
      # @overload fetch_zone_lines(name, type)
      #   Fetch records of a type for a name.
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
      # @overload delete_records(name)
      #   Delete records for a name.
      #   @param name [String] the name to delete records for.
      # @overload delete_records(name, type)
      #   Delete records of a type for a name.
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

      # Replace all records for this domain.
      # @param records
      #   [Array<Hash<:name, :type => String, :ttl => Integer, :values => Array<String>>>]
      #   the records to add.
      # @param text [String] zone file lines to replace the records with.
      # @return [String] The confirmation message from Gandi.
      # @raise [ArgumentError] if neither/both of records & test are passed.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def replace_records(records: nil, text: nil)
        unless [records, text].count(&:nil?).eql?(1)
          fail ArgumentError, 'you must pass ONE of records: or text:'
        end

        if records
          body = {
            items: records.map { |r| r.transform_keys { |k| "rrset_#{k}" } }
          }.to_json
          _response, data = GandiV5.put "#{url}/records", body
        elsif text
          _response, data = GandiV5.put "#{url}/records", text, 'content-type': 'text/plain'
        end
        data['message']
      end

      # Replace records for a name in this domain.
      # @param name [String]
      # @param records
      #   [Array<Hash<type: String, ttl: Integer, values: Array<String>>>]
      #   the records to add.
      # @return [String] The confirmation message from Gandi.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def replace_records_for(name, *records)
        body = {
          items: records.map { |r| r.transform_keys { |k| "rrset_#{k}" } }
        }.to_json
        _response, data = GandiV5.put "#{url}/records/#{name}", body
        data['message']
      end

      GandiV5::LiveDNS::RECORD_TYPES.each do |type|
        # Replace records of a given type for a name in this domain.
        # @return [String] The confirmation message from Gandi.
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        define_method "replace_#{type.downcase}_records_for" do |name, ttl, *values|
          body = {
            rrset_ttl: ttl,
            rrset_values: values
          }.to_json
          _response, data = GandiV5.put "#{url}/records/#{name}/#{type}", body
          data['message']
        end
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
