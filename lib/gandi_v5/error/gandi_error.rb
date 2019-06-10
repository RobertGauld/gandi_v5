# frozen_string_literal: true

class GandiV5
  class Error < RuntimeError
    # Generic error class for errors returned by Gandi.
    class GandiError < GandiV5::Error
      # Generate a new GandiV5::Error::GandiError from the hash returned by Gandi.
      # @param hash [Hash] the hash returned by Gandi.
      # @return [GandiV5::Error::GandiError]
      def self.from_hash(hash)
        hash['errors'] ||= []

        new(
          (hash['errors'].count > 1 ? "\n" : '') +
            hash['errors'].map { |err| "#{err['location']}->#{err['name']}: #{err['description']}" }
                               .join("\n")
        )
      end
    end
  end
end
