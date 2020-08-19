# frozen_string_literal: true

class GandiV5
  class SimpleHosting
    class Instance
      # An available upgrade on a simple hosting instance.
      # @!attribute [r] name
      #   @return [String]
      # @!attribute [r] status
      #   @return [String]
      # @!attribute [r] type
      #   @return [String] "database" or "language"
      # @!attribute [r] version
      #   @return [String]
      class Upgrade
        include GandiV5::Data

        members :name, :status, :type, :version
      end
    end
  end
end
