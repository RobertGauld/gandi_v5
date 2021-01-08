# frozen_string_literal: true

class GandiV5
  class Template
    class Payload
      # Web forwarding details of a configuration template.
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
      class WebForwarding
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

        # Check if it's an http end point
        def http?
          protocol == :http || protocol == :https
        end

        # Check if it's an https end point
        def https?
          protocol == :https || protocol == :https_only
        end

        # Check if it's an https only
        def https_only?
          protocol == :https_only
        end
      end
    end
  end
end
