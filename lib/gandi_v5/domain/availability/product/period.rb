# frozen_string_literal: true

class GandiV5
  class Domain
    class Availability
      class Product
        # Information about an available product.
        # @!attribute [r] name
        #   @return [String]
        # @!attribute [r]
        #   @return [Time] starts_at
        # @!attribute [r]
        #   @return [Time, nil] ends_at
        class Period
          include GandiV5::Data

          members :name
          member :starts_at, converter: GandiV5::Data::Converter::Time
          member :ends_at, converter: GandiV5::Data::Converter::Time
        end
      end
    end
  end
end
