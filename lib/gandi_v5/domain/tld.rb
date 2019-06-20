# frozen_string_literal: true

class GandiV5
  class Domain
    # Information about a specific TLD (Top Level Domain).
    # @!attribute [r] name
    #   @return [String]
    # @!attribute [r] full_tld
    #   @return [String]
    # @!attribute [r] authinfo_for_transfer
    #   @return [Boolean] whether authinfo is required for a transfer.
    # @!attribute [r] category
    #   @return [String]
    # @!attribute [r] change_owner
    #   @return [Boolean] whther changing owner is pemritted.
    # @!attribute [r] corporate
    #   @return [Boolean] whether this is a corporate TLD.
    # @!attribute [r] ext_trade
    #   @return [Boolean]
    # @!attribute [r] lock
    #   @return [Boolean]
    class TLD
      include GandiV5::Data

      members :name, :full_tld, :authinfo_for_transfer, :change_owner, :corporate, :ext_trade, :lock
      member :category, converter: GandiV5::Data::Converter::Symbol

      # List of available TLDs.
      # @see https://api.gandi.net/docs/domains#get-v5-domain-tlds
      # @return Array<GandiV5::Domain::TLD>
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.list
        GandiV5.get(url)
               .last
               .map { |tld| GandiV5::Domain::TLD.from_gandi tld }
      end

      # Get TLD information.
      # @see https://api.gandi.net/docs/domains#get-v5-domain-tlds-name
      # @param name [String, #to_s] the top level domain to get information for.
      # @return [GandiV5::Domain::TLD]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.fetch(name)
        _response, data = GandiV5.get url(name)
        GandiV5::Domain::TLD.from_gandi data
      end

      private

      def self.url(name = nil)
        "#{BASE}domain/tlds" +
          (name ? "/#{CGI.escape name}" : '')
      end
      private_class_method :url
    end
  end
end
