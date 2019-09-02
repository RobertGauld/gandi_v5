# frozen_string_literal: true

class GandiV5
  # Gandi Domain Management API.
  # @see https://api.gandi.net/docs/domains
  # @!attribute [r] fqdn
  #   @return [String] fully qualified domain name, written in its native alphabet (IDN).
  # @!attribute [r] fqdn_unicode
  #   @return [String] fully qualified domain name, written in unicode.
  #     @see https://docs.gandi.net/en/domain_names/register/idn.html
  # @!attribute [r] name_servers
  #   @return [Array<String>]
  # @!attribute [r] services
  #   @return [Array<Symbol>] list of Gandi services attached to this domain.
  #      gandidns, redirection, gandimail, packmail, dnssec, blog, hosting,
  #      paas, site, certificate, gandilivedns, mailboxv2
  # @!attribute [r] sharing_space
  #   @return [GandiV5::Domain::SharingSpace]
  # @!attribute [r] status
  #   @return [String] one of: "clientHold", "clientUpdateProhibited", "clientTransferProhibited",
  #     "clientDeleteProhibited", "clientRenewProhibited", "serverHold", "pendingTransfer",
  #     "serverTransferProhibited"
  #     @see https://docs.gandi.net/en/domain_names/faq/domain_statuses.html
  # @!attribute [r] tld
  #   @return [String]
  # @!attribute [r] dates
  #   @return [GandiV5::Domain::Dates]
  # @!attribute [r] can_tld_lock
  #   @return [Boolean]
  # @!attribute [r] contacts
  #   @return [Hash<:owner, :admin, :bill, :tech => GandiV5::Domain::Contact>]
  # @!attribute [r] auto_renew
  #   @return [GandiV5::Domain::AutoRenew]
  # @!attribute [r] auth_info
  #   @return [nil, String]
  # @!attribute [r] uuid
  #   @return [nil, String]
  # @!attribute [r] sharing_uuid
  #   @return [nil, String]
  # @!attribute [r] tags
  #   @return [nil, Array<String>] list of tags that have been assigned to the domain.
  # @!attribute [r] trustee_roles
  #   @return [nil, Array<Symbol>] one of: admin, tech.
  # @!attribute [r] owner
  #   @return [String]
  # @!attribute [r] organisation_owner
  #   @return [_String
  # @!attribute [r] domain_owner
  #   @return [String]
  # @!attribute [r] name_server
  #   @return [Symbol]
  class Domain
    include GandiV5::Data

    SERVICES = {
      gandidns: 'GandiDNS',
      gandilivedns: 'LiveDNS',
      dnssec: 'DNSSEC',
      certificate: 'SSL Certificate',
      paas: 'PAAS',
      redirection: 'Redirection',
      gandimail: 'GandiMail',
      packmail: 'PackMail',
      blog: 'Blog',
      hosting: 'Hosting',
      site: 'Site',
      mailboxv2: 'MailboxV2'
    }.freeze

    STATUSES = {
      clientHold: 'clientHold',
      clientUpdateProhibited: 'clientUpdateProhibited',
      clientTransferProhibited: 'clientTransferProhibited',
      clientDeleteProhibited: 'clientDeleteProhibited',
      clientRenewProhibited: 'clientRenewProhibited',
      serverHold: 'serverHold',
      pendingTransfer: 'pendingTransfer',
      serverTransferProhibited: 'serverTransferProhibited'
    }.freeze

    CONTACTS_CONVERTER = lambda { |hash|
      break {} if hash.nil?

      hash = hash.transform_keys(&:to_sym)
                 .transform_values { |value| GandiV5::Domain::Contact.from_gandi value }

      hash.define_singleton_method(:owner) { send :'[]', :owner }
      hash.define_singleton_method(:admin) { send :'[]', :admin }
      hash.define_singleton_method(:bill) { send :'[]', :bill }
      hash.define_singleton_method(:tech) { send :'[]', :tech }

      hash
    }
    private_constant :CONTACTS_CONVERTER

    members :fqdn, :fqdn_unicode, :tld, :can_tld_lock, :tags, :owner, :domain_owner
    member :sharing_uuid, gandi_key: 'sharing_id'
    member :name_servers, gandi_key: 'nameservers'
    member :auth_info, gandi_key: 'authinfo'
    member :organisation_owner, gandi_key: 'orga_owner'
    member :uuid, gandi_key: 'id'

    member(
      :dates,
      converter: GandiV5::Domain::Dates
    )
    member(
      :sharing_space,
      gandi_key: 'sharing_space',
      converter: GandiV5::Domain::SharingSpace
    )

    member(
      :auto_renew,
      gandi_key: 'autorenew',
      converter: GandiV5::Data::Converter.new(from_gandi: lambda { |hash|
        break nil if hash.nil?
        break nil if hash.eql?(true)
        break GandiV5::Domain::AutoRenew.from_gandi('enabled' => false) if hash.eql?(false)

        GandiV5::Domain::AutoRenew.from_gandi hash
      })
    )

    member(
      :contacts,
      converter: GandiV5::Data::Converter.new(from_gandi: CONTACTS_CONVERTER)
    )

    member(
      :name_server,
      gandi_key: 'nameserver',
      converter: GandiV5::Data::Converter.new(from_gandi: ->(hash) { hash&.[]('current')&.to_sym })
    )
    member :services, converter: GandiV5::Data::Converter::Symbol, array: true
    member :status, converter: GandiV5::Data::Converter::Symbol, array: true
    member :trustee_roles, converter: GandiV5::Data::Converter::Symbol, array: true

    alias domain_uuid uuid

    # rubocop:disable Style/AsciiComments
    # Returns the string representation of the domain.
    # @return [String] e.g. "example.com", "😀.com (xn--e28h.uk.com)"
    # rubocop:enable Style/AsciiComments
    def to_s
      string = fqdn_unicode
      string += " (#{fqdn})" unless fqdn == fqdn_unicode
      string
    end

    # Contacts for the domain.
    # @see https://api.gandi.net/docs/domains#get-v5-domain-domains-domain-contacts
    # @return [Hash{:owner, :admin, :bill, :tech => GandiV5::Domain::Contact}]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def contacts
      @contacts ||= fetch_contacts
    end

    # Requery Gandi for the domain's contacts.
    # @see https://api.gandi.net/docs/domains#get-v5-domain-domains-domain-contacts
    # @return [Hash{:owner, :admin, :bill, :tech => GandiV5::Domain::Contact}]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def fetch_contacts
      _response, data = GandiV5.get url('contacts')
      self.contacts = data.transform_keys(&:to_sym)
      CONTACTS_CONVERTER.call contacts
    end

    # Update some of the domain's contacts.
    # @see https://api.gandi.net/docs/domains#patch-v5-domain-domains-domain-contacts
    # @param admin [GandiV5::Domain::Contact, #to_gandi, #to_h]
    #   details for the new administrative contact.
    # @param bill [GandiV5::Domain::Contact, #to_gandi, #to_h]
    #   details for the new billing contact.
    # @param tech [GandiV5::Domain::Contact, #to_gandi, #to_h]
    #   details for the new technical contact.
    # @return [Hash{:owner, :admin, :bill, :tech => GandiV5::Domain::Contact}]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def update_contacts(admin: nil, bill: nil, tech: nil)
      body = {
        admin: admin.respond_to?(:to_gandi) ? admin.to_gandi : admin,
        bill: bill.respond_to?(:to_gandi) ? bill.to_gandi : bill,
        tech: tech.respond_to?(:to_gandi) ? tech.to_gandi : tech
      }.reject { |_k, v| v.nil? }.to_json

      GandiV5.patch url('contacts'), body
      fetch_contacts
    end

    # Renewal information for the domain.
    # @see https://api.gandi.net/docs/domains#get-v5-domain-domains-domain-renew
    # @return [GandiV5::Domain::RenewalInformation]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def renewal_information
      @renewal_information ||= fetch_renewal_information
    end

    # Requery Gandi for the domain's renewal information.
    # @see https://api.gandi.net/docs/domains#get-v5-domain-domains-domain-renew
    # @return [GandiV5::Domain::RenewalInformation]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def fetch_renewal_information
      _response, data = GandiV5.get url('renew')
      data = data['renew'].merge('contracts' => data['contracts'])
      @renewal_information = GandiV5::Domain::RenewalInformation.from_gandi data
    end

    # Renew domain.
    # Warning! This is not a free operation. Please ensure your prepaid account has enough credit.
    # @see https://api.gandi.net/docs/domains#post-v5-domain-domains-domain-renew
    # @param duration [Integer, #to_s] how long to renew for (in years).
    # @return [String] confirmation message from Gandi.
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def renew_for(duration = 1)
      body = { duration: duration }.to_json
      _response, data = GandiV5.post url('renew'), body
      data['message']
    end

    # Restoration information for the domain.
    # @see https://docs.gandi.net/en/domain_names/renew/restore.html
    # @see https://api.gandi.net/docs/domains#get-v5-domain-domains-domain-restore
    # @return [GandiV5::Domain::RestoreInformation]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def restore_information
      @restore_information ||= fetch_restore_information
    end

    # Requery Gandi for the domain's restore information.
    # @see https://docs.gandi.net/en/domain_names/renew/restore.html
    # @see https://api.gandi.net/docs/domains#get-v5-domain-domains-domain-restore
    # @return [GandiV5::Domain::RestoreInformation]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def fetch_restore_information
      _response, data = GandiV5.get url('restore')
      @restore_information = GandiV5::Domain::RestoreInformation.from_gandi data
    rescue RestClient::NotFound
      @restore_information = GandiV5::Domain::RestoreInformation.from_gandi restorable: false
    end

    # Restore an expired domain.
    # Warning! This is not a free operation. Please ensure your prepaid account has enough credit.
    # @see https://docs.gandi.net/en/domain_names/renew/restore.html
    # @see https://api.gandi.net/docs/domains#post-v5-domain-domains-domain-restore
    # @return [String] The confirmation message from Gandi.
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def restore
      _response, data = GandiV5.post url('restore'), '{}'
      data['message']
    end

    # Requery Gandi fo this domain's information.
    # @return [GandiV5::Domain]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def refresh
      _response, data = GandiV5.get url
      from_gandi data
      auto_renew.domain = self
    end

    # Get the price for renewing this domain.
    # @param currency [String] the currency to get the price in (e.g. GBP)
    # @param period [Integer] the number of year(s) renewal to get the price for
    # @return [GandiV5::Domain::Availability::Product::Price]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error
    def renewal_price(currency: 'GBP', period: 1)
      arguments = { processes: [:renew], currency: currency, period: period }
      GandiV5::Domain::Availability.fetch(fqdn, **arguments)
                                   .products.first
                                   .prices.first
    end

    # LiveDNS information for the domain.
    # @see https://api.gandi.net/docs/domains#get-v5-domain-domains-domain-livedns
    # @return [GandiV5::Domain::LiveDNS]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def livedns
      @livedns ||= fetch_livedns
    end

    # Requery Gandi for the domain's LiveDNS information.
    # @see https://api.gandi.net/docs/domains#get-v5-domain-domains-domain-livedns
    # @return [GandiV5::Domain::LiveDNS]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def fetch_livedns
      _response, data = GandiV5.get url('livedns')
      @livedns = GandiV5::Domain::LiveDNS.from_gandi data
      @name_server = @livedns.current
      @name_servers = @livedns.name_servers
      @livedns
    end

    # Enable LiveDNS for the domain.
    # If you want to disable LiveDNS, change the nameservers.
    # Please note that if the domain is on the classic Gandi DNS,
    # this will also perform a copy of all existing records immediately afterwards.
    # @see https://api.gandi.net/docs/domains#post-v5-domain-domains-domain-livedns
    # @return [String] confirmation message from Gandi.
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def enable_livedns
      _response, data = GandiV5.post url('livedns')
      data['message']
    end

    # Name servers for the domain.
    # @see https://api.gandi.net/docs/domains#get-v5-domain-domains-domain-nameservers
    # @return [Array<String>]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def name_servers
      @name_servers ||= fetch_name_servers
    end

    # Requery Gandi for the domain's name servers.
    # @see https://api.gandi.net/docs/domains#get-v5-domain-domains-domain-nameservers
    # @return [Array<String>]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def fetch_name_servers
      _response, data = GandiV5.get url('nameservers')
      @name_servers = data
    end

    # Update name servers in Gandi.
    # @see https://api.gandi.net/docs/domains#put-v5-domain-domains-domain-nameservers
    # @param nameservers [Array<String>] the name servers to use.
    # @return [String] confirmation message from Gandi.
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def update_name_servers(nameservers)
      _response, data = GandiV5.put url('nameservers'), { 'nameservers' => nameservers }.to_json
      @name_servers = nameservers
      data['message']
    end

    # Glue records for the domain.
    # @see https://api.gandi.net/docs/domains#get-v5-domain-domains-domain-hosts
    # @return [Hash<String => Array<String>>] name to list of IPs
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def glue_records
      @glue_records ||= fetch_glue_records
    end

    # Requery Gandi for the domain's glue records.
    # @see https://api.gandi.net/docs/domains#get-v5-domain-domains-domain-hosts
    # @return [Hash<String => Array<String>>] name to list of IPs
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def fetch_glue_records
      _response, data = GandiV5.get url('hosts')
      @glue_records = data.map { |record| record.values_at('name', 'ips') }.to_h
    end

    # Add a new glue record to the domain in Gandi.
    # @see https://api.gandi.net/docs/domains#post-v5-domain-domains-domain-hosts
    # @param name [String] the DNS name (excluding FQDN) for the glue record to add (e.g. 'ns1').
    # @param ips [Array<String>] the IPs for the name.
    # @return [String] confirmation message from Gandi.
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def add_glue_record(name, *ips)
      _response, data = GandiV5.post url('hosts'), { 'name' => name, 'ips' => ips }.to_json
      @glue_records ||= {}
      @glue_records[name] = ips
      data['message']
    end

    # Get a specific glue record for the domain.
    # @see https://api.gandi.net/docs/domains#get-v5-domain-domains-domain-hosts
    # @param name [String] the DNS name (excluding FQDN) for the glue record to add (e.g. 'ns1').
    # @return [Hash<String => Array<String>>] name to list of IPs
    # @return [nil] name was not found
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def glue_record(name)
      records = @glue_records.key?(name) ? @glue_records : fetch_glue_records
      records.key?(name) ? records.select { |k, _v| k == name } : nil
    end

    # Update a specific glue record for the domain.
    # @see https://api.gandi.net/docs/domains#put-v5-domain-domains-domain-hosts-name
    # @param name [String] the DNS name (excluding FQDN) for the glue record to update (e.g. 'ns1').
    # @param ips [Array<String>] the IPs for the name.
    # @return [String] confirmation message from Gandi.
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def update_glue_record(name, *ips)
      _response, data = GandiV5.put url('hosts', name), { 'ips' => ips }.to_json
      @glue_records ||= {}
      @glue_records[name] = ips
      data['message']
    end

    # Delete a specific glue record for the domain.
    # @see https://api.gandi.net/docs/domains#delete-v5-domain-domains-domain-hosts-name
    # @param name [String] the DNS name (excluding FQDN) for the glue record to update (e.g. 'ns1').
    # @return [String] confirmation message from Gandi.
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def delete_glue_record(name)
      _response, data = GandiV5.delete url('hosts', name)
      @glue_records ||= {}
      @glue_records.delete(name)
      data['message']
    end

    # Create (register) a new domain.
    # Warning! This is not a free operation. Please ensure your prepaid account has enough credit.
    # @see https://api.gandi.net/docs/domains#post-v5-domain-domains
    # @param fqdn [String, #to_s] the fully qualified domain name to create.
    # @param owner [GandiV5::Domain::Contact, #to_gandi, #to_h] (required)
    #   the owner of the new domain.
    # @param admin [GandiV5::Domain::Contact, #to_gandi, #to_h] (optional, defaults to owner)
    #   the administrative contact for the new domain.
    # @param bill [GandiV5::Domain::Contact, #to_gandi, #to_h] (optional, defaults to owner)
    #   the billing contact for the new domain.
    # @param tech [GandiV5::Domain::Contact, #to_gandi, #to_h] (optional, defaults to owner)
    #   the technical contact for the new domain.
    # @param claims [String] (optional) unknown - not documented at Gandi.
    # @param currency ["EUR", "USD", "GBP", "TWD", "CNY"] (optional)
    #   the currency you wish to be charged in.
    # @param duration [Integer] (optional, default 1, minimum 1 maximum 10)
    #   how many years to register for.
    # @param enforce_premium [Boolean] (optional)
    #   must be set to true if the domain is a premium domain.
    # @param extra_parameters [Hash, #to_gandi, #to_json] (optional)
    #   unknown - not documented at Gandi.
    # @param lang [String] (optional)
    #   ISO-639-2 language code of the domain, required for some IDN domains.
    # @param nameserver_ips [Hash<String => Array<String>>, #to_gandi, #to_json] (optional)
    #   For glue records only - dictionnary associating a nameserver to a list of IP addresses.
    # @param nameservers [Array<String>, #to_gandi, #to_json] (optional)
    #   List of nameservers. Gandi's LiveDNS nameservers are used if omitted..
    # @param price [Numeric, #to_gandi, #to_json] (optional) unknown - not documented at Gandi.
    # @param reselle_id [String, #to_gandi, #to_json] (optional) unknown - not documented at Gandi.
    # @param smd [String, #to_gandi, #to_json] (optional)
    #   Contents of a Signed Mark Data file (used for newgtld sunrises, tld_period must be sunrise).
    # @param tld_period ["sunrise", "landrush", "eap1", "eap2", "eap3", "eap4", "eap5", "eap6",
    #   "eap7", "eap8", "eap9", "golive", #to_gandi, #to_json] (optional)
    #   @see https://docs.gandi.net/en/domain_names/register/new_gtld.html
    # @param dry_run [Boolean] whether the details should be checked
    #   instead of actually creating the domain
    # @return [GandiV5::Domain] the created domain
    # @return [Hash] if doing a dry run, you get what Gandi returns
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error
    def self.create(fqdn, dry_run: false, **params)
      fail ArgumentError, 'missing keyword: owner' unless params.key?(:owner)

      body = params.merge(fqdn: fqdn)
                   .transform_values { |val| val.respond_to?(:to_gandi) ? val.to_gandi : val }
                   .to_json

      response, data = GandiV5.post(url, body, 'Dry-Run': dry_run ? 1 : 0)
      dry_run ? data : fetch(response.headers[:location].split('/').last)
    end

    # Get information on a domain.
    # @see https://api.gandi.net/docs/domains#get-v5-domain-domains-domain
    # @param fqdn [String, #to_s] the fully qualified domain name to fetch.
    # @return [GandiV5::Domain]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def self.fetch(fqdn)
      _response, data = GandiV5.get url(fqdn)
      domain = from_gandi data
      domain.auto_renew.domain = fqdn
      domain
    end

    # List domains.
    # @see https://api.gandi.net/docs/domains#get-v5-domain-domains
    # @param page [#each<Integer, #to_s>] the page(s) of results to retrieve.
    #   If page is not provided keep querying until an empty list is returned.
    #   If page responds to .each then iterate until an empty list is returned.
    # @param per_page [Integer, #to_s] (optional default 100) how many results ot get per page.
    # @param fqdn [String, #to_s] (optional)
    #   filters the list by domain name, with optional patterns.
    #   e.g. "example.net", "example.*", "*ample.com"
    # @param sort_by [String, #to_s] (optional default "fqdn") how to sort the list.
    # @param tld [String, #to_s] (optional) used to filter by just the top level domain.
    # @return [Array<GandiV5::Domain>]
    # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
    def self.list(page: (1..), per_page: 100, **params)
      page = [page.to_i] unless page.respond_to?(:each)

      domains = []
      page.each do |page_number|
        _resp, data = GandiV5.get url, params: params.merge(page: page_number, per_page: per_page)
        break if data.empty?

        domains += data.map { |domain| from_gandi domain }
        break if data.count < per_page
      end
      domains
    end

    private

    def url(*extra)
      "#{BASE}domain/domains/" +
        CGI.escape(fqdn) +
        (extra.empty? ? '' : "/#{extra.join('/')}")
    end

    def self.url(fqdn = nil)
      "#{BASE}domain/domains" +
        (fqdn ? "/#{CGI.escape fqdn}" : '')
    end
    private_class_method :url
  end
end
