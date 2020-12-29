# frozen_string_literal: true

class GandiV5
  class Email
    # A forwarding address that lives within a domain.
    # @see https://docs.gandi.net/en/gandimail/forwarding_and_aliases/
    # @!attribute [r] source
    #   @return [String] the source email address ("alice" rather than "alice@example.com").
    # @!attribute [r] destinations
    #   @return [Array<String>] list of destination email addresses.
    # @!attribute [r] fqdn
    #   @return [String] domain name.
    class Forward
      include GandiV5::Data

      members :source, :fqdn
      member :destinations, array: true

      # Delete the forwarding.
      # @see https://api.gandi.net/docs/email/#delete-v5-email-forwards-domain-source
      # @return [String] The confirmation message from Gandi.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def delete
        _response, data = GandiV5.delete url
        data['message']
      end

      # Update the forwarding.
      # @see https://api.gandi.net/docs/email/#put-v5-email-forwards-domain-source
      # @param destinations [Array<String, #to_s>] new list of destination email addresses.
      # @return [String] The confirmation message from Gandi.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def update(*destinations)
        fail ArgumentError, 'destinations can\'t be empty' if destinations.none?

        _response, data = GandiV5.put url, { destinations: destinations }.to_json
        @destinations = destinations.map(&:to_s)
        data['message']
      end

      # Returns the string representation of the forwarding.
      # @return [String]
      def to_s
        "#{source}@#{fqdn} -> #{destinations.join(', ')}"
      end

      # Create a new forward.
      # @see https://api.gandi.net/docs/email/#post-v5-email-forwards-domain
      # @param fqdn [String, #to_s] the fully qualified domain name for the forward.
      # @param source [String, #to_s]
      #   the source email address ("alice" rather than "alice@example.com").
      # @param destinations [Array<String, #to_s>] list of destination email addresses.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.create(fqdn, source, *destinations)
        fail ArgumentError, 'destinations can\'t be empty' if destinations.none?

        body = {
          source: source,
          destinations: destinations
        }.to_json
        _response, _data = GandiV5.post url(fqdn), body

        new fqdn: fqdn, source: source, destinations: destinations
      end

      # List forwards for a domain.
      # @see https://api.gandi.net/docs/email/#get-v5-email-forwards-domain
      # @param fqdn [String, #to_s] the fully qualified domain name for the forwards.
      # @param page [Integer, #each<Integer>] which page(s) of results to get.
      #   If page is not provided keep querying until an empty list is returned.
      #   If page responds to .each then iterate until an empty list is returned.
      # @param per_page [Integer, #to_s] (optional default 100) how many results ot get per page.
      # @param sort_by [#to_s] (optional default "login")
      #   how to sort the results ("login", "-login").
      # @param source [String] (optional) filter the source (pattern)
      #   e.g. ("alice" "*lice", "alic*").
      # @return [Array<GandiV5::Email::Forward>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.list(fqdn, page: (1..), per_page: 100, **params)
        params.compact! { |_k, v| v.nil? }

        mailboxes = []
        GandiV5.paginated_get(url(fqdn), page, per_page, params: params) do |data|
          mailboxes += data.map { |mailbox| from_gandi mailbox.merge(fqdn: fqdn) }
        end
        mailboxes
      end

      private

      def url
        "#{BASE}email/forwards/#{CGI.escape fqdn}/#{CGI.escape source}"
      end

      def self.url(fqdn, source = nil)
        "#{BASE}email/forwards/#{CGI.escape fqdn}" +
          (source ? "/#{CGI.escape source}" : '')
      end
      private_class_method :url
    end
  end
end
