# frozen_string_literal: true

class GandiV5
  class Domain
    class Availability
      class Product
        # Information about an available product.
        # @!attribute [r] duration_unit
        #   @return [String] time unit for the duration (e.g. y)
        # @!attribute [r] max_duration
        #   @return [Integer] maximum duration for which this price unit applies
        # @!attribute [r] min_duration
        #   @return [Integer] minimum duration for which this price unit applies.
        # @!attribute [r] price_after_taxes
        #   @return [Numeric] pricing after tax is applied
        # @!attribute [r] price_before_taxes
        #   @return [Numeric] pricing before tax is applied
        # @!attribute [r] discount
        #   @return [Boolean, nil] whether a discount is active on this price unit
        # @!attribute [r] normal_price_after_taxes
        #   @return [Numeric, nil] pricing after tax is applied, when no discount applies
        # @!attribute [r] normal_price_before_taxes
        #   @return [Numeric, nil] pricing before tax is applied, when no discount applies
        # @!attribute [r] type
        #   @return [String, nil]
        class Price
          include GandiV5::Data

          members :duration_unit, :max_duration, :min_duration,
                  :price_after_taxes, :price_before_taxes,
                  :discount, :normal_price_after_taxes, :normal_price_after_taxes, :type
        end
      end
    end
  end
end
