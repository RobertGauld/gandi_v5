# frozen_string_literal: true

class GandiV5
  class Template
    # Payload of a configuration template.
    # @!attribute [r] dns_records
    #   @return [Array<GandiV5::Template::Payload::DNSRecord>, :default, nil]
    #     the DNS records this template will create.
    # @!attribute [r] mailboxes
    #   @return [Array<String>, nil] the mailbox names (upto 2) which will be created.
    # @!attribute [r] name_servers
    #   @return [Array<String>, :live_dns, nil] hosts to use as name servers for the domain.
    # @!attribute [r] web_redirects
    #   @return [Array<GandiV5::Template::Payload::WebRedirect>, nil]
    #     what web redirects will be created.
    class Payload
      include GandiV5::Data

      member(
        :dns_records,
        gandi_key: 'dns:records',
        converter: GandiV5::Data::Converter.new(
          from_gandi: lambda { |hash|
            if hash['default']
              :default
            else
              hash.fetch('records').map do |item|
                GandiV5::Template::Payload::DNSRecord.from_gandi item
              end
            end
          }
        )
      )

      member(
        :mailboxes,
        gandi_key: 'domain:mailboxes',
        converter: GandiV5::Data::Converter.new(
          from_gandi: ->(h_a_h) { h_a_h.fetch('values').map { |h| h.fetch('login') } }
        )
      )

      member(
        :name_servers,
        gandi_key: 'domain:nameservers',
        converter: GandiV5::Data::Converter.new(
          from_gandi: ->(h) { h.fetch('service').eql?('livedns') ? :livedns : h.fetch('addresses') }
        )
      )

      member(
        :web_redirects,
        gandi_key: 'domain:webredirs',
        converter: GandiV5::Data::Converter.new(
          from_gandi: lambda { |hash|
            hash.fetch('values').map do |item|
              GandiV5::Template::Payload::WebRedirect.from_gandi item
            end
          }
        )
      )
    end
  end
end
