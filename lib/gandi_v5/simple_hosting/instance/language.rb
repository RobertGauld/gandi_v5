# frozen_string_literal: true

class GandiV5
  class SimpleHosting
    class Instance
      # A language running on a simple hosting instance.
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
