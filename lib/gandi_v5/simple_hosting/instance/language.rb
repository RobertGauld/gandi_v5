# frozen_string_literal: true

class GandiV5
  class SimpleHosting
    class Instance
      # Sharing space which contains other billable items.
      # @!attribute [r] name
      #   @return [String]
      # @!attribute [r] single_application
      #   @return [Boolean]
      # @!attribute [r] status
      #   @return [String]
      # @!attribute [r] version
      #   @return [String]
      class Language
        include GandiV5::Data

        members :name, :single_application, :status, :version
      end
    end
  end
end
