# frozen_string_literal: true

# Namespace for classes which access LiveDNS details.
class GandiV5
  # Gandi Simple Hosting management API.
  class SimpleHosting
    # @see GandiV5::Simplehosting::Instance.list
    def self.instances
      GandiV5::SimpleHosting::Instance.list
    end
  end
end
