# frozen_string_literal: true

require_relative 'product/price'
require_relative 'product/period'

class GandiV5
  class Domain
    class Availability
      # Information about an available product.
      # @!attribute [r] name
      #   @return [String]
      # @!attribute [r] prices
      #   @return [Array<GandiV5::Domain::Availability::Product::Price>]
      # @!attribute [r] periods
      #   @return [Array<GandiV5::Domain::Availability::Product::Period>]
      # @!attribute [r] taxes
      #   @return [Array<GandiV5::Domain::Availability::Tax>]
      # @!attribute [r] process
      #   @return [Symbol]
      # @!attribute [r] status
      #   @return [Symbol]
      class Product
        include GandiV5::Data

        STATUSES = {
          available: 'Domain name is available',
          available_reserved: 'Domain name reserved under special conditions',
          available_preorder: 'Domain name can be pre-ordered',
          unavailable: 'Domain name is not available',
          unavailable_premium: 'Domain name is not available',
          unavailable_restricted: 'Domain name is not available (forbidden)',
          error_invalid: 'Provided value is not a valid domain name',
          error_refused: 'Service is temporarily down',
          error_timeout: 'Service timed out, try the method again later',
          error_unknown: 'Internal server error',
          reserved_corporate: 'The TLD for the given domain name is reserved for ' \
                              'Gandi Corporate Services customers',
          pending: 'Result is not yet ready, try the method again later',
          error_eoi: 'The TLD for the given domain name is in an ' \
                     'Expression of Interest (EOI) period'
        }.freeze

        members :name
        member :prices, converter: GandiV5::Domain::Availability::Product::Price, array: true
        member :periods, converter: GandiV5::Domain::Availability::Product::Period, array: true
        member :process, converter: GandiV5::Data::Converter::Symbol
        member :status, converter: GandiV5::Data::Converter::Symbol
        member :taxes, converter: GandiV5::Domain::Availability::Tax, array: true
      end
    end
  end
end
