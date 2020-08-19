# frozen_string_literal: true

class GandiV5
  class Domain
    # Information for a single contact for a domain.
    # @!attribute [r] country
    #   @return [String]
    # @!attribute [r] email
    #   @return [String]
    # @!attribute [r] family
    #   @return [String]
    # @!attribute [r] given
    #   @return [String]
    # @!attribute [r] address
    #   @return [String]
    # @!attribute [r] type
    #   @return [:person, :company, :association, :'public body', :reseller]
    # @!attribute [r] brand_number
    #   @return [nil, String]
    # @!attribute [r] city
    #   @return [nil, String]
    # @!attribute [r] data_obfuscated
    #   @return [nil, Boolean]
    # @!attribute [r] extra_parameters
    #   @return [nil, Hash]
    # @!attribute [r] fax
    #   @return [nil, String]
    # @!attribute [r] jo_announce_number
    #   @return [nil, String]
    # @!attribute [r] jo_announce_page
    #   @return [nil, String]
    # @!attribute [r] jo_declaration_page
    #   @return [nil, String]
    # @!attribute [r] jo_publication_date
    #   @return [nil, String]
    # @!attribute [r] mail_obfuscated
    #   @return [nil, Boolean]
    # @!attribute [r] mobile
    #   @return [nil, String]
    # @!attribute [r] organisation_name
    #   @return [nil, String] the legal name of the company, association, or public body
    #     if the contact type is not :person.
    # @!attribute [r] phone
    #   @return [nil, String]
    # @!attribute [r] reachability
    #   @return [nil, :pending, :done, :failed, :deleted, :none]
    # @!attribute [r] sharing_uuid
    #   @return [nil, String]
    # @!attribute [r] siren
    #   @return [nil, String]
    # @!attribute [r] state
    #   @return [nil, String]
    #     @see https://docs.gandi.net/en/rest_api/domain_api/contacts_api.html
    # @!attribute [r] validation
    #   @return [nil, :pending, :done, :failed, :deleted, :none]
    # @!attribute [r] zip
    #   @return [nil, String]
    class Contact
      include GandiV5::Data

      TYPES = {
        person: 'Person',
        company: 'Company',
        association: 'Association',
        'public body': 'Public Body',
        reseller: 'Reseller'
      }.freeze
      REACHABILITIES = %i[pending done failed deleted none].freeze
      VALIDATIONS = %i[pending done failed deleted none].freeze

      members :country, :email, :family, :given, :brand_number, :city, :data_obfuscated,
              :extra_parameters, :fax, :jo_announce_number, :jo_announce_page,
              :jo_declaration_page, :jo_publication_date, :mail_obfuscated,
              :mobile, :phone, :siren, :state, :zip

      member :organisation_name, gandi_key: 'orgname'
      member :address, gandi_key: 'streetaddr'
      member :sharing_uuid, gandi_key: 'sharing_id'

      member(
        :type,
        converter: GandiV5::Data::Converter.new(
          from_gandi: ->(type) { TYPES.keys[type] },
          to_gandi: ->(type) { TYPES.keys.index(type) }
        )
      )
      member :reachability, converter: GandiV5::Data::Converter::Symbol
      member :validation, converter: GandiV5::Data::Converter::Symbol

      # Get the name for this contact.
      # @return [String] e.g. "John Smith" or "Some Company LTD."
      def name
        type.eql?(:person) ? "#{given} #{family}" : organisation_name
      end

      # @return [String] Containing type and name.
      def to_s
        "#{TYPES[type]}\t#{name}"
      end
    end
  end
end
