# frozen_string_literal: true

class GandiV5
  class Email
    # The current status of your mailbox offer.
    # @!attribute [r] status
    #   @return [:active, :inactive]
    # @!attribute [r] version
    #   @return [1, 2]
    class Offer
      include GandiV5::Data

      member :version
      member :status, converter: GandiV5::Data::Converter::Symbol

      # Get the current status of your mailbox offer.
      # @see https://api.gandi.net/docs/email#get-v5-email-offers-domain
      # @param fqdn [String, #to_s] the fully qualified domain name to get the offer for.
      # @return [GandiV5::Email::Offer]
      # @raise [GandiV5::Error::GandiError::GandiError] if Gandi returns an error.
      def self.fetch(fqdn)
        _response, data = GandiV5.get "#{BASE}email/offers/#{CGI.escape fqdn}"
        from_gandi data
      end
    end
  end
end
