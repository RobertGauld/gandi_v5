# frozen_string_literal: true

class GandiV5
  class Domain
    # Manage a domain's transfer to Gandi.
    # @!attribute [r] fqdn
    #   @return [String] the fully qualified domain name being transfered
    # @!attribute [r] created_at
    #   @return [Time]
    # @!attribute [r] updated_at
    #   @return [Time]
    # @!attribute [r] owner_contact
    #   @return [String]
    # @!attribute [r] step
    #   @return [String]
    # @!attribute [r] step_number
    #   @return [Integer]
    # @!attribute [r] errortype
    #   @return [String] (optional)
    # @!attribute [r] errortype_label
    #   @return [String] (optional)
    # @!attribute [r] duration
    #   @return [Integer] (optional)
    # @!attribute [r] reseller_uuid
    #   @return [String] (optional)
    # @!attribute [r] version
    #   @return [Integer] (optional)
    # @!attribute [r] foa
    #   @return [Hash{String=>String}] (optional) email => status
    # @!attribute [r] inner_step
    #   @return [String] (optional)
    # @!attribute [r] transfer_procedure
    #   @return [String] (optional)
    # @!attribute [r] start_at
    #   @return [Time] (optional)
    # @!attribute [r] regac_at
    #   @return [Time] (optional)
    class TransferIn
      include GandiV5::Data

      members :fqdn, :owner_contact, :step, :errortype, :errortype_label, :inner_step,
              :transfer_procedure, :reseller_uuid, :version, :foa_status, :duration

      member :step_number, gandi_key: 'step_nb'
      member :created_at, converter: GandiV5::Data::Converter::Time
      member :updated_at, converter: GandiV5::Data::Converter::Time
      member :regac_at, converter: GandiV5::Data::Converter::Time
      member :start_at, converter: GandiV5::Data::Converter::Time

      # Relaunch the transfer process after something went wrong.
      # @see https://api.gandi.net/docs/domains/#put-v5-domain-transferin-domain
      # @return [String] the confirmation message from Gandi
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def relaunch
        TransferIn.relaunch fqdn
      end

      # Resend the {https://icannwiki.org/FOA Form Of Authorization} email.
      # @see https://api.gandi.net/docs/domains/#post-v5-domain-transferin-domain-foa
      # @return [String] the confirmation message from Gandi
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def resend_foa_emails(email_address)
        TransferIn.resend_foa_emails fqdn, email_address
      end

      # Start the transfer of a domain to Gandi.
      # @note This is not a free operation. Please ensure your prepaid account has enough credit.
      # @see https://api.gandi.net/docs/domains/#post-v5-domain-transferin
      # @param fqdn [String, #to_s] the fully qualified domain name to create.
      # @param dry_run [Boolean]
      #   whether the details should be checked instead of actually creating the domain.
      # @param sharing_id [String] either:
      #   * nil (default) - nothing special happens
      #   * an organization ID - pay using another organization
      #     (you need to have billing permissions on the organization
      #     and use the same organization name for the domain name's owner).
      #     The invoice will be edited using this organization's information.
      #   * a reseller ID - buy a domain for a customer using a reseller account
      #     (you need to have billing permissions on the reseller organization
      #     and have your customer's information for the owner).
      #     The invoice will be edited using the reseller organization's information.
      # @param owner [GandiV5::Domain::Contact, #to_gandi, #to_h] (required)
      #   the owner of the new domain.
      # @param admin [GandiV5::Domain::Contact, #to_gandi, #to_h] (optional, defaults to owner)
      #   the administrative contact for the new domain.
      # @param bill [GandiV5::Domain::Contact, #to_gandi, #to_h] (optional, defaults to owner)
      #   the billing contact for the new domain.
      # @param tech [GandiV5::Domain::Contact, #to_gandi, #to_h] (optional, defaults to owner)
      #   the technical contact for the new domain.
      # @param currency ["EUR", "USD", "GBP", "TWD", "CNY"] (optional)
      #   the currency you wish to be charged in.
      # @param duration [Integer] (optional, default 1, minimum 1 maximum 10)
      #   how many years to register for.
      # @param enforce_premium [Boolean] (optional)
      #   must be set to true if the domain is a premium domain.
      # @param extra_parameters [Hash, #to_gandi, #to_json] (optional)
      #   unknown - not documented at Gandi.
      # @param nameserver_ips [Hash<String => Array<String>>, #to_gandi, #to_json] (optional)
      #   For glue records only - dictionnary associating a nameserver to a list of IP addresses.
      # @param nameservers [Array<String>, #to_gandi, #to_json] (optional)
      #   List of nameservers. Gandi's LiveDNS nameservers are used if omitted..
      # @param price [Numeric, #to_gandi, #to_json] (optional) unknown - not documented at Gandi.
      # @param resellee_id [String, #to_gandi, #to_json] (optional)
      #   unknown - not documented at Gandi.
      # @param change_owner [Boolean] (optional)
      #   whether the change the domain's owner during the transfer.
      # @param auth_code [String] (optional) authorization code (if required).
      # @return [String] the confirmation message from Gandi
      # @return [Hash] if doing a dry run, you get what Gandi returns
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error
      def self.create(fqdn, dry_run: false, sharing_id: nil, **params)
        fail ArgumentError, 'missing keyword: owner' unless params.key?(:owner)

        body = params.merge(fqdn: fqdn)
                     .transform_values { |val| val.respond_to?(:to_gandi) ? val.to_gandi : val }
                     .to_json
        url_ = sharing_id ? "#{url}?sharing_id=#{sharing_id}" : url

        _response, data = GandiV5.post(url_, body, 'Dry-Run': dry_run ? 1 : 0)
        dry_run ? data : data['message']
      end

      # Get information on an existing transfer.
      # @see https://api.gandi.net/docs/domains/#get-v5-domain-transferin-domain
      # @param fqdn [String, #to_s] the fully qualified domain name to check.
      # @return [GandiV5::Domain::TransferIn]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.fetch(fqdn)
        _response, data = GandiV5.get url(fqdn)
        transfer = from_gandi data
        transfer.instance_exec { @fqdn = data.dig('params', 'domain') }
        transfer.instance_exec { @reseller_uuid = data.dig('params', 'reseller') }
        transfer.instance_exec { @version = data.dig('params', 'version') }
        transfer.instance_exec { @duration = data.dig('params', 'duration') }
        if data.key?('foa')
          transfer.instance_exec do
            @foa_status = Hash[data['foa'].map { |hash| hash.values_at('email', 'answer') }]
          end
        end
        transfer
      end

      # Relaunch the transfer process after something went wrong.
      # @see https://api.gandi.net/docs/domains/#put-v5-domain-transferin-domain
      # @return [String] the confirmation message from Gandi
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.relaunch(fqdn)
        _response, data = GandiV5.put url(fqdn)
        data['message']
      end

      # Resend the {https://icannwiki.org/FOA Form Of Authorization} email.
      # @see https://api.gandi.net/docs/domains/#post-v5-domain-transferin-domain-foa
      # @return [String] the confirmation message from Gandi
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.resend_foa_emails(fqdn, email_address)
        _response, data = GandiV5.post "#{url(fqdn)}/foa", { 'email' => email_address }.to_json
        data['message']
      end

      private

      def self.url(fqdn = nil)
        "#{BASE}domain/transferin" +
          (fqdn ? "/#{CGI.escape fqdn}" : '')
      end
      private_class_method :url
    end
  end
end
