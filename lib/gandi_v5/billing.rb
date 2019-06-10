# frozen_string_literal: true

require_relative 'billing/info'

class GandiV5
  # Gandi Billing API.
  # @see https://api.gandi.net/docs/billing
  class Billing
    # Get account info (defaults to currently authenticated user).
    # @see https://api.gandi.net/docs/billing#get-v5-billing-info
    # @param url [sharing_id] the Sharing ID of the organisation to get info for
    #   defaults to the user the api key belomgs to.
    # @return [GandiV5::Billing::Info]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def self.info(sharing_id = nil)
      _response, data = GandiV5.get url(sharing_id)
      GandiV5::Billing::Info.from_gandi data
    end

    private

    def self.url(sharing_id = nil)
      "#{BASE}billing/info" +
        (sharing_id ? "/#{CGI.escape sharing_id}" : '')
    end
    private_class_method :url
  end
end
