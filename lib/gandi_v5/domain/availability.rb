# frozen_string_literal: true

require_relative 'availability/tax'
require_relative 'availability/product'

class GandiV5
  class Domain
    # Information about the availabillity of processes on a domain.
    # @!attribute [r] currency
    #   @return [String]
    # @!attribute [r] grid
    #   @return [String]
    # @!attribute [r] products
    #   @return [Arrav<GandiV5::Domain::Availability::Product>]
    # @!attribute [r] taxes
    #   @return [Array<GandiV5::Domain::Availability::Tax>]
    class Availability
      include GandiV5::Data

      members :currency, :grid
      member :products, converter: GandiV5::Domain::Availability::Product, array: true
      member :taxes, converter: GandiV5::Domain::Availability::Tax, array: true

      # Check domain availability and pricing.
      # @see https://api.gandi.net/docs/domains#get-v5-domain-check
      # @param fqdn [String, #to_s] the fully qualified domain name to check.
      # @param country [String, #to_s] (optional)
      #   ISO country code for which taxes are to be applied.
      # @param currency [String, #to_s] (optional) request price for a specific ISO currency code.
      # @param duration_unit [String, #to_s] (optional) define the unit for max_duration.
      # @param extension [String, #to_s] (optional) query a specific extension for product options.
      # @param grid [String, #to_s] (optional) request price for a specific rate.
      # @param lang [String, #to_s] (optional) language code.
      # @param max_duration [Integer, #to_s] (optional)
      #   set a limit on the duration range for returned prices.
      # @param period [String, #to_s] (optional) specific registration period to query.
      # @param processes [Array<:create, :renew, :transfer etc.>] (optional default [:create])
      #   list of at least 1 process for which pricing is to be made.
      # @param sharing_id [String, #to_s] (optional)
      #   organization for which the pricing is to be made.
      # @return [GandiV5::Domain::Availability]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.fetch(fqdn, **options)
        _response, data = GandiV5.get("#{BASE}domain/check", params: { name: fqdn }.merge(options))
        GandiV5::Domain::Availability.from_gandi data
      end
    end
  end
end
