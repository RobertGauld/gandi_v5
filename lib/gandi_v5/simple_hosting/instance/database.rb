# frozen_string_literal: true

class GandiV5
  class SimpleHosting
    class Instance
      # A simple hosting instance.
      # @!attribute [r] name
      #   @return [String]
      # @!attribute [r] status
      #   @return [String]
      # @!attribute [r] version
      #   @return [String]
      class Database
        include GandiV5::Data

        members :name, :status, :version
      end
    end
  end
end
