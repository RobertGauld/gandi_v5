# frozen_string_literal: true

class GandiV5
  class Domain
    class Availability
      # Information about tax due on a process/product.
      # @!attribute [r] name
      #   @return [String] name of the tax (e.g. VAT)
      # @!attribute [r] rate
      #   @return [Numeric] percentage rate of the tax (e.g. 20)
      # @!attribute [r] type
      #   @return [String] type of the tax (e.g. service)
      class Tax
        include GandiV5::Data

        members :name, :rate, :type
      end
    end
  end
end
