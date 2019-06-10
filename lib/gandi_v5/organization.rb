# frozen_string_literal: true

require_relative 'email/mailbox'
require_relative 'email/offer'
require_relative 'email/slot'

class GandiV5
  # The Organization API is a read-only API.
  # All organization management must be performed via the web interface.
  # @see https://api.gandi.net/docs/organization
  # @!attribute [r] uuid
  #   @return [String] the sharing uuid of the user.
  # @!attribute [r] username
  #   @return [String] the username of the user.
  # @!attribute [r] name
  #   @return [String] the sharing name of the user.
  # @!attribute [r] first_name
  #   @return [nil, String] the first name of the user.
  # @!attribute [r] last_name
  #   @return [nil, String] the last name of the user.
  # @!attribute [r] lang
  #   @return [String] language used by the user.
  # @!attribute [r] street_address
  #   @return [nil, String] the street address of the user.
  # @!attribute [r] city
  #   @return [String] the city name of the address.
  # @!attribute [r] zip
  #   @return [nil, String] zip code of the address.
  # @!attribute [r] country
  #   @return [nil, String] country ISO code of the address.
  # @!attribute [r] email
  #   @return [String] the email address of the user.
  # @!attribute [r] phone
  #   @return [nil, String] the phone number of the user.
  # @!attribute [r] security_email
  #   @return [String] email address used for security processes such as account recovery.
  # @!attribute [r] security_phone
  #   @return [nil, String]
  #      phone number used for security recovery processes such as totp recovery.
  # @!attribute [r] security_email_validated
  #   @return [Boolean] state of the email validation process.
  # @!attribute [r] security_email_validation_deadline
  #   @return [Time] deadline for the email address validation process.
  class Organization
    include GandiV5::Data

    members :username, :name, :lang, :city, :zip, :country, :email, :phone, :security_phone,
            :security_email, :security_email_validated, :security_email_validation_deadline
    member :uuid, gandi_key: 'id'
    member :first_name, gandi_key: 'firstname'
    member :last_name, gandi_key: 'lastname'
    member :street_address, gandi_key: 'streetaddr'
    member :security_email_validation_deadline, converter: GandiV5::Data::Converter::Time

    alias organization_uuid uuid

    # Get information about the current authenticated user.
    # @see https://api.gandi.net/docs/organization#get-v5-organization-user-info
    # @return [GandiV5::Organization]
    # @raise [GandiV5::Error::GandiError::GandiError] if Gandi returns an error.
    def self.fetch
      _response, data = GandiV5.get "#{BASE}organization/user-info"
      from_gandi data
    end
  end
end
