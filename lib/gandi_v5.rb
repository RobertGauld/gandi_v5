# frozen_string_literal: true

require_relative 'gandi_v5/version'
require_relative 'gandi_v5/data'
require_relative 'gandi_v5/error'

require_relative 'gandi_v5/billing'
require_relative 'gandi_v5/domain'
require_relative 'gandi_v5/email'
require_relative 'gandi_v5/live_dns'
require_relative 'gandi_v5/organization'

require 'rest_client'
require 'securerandom'

# Namespace for classes which access the Gandi V5 API.
# Also provides useful methods and constants for them.
# This is where you configure the gem:
#  * Setting your Gandi API key:
#    1. Get your API key - Login to Gandi and visit User Settings ->
#       Change password & configure access restrictions.
# @see https://api.gandi.net/docs/
# @see https://doc.livedns.gandi.net/
# @!attribute [w] api_key
#   @return [String]
class GandiV5
  BASE = 'https://api.gandi.net/v5/'

  # @see GandiV5::Domain.fetch
  def self.domain(fqdn)
    GandiV5::Domain.fetch(fqdn)
  end

  # @see GandiV5::Domain.list
  def self.domains(**params)
    GandiV5::Domain.list(**params)
  end

  # @see GandiV5::Email::Mailbox.list
  def self.mailboxes(fqdn, **params)
    GandiV5::Email::Mailbox.list(fqdn, **params)
  end

  class << self
    attr_writer :api_key

    # Might raise:
    #  * RestClient::NotFound
    #  * RestClient::Unauthorized
    #      Bad authentication attempt because of a wrong API Key.
    #  * RestClient::Forbidden
    #      Access to the resource is denied.
    #      Mainly due to a lack of permissions to access it.
    #  * GandiV5::Error
    #  * JSON::ParserError
    def get(url, **headers)
      prepare_headers headers, url
      response = RestClient.get url, **headers
      [response, parse_response(response)]
    rescue RestClient::BadRequest => e
      handle_bad_request(e)
    end

    # Might raise:
    #  * RestClient::NotFound
    #  * RestClient::Unauthorized
    #      Bad authentication attempt because of a wrong API Key.
    #  * RestClient::Forbidden
    #      Access to the resource is denied.
    #      Mainly due to a lack of permissions to access it.
    #  * RestClient::Conflict
    #  * GandiV5::Error
    #  * JSON::ParserError
    def delete(url, **headers)
      prepare_headers headers, url
      response = RestClient.delete url, **headers
      [response, parse_response(response)]
    rescue RestClient::BadRequest => e
      handle_bad_request(e)
    end

    # Might raise:
    #  * RestClient::NotFound
    #  * RestClient::Unauthorized
    #      Bad authentication attempt because of a wrong API Key.
    #  * RestClient::Forbidden
    #      Access to the resource is denied.
    #      Mainly due to a lack of permissions to access it.
    #  * RestClient::BadRequest
    #  * RestClient::Conflict
    #  * GandiV5::Error
    #  * JSON::ParserError
    def patch(url, payload = '', **headers)
      prepare_headers headers, url
      headers[:'content-type'] ||= 'application/json'
      response = RestClient.patch url, payload, **headers
      [response, parse_response(response)]
    rescue RestClient::BadRequest => e
      handle_bad_request(e)
    end

    # Might raise:
    #  * RestClient::NotFound
    #  * RestClient::Unauthorized
    #      Bad authentication attempt because of a wrong API Key.
    #  * RestClient::Forbidden
    #      Access to the resource is denied.
    #      Mainly due to a lack of permissions to access it.
    #  * RestClient::BadRequest
    #  * RestClient::Conflict
    #  * GandiV5::Error
    #  * JSON::ParserError
    def post(url, payload = '', **headers)
      prepare_headers headers, url
      headers[:'content-type'] ||= 'application/json'
      response = RestClient.post url, payload, **headers
      [response, parse_response(response)]
    rescue RestClient::BadRequest => e
      handle_bad_request(e)
    end

    # Might raise:
    #  * RestClient::NotFound
    #  * RestClient::Unauthorized
    #      Bad authentication attempt because of a wrong API Key.
    #  * RestClient::Forbidden
    #      Access to the resource is denied.
    #      Mainly due to a lack of permissions to access it.
    #  * RestClient::BadRequest
    #  * RestClient::Conflict
    #  * GandiV5::Error
    #  * JSON::ParserError
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

    def authorisation_header(url)
      if url.start_with?(BASE)
        { Authorization: "Apikey #{api_key}" }
      elsif url.start_with?(GandiV5::LiveDNS::BASE)
        { 'X-Api-Key': api_key }
      else
        fail ArgumentError, "Don't know how to authorise for url: #{url}"
      end
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

    def prepare_headers(headers, url)
      headers.transform_keys!(&:to_sym)
      headers[:accept] ||= 'application/json'
      headers.merge!(authorisation_header(url))
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
