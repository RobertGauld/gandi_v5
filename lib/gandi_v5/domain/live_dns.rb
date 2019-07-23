# frozen_string_literal: true

class GandiV5
  class Domain
    # LiveDNS information for a domain.
    # @!attribute [r] current
    #   @return [:classic, :livedns, :other]
    #     type of nameservers currently set. classic corresponds to Gandi's classic nameservers,
    #     livedns is for the new, default, Gandi nameservers and other is for custom nameservers.
    # @!attribute [r] name_servers
    #   @return [Array<String>] list of current nameservers.
    # @!attribute [r] dnssec_available
    #   @return [nil, Boolean] whether DNSSEC may be applied to the domain.
    # @!attribute [r] livednssec_available
    #   @return [nil, Boolean] whether DNSSEC with liveDNS may be applied to this domain.
    class LiveDNS
      include GandiV5::Data

      members :dnssec_available, :livednssec_available
      member :name_servers, gandi_key: 'nameservers'
      member :current, converter: GandiV5::Data::Converter::Symbol

      # Check if classic DNS is being used.
      # @return [Boolean]
      def classic?
        current == :classic
      end

      # Check if custom DNS is being used.
      # @return [Boolean]
      def custom?
        current == :custom
      end

      # Check if LiveDNS is being used.
      # @return [Boolean]
      def livedns?
        current == :livedns
      end
    end
  end
end
