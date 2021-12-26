# frozen_string_literal: true

# Namespace for classes which access LiveDNS details.
class GandiV5
  class SimpleHosting
    class Instance
      # A virtual host on a simple hosting instance.
      # @see https://api.gandi.net/docs/simplehosting/
      # @!attribute [r] created_at
      #   @return [Time]
      # @!attribute [r] fqdn
      #   @return [String] fully qualified domain name of the virtual host.
      # @!attribute [r] instance_uuid
      #   @return [String] UUID of the simple hosting instance which 'owns' the host.
      # @!attribute [r] is_a_test_virtual_host
      #   @return [Boolean]
      # @!attribute [r] status
      #   @return [Symbol] :being_created, :running, :being_deleted,
      #                    :locked, :waiting_ownership, :ownership_validated,
      #                    :validation_failed
      # @!attribute [r] https_strategy
      #   @return [Symbol] :http_only, :allow_http_and_https,
      #                    :redirect_http_to_https
      # @!attribute [r] Application
      #   @return [GandiV5::SimpleHosting::Instance::Application]
      # @!attribute [r] certificates
      #   @return [Hash<String => Boolean>] Hash - certificate ID to pendingness
      # @!attribute [r] linked_dns_zone
      #   @return [GandiV5::SimpleHosting::Instance::VirtualHost::LinkedDnsZone]
      class VirtualHost
        include GandiV5::Data

        members :created_at, :fqdn, :instance_uuid

        member :is_a_test_virtual_host, gandi_key: 'is_a_test_vhost'
        member :status, converter: GandiV5::Data::Converter::Symbol

        member(
          :https_strategy,
          converter: GandiV5::Data::Converter.new(from_gandi: ->(data) { data.downcase.to_sym })
        )

        member(
          :application,
          converter: GandiV5::SimpleHosting::Instance::Application
        )

        member(
          :certificates,
          converter: GandiV5::Data::Converter.new(
            from_gandi: ->(array) { array.to_h { |h| [h['id'], h['pending']] } }
          )
        )

        member(
          :linked_dns_zone,
          converter: GandiV5::SimpleHosting::Instance::VirtualHost::LinkedDnsZone
        )

        # Requery Gandi fo this virtual hosts's information.
        # @return [GandiV5::SimpleHosting::Instance::VirtualHost]
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def refresh
          _response, data = GandiV5.get url
          from_gandi data
        end

        # Delete the virtual host.
        # @see https://api.gandi.net/docs/simplehosting/#delete-v5-simplehosting-instances-instance_id-vhosts-vhost_fqdn
        # @return [String] The confirmation message from Gandi.
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def delete
          _response, data = GandiV5.delete url
          data['message']
        end

        # Update the virtual host.
        # @see https://api.gandi.net/docs/simplehosting/#patch-v5-simplehosting-instances-instance_id-vhosts-vhost_fqdn
        # @param application [GandiV5::SimpleHosting::Instance::Application, Hash]
        # @param https_strategy [:http_only, :allow_http_and_https, :redirect_http_to_https]
        # @param linked_dns_zone_allow_alteration [Boolean]
        #   authorize Gandi to modify your DNS zone so that your vhost points to their
        #   Simple Hosting public endpoints.
        # @param linked_dns_zone_allow_alteration_override [Boolean]
        #   authorize Gandi to override your DNS zone if there already is a record to
        #   link your instance to your vhost fqdn.
        # @return [GandiV5::SimpleHosting::Instance::VirtualHost] self.
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        # rubocop:disable Metrics/MethodLength
        def update(
          application: nil,
          https_strategy: nil,
          linked_dns_zone_allow_alteration: nil,
          linked_dns_zone_allow_alteration_override: false
        )
          https_strategy = case https_strategy
                           when nil then nil
                           when :http_only then 'HTTP_only'
                           when :allow_http_and_https then 'allow_HTTP_and_HTTPS'
                           when :redirect_http_to_https then 'redirect_HTTP_to_HTTPS'
                           else
                             fail ArgumentError,
                                  "https_strategy #{https_strategy.inspect} is invalid"
                           end

          body = {}
          body[:application] = application.to_h.slice(:name, :parameters) if application
          body[:https_strategy] = https_strategy if https_strategy
          unless linked_dns_zone_allow_alteration.nil?
            body[:linked_dns_zone] = {
              allow_alteration: linked_dns_zone_allow_alteration,
              allow_alteration_override: linked_dns_zone_allow_alteration_override
            }
          end

          _response, data = GandiV5.put url, body.to_json
          from_gandi data
        end
        # rubocop:enable Metrics/MethodLength

        # Check if the virtual host is being created
        # @return [Boolean]
        def being_created?
          status == :being_created
        end

        # Check if the virtual host is running
        # @return [Boolean]
        def running?
          status == :running
        end

        # Check if the virtual host is being deleted
        # @return [Boolean]
        def being_deleted?
          status == :being_deleted
        end

        # Check if the virtual host is locked
        # @return [Boolean]
        def locked?
          status == :locked
        end

        # Check if the virtual host is waiting for an ownership check
        # @return [Boolean]
        def waiting_ownership?
          status == :waiting_ownership
        end

        # Check if the virtual host has it's ownership validated
        # @return [Boolean]
        def ownership_validated?
          status == :ownership_validated
        end

        # Check if the virtual host failed it's ownership check
        # @return [Boolean]
        def validation_failed?
          status == :validation_failed
        end

        # Check if the virtual host is serving HTTP only
        # @return [Boolean]
        def http_only?
          https_strategy == :http_only
        end

        # Check if the virtual host is serving HTTP and HTTPS
        # @return [Boolean]
        def http_and_https?
          https_strategy == :http_and_https
        end

        # Check if the virtual host is serving HTTPS and redirecting HTTP to HTTPS
        # @return [Boolean]
        def redirect_http_to_https?
          https_strategy == :redirect_http_to_https
        end

        # Check if the virtual host is serving HTTP requests
        # @return [Boolean]
        def http?
          https_strategy == :http_only || https_strategy == :http_and_https
        end

        # Check if the virtual host is serving HTTPS requests
        # @return [Boolean]
        def https?
          https_strategy == :http_and_https
        end

        # Get information on a virtual host.
        # @see https://api.gandi.net/docs/simplehosting#get-v5-simplehosting-instances-instance_id-vhosts-vhost_fqdn
        # @param instance_uuid [String, #to_s] the UUID of the simple hosting instance.
        # @param fqdn [String, #to_s] the fully qualified domain name of the virtual host.
        # @return [GandiV5::SimpleHosting::Instance]
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def self.fetch(instance_uuid, fqdn)
          _response, data = GandiV5.get url(instance_uuid, fqdn)
          from_gandi data.merge('instance_uuid' => instance_uuid)
        end

        # Create a new virtual host for an instance
        # @see https://api.gandi.net/docs/simplehosting/#post-v5-simplehosting-instances-instance_id-vhosts
        # @param fqdn [String, #to_s] the fully qualified domain of the virtual host to create.
        # @param application [GandiV5::SimpleHosting::Instance::Application, Hash]
        # @param linked_dns_zone_allow_alteration [Boolean]
        #   authorize Gandi to modify your DNS zone so that your vhost points to their
        #   Simple Hosting public endpoints.
        # @param linked_dns_zone_allow_alteration_override [Boolean]
        #   authorize Gandi to override your DNS zone if there already is a record to
        #   link your instance to your vhost fqdn.
        # @return [GandiV5::SimpleHosting::Instance::VirtualHost]
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def self.create(
          instance_uuid,
          fqdn,
          application: nil,
          linked_dns_zone_allow_alteration: nil,
          linked_dns_zone_allow_alteration_override: false
        )
          body = { fqdn: fqdn }
          body[:application] = application.to_h.slice(:name, :parameters) if application
          unless linked_dns_zone_allow_alteration.nil?
            body[:linked_dns_zone] = {
              allow_alteration: linked_dns_zone_allow_alteration,
              allow_alteration_override: linked_dns_zone_allow_alteration_override
            }
          end

          _response, _data = GandiV5.post url(instance_uuid), body.to_json
          fetch instance_uuid, fqdn
        end

        # List virtual hosts for an instance.
        # @see https://api.gandi.net/docs/simplehosting#get-v5-simplehosting-instances-instance_id-vhosts
        # @param page [#each<Integer, #to_s>] the page(s) of results to retrieve.
        #   If page is not provided keep querying until an empty list is returned.
        #   If page responds to .each then iterate until an empty list is returned.
        # @param per_page [Integer, #to_s] (optional default 100) how many results to get per page.
        # @param status [String, #to_s] (optional)
        #   filter the list by the virtual host's status.
        # @param fqdn [String, #to_s] (optional)
        #   filter the list by the virtual host's domain name, allows * as wildcard.
        # @param sort_by [String, #to_s] (optional default "created_at")
        #   how to sort the list, prefix with a minus to reverse sort order.
        # @return [Array<GandiV5::SimpleHosting::Instance::VirtualHost>]
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def self.list(instance_uuid, page: (1..), per_page: 100, **params)
          instances = []
          GandiV5.paginated_get(url(instance_uuid), page, per_page, params: params) do |data|
            instances += data.map { |item| from_gandi item.merge('instance_uuid' => instance_uuid) }
          end
          instances
        end

        private

        def url
          "#{BASE}simplehosting/instances/#{instance_uuid}/vhosts/#{CGI.escape(fqdn)}"
        end

        def self.url(instance_uuid, fqdn = nil)
          "#{BASE}simplehosting/instances/#{instance_uuid}/vhosts" +
            (fqdn ? "/#{CGI.escape fqdn}" : '')
        end
        private_class_method :url
      end
    end
  end
end
