# frozen_string_literal: true

class GandiV5
  # Manage configuration templates.
  # @!attribute [r] description
  #   @return [String] template purpose's description.
  # @!attribute [r] editable
  #   @return [Boolean]
  # @!attribute [r] uuid
  #   @return [String]
  # @!attribute [r] name
  #   @return [String]
  # @!attribute [r] orgname
  #   @return [String]
  # @!attribute [r] sharing_space
  #   @return [GandiV5::SharingSpace]
  # @!attribute [r] variables
  #   @return [Array<String>, nil]
  # @!attribute [r] payload
  #   @return [Array<GandiV5::Template::Payload] the settings which will be applied
  #                                              when this template is used.
  class Template
    include GandiV5::Data

    members :name, :description, :editable, :variables
    member :uuid, gandi_key: 'id'
    member :organisation_name, gandi_key: 'orgname'
    member :payload, converter: GandiV5::Template::Payload
    member(
      :sharing_space,
      gandi_key: 'sharing_space',
      converter: GandiV5::SharingSpace
    )

    # Requery Gandi for this template's information.
    # @return [GandiV5::Template]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def refresh
      _response, data = GandiV5.get url
      from_gandi data
      self
    end

    # Delete this template from Gandi.
    # @see https://api.gandi.net/docs/template/#delete-v5-template-templates-id
    # @return [String] The confirmation message from Gandi.
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def delete
      _response, data = GandiV5.delete url
      data['message']
    end

    # Applies the template to a domain.
    # @see https://api.gandi.net/v5/template/dispatch/{id}
    # @return [String] The UUID of the dispatch,
    #   keep hold of this you'll need it if you want to check the progress.
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def apply(domain_uuid)
      body = { 'object_type' => 'domain', 'object_id' => domain_uuid }.to_json
      _response, data = GandiV5.post url, body
      data.fetch('dispatch_href').split('/').last
    end

    # Update the template in Gandi.
    # @see https://api.gandi.net/docs/template/#patch-v5-template-templates-id
    # @param name [String, #to_s] the name to give the created template.
    # @param description [String, #to_s] description of what the template achieves.
    # @param dns_records [Array<Hash>, :default] The DNS records to create (as Gandi's docs)
    #   @option dns_records [String] :name The name of the DNS record to create.
    #   @option dns_records [String] :type The type of the DNS record to create.
    #   @option dns_records [Array<String>] :values The values for the created DNS record.
    #   @option dns_records [Integer] :ttl The TTL for the created record (300-2592000)
    # @param mailboxes [Array<String>] The mailboxes to create (as Gandi's docs)
    # @param name_servers [Array<String>, :livedns] The name servers to create (as Gandi's docs)
    # @param web_redirects [Array<Hash>] The web redirects to create (as Gandi's docs)
    #   @option web_redirects [:cloak, :http301, :http302] :type
    #   @option web_redirects [String] :target_url
    #   @option web_redirects [String] :source_host (optional)
    #   @option web_redirects [Boolean] :override (optional, default false)
    #      When you create a redirection on a domain, a DNS record is created if it does not exist.
    #      When the record already exists and this parameter is set to true it will overwrite the
    #      record. Otherwise it will trigger an error.
    #   @option web_redirects [:http, :https, :https_only] :target_protocol (optional)
    # @return [GandiV5::Template]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error
    # rubocop:disable Metrics/AbcSize
    def update(
      name: nil,
      description: nil,
      dns_records: nil,
      mailboxes: nil,
      name_servers: nil,
      web_redirects: nil
    )

      body = Hash.new { |hash, key| hash[key] = {} }
      body['name'] = name if name
      body['description'] = description if description
      body['payload']['dns:records'] = gandify_dns_records(dns_records) if dns_records
      body['payload']['domain:mailboxes'] = gandify_mailboxes(mailboxes) if mailboxes
      body['payload']['domain:nameservers'] = gandify_name_servers(name_servers) if name_servers
      body['payload']['domain:webredirs'] = gandify_web_redirects(web_redirects) if web_redirects

      GandiV5.patch url, body.to_json
      refresh
    end
    # rubocop:enable Metrics/AbcSize

    # Get information for a template.
    # @see https://api.gandi.net/docs/template/#get-v5-template-templates-id
    # @param uuid [String, #to_s] unique identifier of the template.
    # @return [GandiV5::Template]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def self.fetch(uuid)
      _response, data = GandiV5.get url(uuid)
      from_gandi data
    end

    # List templates.
    # @see https://api.gandi.net/docs/template/#get-v5-template-templates
    # @param page [Integer, #each<Integer>] which page(s) of results to get.
    #   If page is not provided keep querying until an empty list is returned.
    #   If page responds to .each then iterate until an empty list is returned.
    # @param per_page [Integer, #to_s] (optional default 100) how many results ot get per page.
    # @return [Array<GandiV5::Template>]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def self.list(page: (1..), per_page: 100)
      templates = []
      GandiV5.paginated_get(url, page, per_page) do |data|
        templates += data.map { |template| from_gandi template }
      end
      templates
    end

    # Create a new template.
    # @see https://api.gandi.net/docs/template/#post-v5-template-templates
    # @param name [String, #to_s] the name to give the created template.
    # @param description [String, #to_s] description of what the template achieves.
    # @param sharing_id [String] either:
    #   * nil (default) - nothing special happens,
    #     the template belongs to the user making the request.
    #   * an organization ID - the template will belong to the organization.
    #   * a reseller ID - the template will belong to the reseller.
    # @param payload [Hash, #to_h]
    # @option payload [Hash] 'dns:records' The DNS records to create (as Gandi's docs)
    # @option payload [Hash] 'domain:mailboxes' The mailboxes to create (as Gandi's docs)
    # @option payload [Hash] 'domain:nameservers' The name servers to create (as Gandi's docs)
    # @option payload [Hash] 'domain:webredirs' The web redirects to create (as Gandi's docs)
    # @option payload [Array<Hash>, :default] :dns_records
    #   Generate dns:records from the passed list or use Gandi's default records.
    #   @option dns_records [String] :name The name of the DNS record to create.
    #   @option dns_records [String] :type The type of the DNS record to create.
    #   @option dns_records [Array<String>] :values The values for the created DNS record.
    #   @option dns_records [Integer] :ttl The TTL for the created record (300-2592000)
    # @option payload [Array<String>] :mailboxes
    #   Generate domain:mailboxes from the passed list of mail names.
    # @option payload [Array<String>, :livedns] :name_servers
    #   Generate domain:nameservers from the passed list of addresses, or set to Gandi's livedns.
    # @option payload [Array<Hash>] :web_redirects Generate domain:webredirs from the passed list.
    #   @option web_redirects [:cloak, :http301, :http302] :type
    #   @option web_redirects [String] :target_url
    #   @option web_redirects [String] :source_host (optional)
    #   @option web_redirects [Boolean] :override (optional, default false)
    #      When you create a redirection on a domain, a DNS record is created if it does not exist.
    #      When the record already exists and this parameter is set to true it will overwrite the
    #      record. Otherwise it will trigger an error.
    #   @option web_redirects [:http, :https, :https_only] :target_protocol (optional)
    # @return [GandiV5::Template] the created template
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def self.create(name:, description:, sharing_id: nil, **payload)
      if payload.key? :dns_records
        payload['dns:records'] = gandify_dns_records(payload.delete(:dns_records))
      end
      if payload.key? :mailboxes
        payload['domain:mailboxes'] = gandify_mailboxes(payload.delete(:mailboxes))
      end
      if payload.key? :name_servers
        payload['domain:nameservers'] = gandify_name_servers(payload.delete(:name_servers))
      end
      if payload.key? :web_redirects
        payload['domain:webredirs'] = gandify_web_redirects(payload.delete(:web_redirects))
      end

      url_ = sharing_id ? "#{url}?sharing_id=#{sharing_id}" : url
      body = { name: name, description: description, payload: payload }.to_json

      response, _data = GandiV5.post url_, body
      fetch response.headers[:location].split('/').last
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    private

    def self.gandify_dns_records(value)
      if value == :default
        { default: true }
      else
        {
          default: false,
          records: value
        }
      end
    end
    private_class_method :gandify_dns_records

    def gandify_dns_records(value)
      self.class.send :gandify_dns_records, value
    end

    def self.gandify_mailboxes(value)
      { values: value.map { |name| { login: name } } }
    end
    private_class_method :gandify_mailboxes

    def gandify_mailboxes(value)
      self.class.send :gandify_mailboxes, value
    end

    def self.gandify_name_servers(value)
      if value == :livedns
        { service: :livedns }
      else
        {
          service: :custom,
          addresses: value
        }
      end
    end
    private_class_method :gandify_name_servers

    def gandify_name_servers(value)
      self.class.send :gandify_name_servers, value
    end

    def self.gandify_web_redirects(value)
      {
        values: value.map do |redirect|
          new_redirect = { type: redirect.fetch(:type), url: redirect.fetch(:target_url) }
          new_redirect[:host] = redirect[:source_host] if redirect.key?(:source_host)
          new_redirect[:override] = redirect[:override] if redirect.key?(:override)
          if redirect.key?(:target_protocol)
            new_redirect[:protocol] = redirect[:target_protocol].to_s.delete('_')
          end
          new_redirect
        end
      }
    end
    private_class_method :gandify_web_redirects

    def gandify_web_redirects(value)
      self.class.send :gandify_web_redirects, value
    end

    def url
      "#{BASE}template/templates/#{CGI.escape uuid}"
    end

    def self.url(uuid = nil)
      "#{BASE}template/templates" + (uuid ? "/#{CGI.escape uuid}" : '')
    end
    private_class_method :url
  end
end
