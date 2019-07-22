# frozen_string_literal: true

class GandiV5
  class LiveDNS
    # Methods for handling record related requests in both
    # GandiV5::LiveDNS::Domain and GandiV5::LiveDNS::Zone.
    module HasZoneRecords
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

      # @override replace_records_for(name, records)
      #   Replace records for a name in this domain.
      #   @param name [String]
      #   @param records
      #     [Array<Hash<type: String, ttl: Integer, values: Array<String>>>]
      #     the records to add.
      # @override replace_records_for(name, values, type: nil, ttl: nil)
      #   Replace records for a name in this domain.
      #   @param name [String]
      #   @param type [String] the record type.
      #   @param ttl [Integer] the TTL to set for the record.
      #   @param values [Array<String>] the values to set for the record.
      #   @raise [ArgumentError] if ttl is present and type is absent.
      # @return [String] The confirmation message from Gandi.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def replace_records_for(name, records, type: nil, ttl: nil)
        fail ArgumentError, 'missing keyword: type' if ttl && type.nil?

        if type
          GandiV5::LiveDNS.require_valid_record_type type
          body = { rrset_values: records, rrset_ttl: ttl }
          # body[:rrset_ttl] = ttl if ttl
          _response, data = GandiV5.put "#{url}/records/#{name}/#{type}", body.to_json

        else
          body = {
            items: records.map { |r| r.transform_keys { |k| "rrset_#{k}" } }
          }
          _response, data = GandiV5.put "#{url}/records/#{name}", body.to_json
        end

        data['message']
      end
    end
  end
end
