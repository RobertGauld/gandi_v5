# frozen_string_literal: true

class GandiV5
  class Template
    class Payload
      # DNS Record details of a configuration template.
      # @!attribute [r] type
      #   @return [:cloak, :http301, :http302]
      # @!attribute [r] target
      #   @return [String]
      # @!attribute [r] fqdn
      #   @return [String, nil]
      # @!attribute [r] override
      #   @return [Boolean, nil]
      #     when you create a redirection on a domain, a DNS record is created if it does not exist.
      #     When the record already exists and this parameter is set to true it will
      #     overwrite the record. Otherwise it will trigger an error.
      # @!attribute [r] protocol
      #   @return [:http, :https, :https_only, nil]
      class WebRedirect
        include GandiV5::Data

        member :type, converter: GandiV5::Data::Converter::Symbol
        member :target, gandi_key: 'url'
        member :fqdn, gandi_key: 'host'
        member :override
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
      end
    end
  end
end
