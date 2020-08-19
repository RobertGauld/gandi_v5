# frozen_string_literal: true

# Namespace for classes which access LiveDNS details.
class GandiV5
  class SimpleHosting
    # A simple hosting instance.
    # @see https://api.gandi.net/docs/simplehosting/
    # @!attribute [r] uuid
    #   @return [String]
    # @!attribute [r] name
    #   @return [String]
    # @!attribute [r] size
    #   @return [String] one of: s, s+, m, l, xl, xxl
    # @!attribute [r] password_updated_at
    #   @return [Time]
    # @!attribute [r] created_at
    #   @return [Time]
    # @!attribute [r] expire_at
    #   @return [Time]
    # @!attribute [r] status
    #   @return [Symbol] :waiting_bill, :being_created, :active
    #                    :paused, :locked, :being_deleted
    # @!attribute [r] snapshot_enabled
    #   @return [Boolean]
    # @!attribute [r] available_upgrade
    #   @return [Boolean]
    # @!attribute [r] is_trial
    #   @return [Boolean]
    # @!attribute [r] access_information
    #   @return [Hash] as returned by Gandi.
    # @!attribute [r] sharing_space
    #   @return [GandiV5::SharingSpace] who pays for this instance.
    # @!attribute [r] data_center
    #   @return [String] code of the data center hosting this instance.
    # @!attribute [r] storage
    #   @return [Hash<Symbol => "#{number} #{unit}">]
    #     storage split by :base, :additional and :total
    # @!attribute [r] auto_renew
    #   @return [string] "#{number} #{unit}".
    # @!attribute [r] virtual_hosts
    #   @return [Array<GandiV5::SimpleHosting::Instance::VirtualHost>]
    # @!attribute [r] database
    #   @return [GandiV5::SimpleHosting::Instance::Database]
    # @!attribute [r] language
    #   @return [GandiV5::SimpleHosting::Instance::Language]
    # @!attribute [r] compatible_applications
    #   @return [Array<GandiV5::SimpleHosting::Instance::Application>]
    # @!attribute [r] upgrade_to
    #   @return [Array<GandiV5::SimpleHosting::Instance::Upgrade>]
    class Instance
      include GandiV5::Data

      members :name, :size, :password_updated_at, :created_at, :expire_at, :status,
              :snapshot_enabled, :available_upgrade, :is_trial, :access_information

      member :uuid, gandi_key: 'id'

      member(
        :sharing_space,
        gandi_key: 'sharing_space',
        converter: GandiV5::SharingSpace
      )

      member(
        :data_center,
        gandi_key: 'datacenter',
        converter: GandiV5::Data::Converter.new(
          from_gandi: ->(hash) { hash['code'] }
        )
      )

      member(
        :storage,
        converter: GandiV5::Data::Converter.new(
          from_gandi: lambda do |hash|
            hash.transform_values { |value| "#{value['value']} #{value['unit']}" }
                .transform_keys(&:to_sym)
          end
        )
      )

      member(
        :auto_renew,
        gandi_key: 'autorenew',
        converter: GandiV5::Data::Converter.new(
          from_gandi: ->(hash) { "#{hash['duration']} #{hash['duration_type']}" }
        )
      )

      member(
        :virtual_hosts,
        gandi_key: 'vhosts',
        array: true,
        converter: GandiV5::SimpleHosting::Instance::VirtualHost
      )

      member(
        :database,
        converter: GandiV5::SimpleHosting::Instance::Database
      )

      member(
        :language,
        converter: GandiV5::SimpleHosting::Instance::Language
      )

      member(
        :compatible_applications,
        array: true,
        converter: GandiV5::SimpleHosting::Instance::Application
      )

      member(
        :upgrade_to,
        array: true,
        converter: GandiV5::SimpleHosting::Instance::Upgrade
      )

      # Instruct Gandi to restart this instance.
      # @see https://api.gandi.net/docs/simplehosting/#post-v5-simplehosting-instances-instance_id-action
      # @return [String] confirmation message.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def restart
        _response, data = GandiV5.post "#{url}/action", { 'action' => 'restart' }.to_json
        data
      end

      # Instruct Gandi to console this instance.
      # @see https://api.gandi.net/docs/simplehosting/#post-v5-simplehosting-instances-instance_id-action
      # @return [String] confirmation message.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def console
        _response, data = GandiV5.post "#{url}/action", { 'action' => 'console' }.to_json
        data
      end

      # Instruct Gandi to reset the database password for this instance.
      # @see https://api.gandi.net/docs/simplehosting/#post-v5-simplehosting-instances-instance_id-action
      # @return [String] confirmation message.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def reset_database_password
        _response, data = GandiV5.post(
          "#{url}/action",
          { 'action' => 'reset_database_password' }.to_json
        )
        data
      end

      # Requery Gandi fo this instance's information.
      # @return [GandiV5::SimpleHosting::Instance]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def refresh
        _response, data = GandiV5.get url
        from_gandi data
      end

      # Check if this instance is waiting for a bill
      # @return [Boolean]
      def waiting_bill?
        status == :waiting_bill
      end

      # Check if this instance is being created
      # @return [Boolean]
      def being_created?
        status == :being_created
      end

      # Check if this instance is active
      # @return [Boolean]
      def active?
        status == :active
      end

      # Check if this instance is paused
      # @return [Boolean]
      def paused?
        status == :paused
      end

      # Check if this instance is locked
      # @return [Boolean]
      def locked?
        status == :locked
      end

      # Check if this instance is being deleted
      # @return [Boolean]
      def being_deleted?
        status == :being_deleted
      end

      # Get information on an instance.
      # @see https://api.gandi.net/docs/simplehosting#get-v5-simplehosting-instances-instance_id
      # @param uuid [String, #to_s] the UUID of the instance.
      # @return [GandiV5::SimpleHosting::Instance]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.fetch(uuid)
        _response, data = GandiV5.get url(uuid)
        from_gandi data
      end

      # List instances.
      # @see https://api.gandi.net/docs/simplehosting#get-v5-simplehosting-instances
      # @param page [#each<Integer, #to_s>] the page(s) of results to retrieve.
      #   If page is not provided keep querying until an empty list is returned.
      #   If page responds to .each then iterate until an empty list is returned.
      # @param per_page [Integer, #to_s] (optional default 100) how many results to get per page.
      # @param sharing_id [String, #to_s] (optional)
      #   filter the list by who pays the bill.
      # @param size [String, #to_s] (optional)
      #   filter the list by instance size (s, s+, m, i, xl, xxl).
      # @param name [String, #to_s] (optional)
      #   filter the list by instance name, allows * as wildcard.
      # @param status [String, #to_s] (optional)
      #   filter the list by the instance's status.
      # @param fqdn [String, #to_s] (optional)
      #   filter the list by the virtual host's domain name, allows * as wildcard.
      # @param sort_by [String, #to_s] (optional default "created_at")
      #   how to sort the list, prefix with a minus to reverse sort order.
      # @return [Array<GandiV5::SimpleHosting::Instance>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.list(page: (1..), per_page: 100, **params)
        instances = []
        GandiV5.paginated_get(url, page, per_page, params: params) do |data|
          instances += data.map { |item| from_gandi item }
        end
        instances
      end

      private

      def url
        "#{BASE}simplehosting/instances/" +
          CGI.escape(uuid)
      end

      def self.url(uuid = nil)
        "#{BASE}simplehosting/instances" +
          (uuid ? "/#{CGI.escape uuid}" : '')
      end
      private_class_method :url
    end
  end
end
