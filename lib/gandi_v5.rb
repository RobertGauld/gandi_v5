# frozen_string_literal: true

require 'json'
require 'rest_client'
require 'securerandom'
require 'zeitwerk'

# Custom inflector for Zeitwerk.
# @api private
class MyInflector < Zeitwerk::Inflector
  # Convert file's base name to class name when
  # Zeitwerk's included inflector gets it wrong.
  # @param basename [String] the file's base name (no path or extension)
  # @param _abspath [String] the file's absolute path
  # @return [String] the class name
  def camelize(basename, _abspath)
    case basename
    when 'dns_record'
      'DNSRecord'
    when 'live_dns'
      'LiveDNS'
    when 'tld'
      'TLD'
    when 'version'
      'VERSION'
    else
      super
    end
  end
end

loader = Zeitwerk::Loader.for_gem
loader.inflector = MyInflector.new
loader.setup

# Namespace for classes which access the Gandi V5 API.
# Also provides useful methods and constants for them.
# To get your API key login to Gandi and visit
# "User Settings" -> "Change password & configure access restrictions".
# Set your API key either in the GANDI_API_KEY environment variable or
# by setting the api_key class attribute.
# @see https://api.gandi.net/docs/
# @see https://doc.livedns.gandi.net/
# @!attribute [w] api_key
#   @return [String]
class GandiV5
  # Base URL for all API requests.
  BASE = 'https://api.gandi.net/v5/'

  # Get information on a domain.
  # @see GandiV5::Domain.fetch
  def self.domain(fqdn)
    GandiV5::Domain.fetch(fqdn)
  end

  # Get information on all domains.
  # @see GandiV5::Domain.list
  def self.domains(**params)
    GandiV5::Domain.list(**params)
  end

  # List mailboxes for a domain.
  # @see GandiV5::Email::Mailbox.list
  def self.mailboxes(fqdn, **params)
    GandiV5::Email::Mailbox.list(fqdn, **params)
  end

  # List email slots for a domain.
  # @see GandiV5::Email::Slot.list
  def self.mailbox_slots(fqdn)
    GandiV5::Email::Slot.list(fqdn)
  end

  class << self
    attr_writer :api_key

    # Make a GET request to a Gandi end point.
    # @param url [String, #to_s]
    #   the full URL (including GandiV5::BASE) to fetch.
    # @param headers [Hash{String, Symbol, #to_s => String, Symbol, #to_s}]
    #   the headers to send in the request, the authorisation will be added.
    # @return [Array<(RestClient::Response, Object)>]
    #   The response from the server and the result of parsing the responce's body.
    # @raise [RestClient::NotFound]
    # @raise [RestClient::Unauthorized]
    #   Bad authentication attempt because of a wrong API Key.
    # @raise [RestClient::Forbidden]
    #   Access to the resource is denied.
    #   Mainly due to a lack of permissions to access it.
    # @raise [GandiV5::Error]
    # @raise [JSON::ParserError]
    def get(url, **headers)
      prepare_headers headers, url
      response = RestClient.get url, **headers
      [response, parse_response(response)]
    rescue RestClient::BadRequest => e
      handle_bad_request(e)
    end

    # Make a GET request to a paginated end point at Gandi.
    # @param url [String, #to_s]
    #   the full URL (including GandiV5::BASE) to fetch.
    # @param page [#each, Integer] the page/pages of results to get.
    # @param per_page [Integer, #to_s] the number of items to get per page of results.
    # @param headers [Hash{String, Symbol, #to_s => String, Symbol, #to_s}]
    #   the headers to send in the request, the authorisation will be added.
    # @return [Array<(RestClient::Response, Object)>]
    #   The response from the server and the result of parsing the responce's body.
    # @raise [RestClient::NotFound]
    # @raise [RestClient::Unauthorized]
    #   Bad authentication attempt because of a wrong API Key.
    # @raise [RestClient::Forbidden]
    #   Access to the resource is denied.
    #   Mainly due to a lack of permissions to access it.
    # @raise [GandiV5::Error]
    # @raise [JSON::ParserError]
    def paginated_get(url, page = (1..), per_page = 100, **headers)
      unless page.respond_to?(:each)
        fail ArgumentError, 'page must be positive' unless page.positive?

        page = [page]
      end

      headers[:params] ||= {}
      headers[:params].transform_keys!(&:to_s)
      headers[:params]['per_page'] = per_page

      page.each do |page_number|
        headers[:params]['page'] = page_number
        _resp, this_data = get(url, **headers)
        break if this_data.empty?

        yield this_data
        break if this_data.count < per_page
      end
    end

    # Make a DELETE request to a Gandi end point.
    # @param url [String, #to_s]
    #   the full URL (including GandiV5::BASE) to fetch.
    # @param headers [Hash{String, Symbol, #to_s => String, Symbol, #to_s}]
    #   the headers to send in the request, the authorisation will be added.
    # @return [Array<(RestClient::Response, Object)>]
    #   The response from the server and the result of parsing the responce's body.
    # @raise [RestClient::NotFound]
    # @raise [RestClient::Unauthorized]
    #   Bad authentication attempt because of a wrong API Key.
    # @raise [RestClient::Forbidden]
    #   Access to the resource is denied.
    #   Mainly due to a lack of permissions to access it.
    # @raise [GandiV5::Error]
    # @raise [JSON::ParserError]
    def delete(url, **headers)
      prepare_headers headers, url
      response = RestClient.delete url, **headers
      [
        response,
        response.headers.key?(:content_type) ? parse_response(response) : nil
      ]
    rescue RestClient::BadRequest => e
      handle_bad_request(e)
    end

    # Make a PATCH request to a Gandi end point.
    # @param url [String, #to_s]
    #   the full URL (including GandiV5::BASE) to fetch.
    # @param payload [String, #to_s] the body for the request.
    # @param headers [Hash{String, Symbol, #to_s => String, Symbol, #to_s}]
    #   the headers to send in the request, the authorisation will be added.
    # @return [Array<(RestClient::Response, Object)>]
    #   The response from the server and the result of parsing the responce's body.
    # @raise [RestClient::NotFound]
    # @raise [RestClient::Unauthorized]
    #   Bad authentication attempt because of a wrong API Key.
    # @raise [RestClient::Forbidden]
    #   Access to the resource is denied.
    #   Mainly due to a lack of permissions to access it.
    # @raise [RestClient::BadRequest]
    # @raise [RestClient::Conflict]
    # @raise [GandiV5::Error]
    # @raise [JSON::ParserError]
    def patch(url, payload = '', **headers)
      prepare_headers headers, url
      headers[:'content-type'] ||= 'application/json'
      response = RestClient.patch url, payload, **headers
      [response, parse_response(response)]
    rescue RestClient::BadRequest => e
      handle_bad_request(e)
    end

    # Make a POST request to a Gandi end point.
    # @param url [String, #to_s]
    #   the full URL (including GandiV5::BASE) to fetch.
    # @param payload [String, #to_s] the body for the request.
    # @param headers [Hash{String, Symbol, #to_s => String, Symbol, #to_s}]
    #   the headers to send in the request, the authorisation will be added.
    # @return [Array<(RestClient::Response, Object)>]
    #   The response from the server and the result of parsing the responce's body.
    # @raise [RestClient::NotFound]
    # @raise [RestClient::Unauthorized]
    #   Bad authentication attempt because of a wrong API Key.
    # @raise [RestClient::Forbidden]
    #   Access to the resource is denied.
    #   Mainly due to a lack of permissions to access it.
    # @raise [RestClient::BadRequest]
    # @raise [RestClient::Conflict]
    # @raise [GandiV5::Error]
    # @raise [JSON::ParserError]
    def post(url, payload = '', **headers)
      prepare_headers headers, url
      headers[:'content-type'] ||= 'application/json'
      response = RestClient.post url, payload, **headers
      [response, parse_response(response)]
    rescue RestClient::BadRequest => e
      handle_bad_request(e)
    end

    # Make a PUT request to a Gandi end point.
    # @param url [String, #to_s]
    #   the full URL (including GandiV5::BASE) to fetch.
    # @param payload [String, #to_s] the body for the request.
    # @param headers [Hash{String, Symbol, #to_s => String, Symbol, #to_s}]
    #   the headers to send in the request, the authorisation will be added
    # @return [Array<(RestClient::Response, Object)>]
    #   The response from the server and the result of parsing the responce's body.
    # @raise [RestClient::NotFound]
    # @raise [RestClient::Unauthorized]
    #   Bad authentication attempt because of a wrong API Key.
    # @raise [RestClient::Forbidden]
    #   Access to the resource is denied.
    #   Mainly due to a lack of permissions to access it.
    # @raise [RestClient::BadRequest]
    # @raise [RestClient::Conflict]
    # @raise [GandiV5::Error]
    # @raise [JSON::ParserError]
    def put(url, payload = '', **headers)
      prepare_headers headers, url
      headers[:'content-type'] ||= 'application/json'
      response = RestClient.put url, payload, **headers
      [response, parse_response(response)]
    rescue RestClient::BadRequest => e
      handle_bad_request(e)
    end

    private

    def api_key
      @api_key ||= ENV.fetch('GANDI_API_KEY')
    end

    def parse_response(response)
      type = response.headers.fetch(:content_type).split(';').first.chomp
      case type
      when 'text/plain'
        response.body.to_s
      when 'application/json'
        response = JSON.parse(response.body)
        if response.is_a?(Hash) && response['status'].eql?('error')
          fail GandiV5::Error::GandiError.from_hash(response)
        end

        response
      else
        fail ArgumentError, "Don't know how to parse a #{type} response"
      end
    end

    def prepare_headers(headers, _url)
      headers.transform_keys! { |key| key.to_s.downcase.to_sym }
      headers[:accept] ||= 'application/json'
      headers[:authorization] = "Apikey #{api_key}"
      headers
    end

    def handle_bad_request(exception)
      data = JSON.parse exception.response.body
      unless data.is_a?(Hash) && data['status'].eql?('error') && data['errors'].is_a?(Array)
        raise exception
      end

      field, message = data['errors'].first.values_at('name', 'description')
      fail GandiV5::Error::GandiError, "#{field}: #{message}"
    rescue JSON::ParserError
      raise exception
    end
  end
end
