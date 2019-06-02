# frozen_string_literal: true

require_relative 'info/prepaid'

class GandiV5
  class Billing
    # Account's information.
    # @!attribute [r] annual_balance
    #   @return [Numeric] amount of purchased over the past 12 months since the request.
    # @!attribute [r] outstanding_amount
    #   @return [Numeric] amount of outstanding orders (payment by terms) since the last invoice.
    # @!attribute [r] grid
    #   @return [String] price rate that is applied
    #      depending on the amount purchased over the last 12 months.
    # @!attribute [r] prepaid_monthly_invoice
    #   @return [nil, Boolean] whether orders are gathered into a single monthly invoice.
    # @!attribute [r] prepaid
    #   @return [nil, Gandiv5::Billing::Info::Prepaid]
    class Info
      include GandiV5::Data

      members :annual_balance, :grid, :outstanding_amount, :prepaid_monthly_invoice
      member :prepaid, converter: GandiV5::Billing::Info::Prepaid
    end
  end
end
