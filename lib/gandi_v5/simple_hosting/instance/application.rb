# frozen_string_literal: true

class GandiV5
  class SimpleHosting
    class Instance
      # @!attribute [r] name
      #   @return [String]
      # @!attribute [r] parameters
      #   @return [String]
      # @!attribute [r] status
      #   @return [Symbol] :error, :running, :being_created, :cancelled
      class Application
        include GandiV5::Data

        members :name, :parameters
        member :status, converter: GandiV5::Data::Converter::Symbol

        # Check if the appliaction is currently being created
        # @return [Boolean]
        def being_created?
          status == :being_created
        end

        # Check if the appliaction has been cancelled
        # @return [Boolean]
        def cancelled?
          status == :cancelled
        end

        # Check if the appliaction is running
        # @return [Boolean]
        def running?
          status == :running
        end

        # Check if the appliaction is in an error condition
        # @return [Boolean]
        def error?
          status == :error
        end
      end
    end
  end
end
