# frozen_string_literal: true

class GandiV5
  class Billing
    class Info
      # Account's prepaid information.
      # @!attribute [r] amount
      #   @return [Numeric] current amount available in the prepaid account.
      # @!attribute [r] currency
      #   @return [String] currency in use for the prepaid account.
      # @!attribute [r] warning_threshold
      #   @return [Numeric] amount under which a warning email is sent.
      # @!attribute [r] created_at
      #   @return [Time] creation date of the prepaid account.
      # @!attribute [r] updated_at
      #   @return [Time] last modification date of the prepaid account.
      class Prepaid
        include GandiV5::Data

        members :amount, :currency, :warning_threshold
        member :created_at, converter: GandiV5::Data::Converter::Time
        member :updated_at, converter: GandiV5::Data::Converter::Time

        # Check if current balance is below the warning threshold.
        def warning?
          return nil if warning_threshold.nil?

          amount < warning_threshold
        end
      end
    end
  end
end
