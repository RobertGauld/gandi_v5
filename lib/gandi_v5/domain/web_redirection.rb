# frozen_string_literal: true

class GandiV5
  class Domain
    # Manage web redirections.
    # @!attribute [r] created_at
    #   @return [Time, nil]
    # @!attribute [r] updated_at
    #   @return [Time, nil]
    # @!attribute [r] type
    #   @return [:cloak, :http301, :http302]
    # @!attribute [r] fqdn
    #   @return [String]
    # @!attribute [r] protocol
    #   @return [:http, :https, :https_only, nil]
    # @!attribute [r] target
    #   @return [String]
    # @!attribute [r] cert_status
    #   @return [String, nil]
    # @!attribute [r] cert_uuid
    #   @return [String, nil]
    class WebRedirection
      include GandiV5::Data

      members :cert_uuid, :cert_status
      member :target, gandi_key: 'url'
      member :fqdn, gandi_key: 'host'
      member :type, converter: GandiV5::Data::Converter::Symbol
      member :created_at, converter: GandiV5::Data::Converter::Time
      member :updated_at, converter: GandiV5::Data::Converter::Time
      member(
        :protocol,
        converter: GandiV5::Data::Converter.new(
          from_gandi: lambda { |value|
            {
              'http' => :http,
              'https' => :https,
              'httpsonly' => :https_only
            }.fetch(value)
          }
        )
      )

      # Update the redirection in Gandi.
      # @see https://api.gandi.net/docs/domains/#patch-v5-domain-domains-domain-webredirs-host
      # @param target [String, #to_s] the url to redirect to (e.g. www.example.com/path).
      # @param protocol [:http, :https, :https_only]
      # @param type [:cloak, :http301, :http302]
      # @param override [Boolean] If true, a DNS record will be created.
      #   When the value is false and no matching DNS record exists, it will trigger an error.
      # @return [GandiV5::Domain::WebRedirection]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error
      def update(target: nil, protocol: nil, type: nil, override: nil)
        body = {}
        body['url'] = target.to_s unless target.nil?
        body['protocol'] = protocol.to_s.delete('_') unless protocol.nil?
        body['type'] = type.to_s unless type.nil?
        body['override'] = override unless override.nil?

        GandiV5.patch url, body.to_json
        refresh
      end

      # Delete this web redirection from Gandi.
      # @see https://api.gandi.net/docs/domains/#delete-v5-domain-domains-domain-webredirs-host
      # @return [String] The confirmation message from Gandi.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def delete
        _response, data = GandiV5.delete url
        data['message']
      end

      # Check if this is an HTTP 301 (permanent) redirection.
      def http301?
        type == :http301
      end

      # Check if this is an HTTP 302 (found) redirection.
      def http302?
        type == :http302
      end

      # Check if this is an HTTP 301 (permanent) redirection.
      def permanent?
        type == :http301
      end

      # Check if this is an HTTP 302 (found) redirection.
      def found?
        type == :http302
      end

      # Check if this is a temporary redirection.
      def temporary?
        type == :http302
      end

      # Create a new web redirection.
      # @see https://api.gandi.net/docs/domains/#post-v5-domain-domains-domain-webredirs
      # @param domain [String, #to_s] the domain name to create the redirection in.
      # @param host [String, #to_s] the host name to redirect from.
      # @param target [String, #to_s] the url to redirect to (e.g. www.example.com/path).
      # @param protocol [:http, :https, :https_only]
      # @param type [:cloak, :http301, :http302]
      # @param override [Boolean] When you create a redirection on a domain, a DNS record is created
      #   if it does not exist. When the record already exists and this parameter is set to true it
      #   will overwrite the record. Otherwise it will trigger an error.
      # @return [GandiV5::Domain::WebRedirection] the created redirection
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error
      def self.create(domain:, host:, target:, protocol:, type:, override: false)
        body = {
          'host' => host.to_s,
          'protocol' => protocol.to_s.delete('_'),
          'type' => type.to_s,
          'url' => target.to_s,
          'override' => override
        }.to_json

        GandiV5.post url(domain), body
        fetch domain, host
      end

      # Get web redirect for a host in a domain.
      # @see https://api.gandi.net/docs/domains/#get-v5-domain-domains-domain-webredirs-host
      # @param domain [String, #to_s] the domain to get the web redirection for.
      # @param host [String, #to_s] the host name to get the web redirection for.
      # @return [GandiV5::Domain::WebRedirect]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.fetch(domain, host)
        _response, data = GandiV5.get url(domain, host)
        redirect = from_gandi data
        redirect.instance_exec { @domain = domain }
        redirect
      end

      # List web redirects for a domain.
      # @see https://api.gandi.net/docs/domains/#get-v5-domain-domains-domain-webredirs-host
      # @param domain [String, #to_s] the domain to get the web redirections for.
      # @param page [#each<Integer, #to_s>] the page(s) of results to retrieve.
      #   If page is not provided keep querying until an empty list is returned.
      #   If page responds to .each then iterate until an empty list is returned.
      # @param per_page [Integer, #to_s] (optional default 100) how many results to get per page.
      # @return [Array<GandiV5::Domain::WebRedirect>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.list(domain, page: (1..), per_page: 100)
        redirects = []
        GandiV5.paginated_get(url(domain), page, per_page) do |data|
          redirects += data.map { |redirect| from_gandi redirect }
        end
        redirects.each { |redirect| redirect.instance_exec { @domain = domain } }
        redirects
      end

      private

      def url
        host = fqdn[0..-(@domain.length + 2)]
        "#{BASE}domain/domains/#{CGI.escape @domain}/webredirs/#{CGI.escape host}"
      end

      def self.url(domain, host = nil)
        "#{BASE}domain/domains/#{CGI.escape domain}/webredirs" +
          (host ? "/#{CGI.escape host}" : '')
      end
      private_class_method :url
    end
  end
end
