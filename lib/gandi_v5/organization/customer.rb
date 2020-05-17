# frozen_string_literal: true

class GandiV5
  class Organization
    # A customer of a reseller organization
    # @!attribute [r] id
    #   @return [String] The main identifier of the customer.
    #                    Also known as sharing_id in many routes.
    # @!attribute [r] email
    #   @return [String] Email of the customer.
    # @!attribute [r] first_name
    #   @return [String] First name of the customer.
    # @!attribute [r] last_name
    #   @return [String] Last name of the customer.
    # @!attribute [r] name
    #   @return [String] Name of the customer.
    # @!attribute [r] type
    #   @return [:individual, :company, :association, :publicbody]
    # @!attribute [r] org_name
    #   @return [nil, String] Organization legal name of the customer..
    class Customer
      include GandiV5::Data

      members :email, :name
      member :uuid, gandi_key: 'id'
      member :first_name, gandi_key: 'firstname'
      member :last_name, gandi_key: 'lastname'
      member :org_name, gandi_key: 'orgname'
      member :type, converter: GandiV5::Data::Converter::Symbol

      # Create a new customer for this organization.
      # @see https://api.gandi.net/docs/organization/#post-v5-organization-organizations-id-customers
      # @param org_uuid [String] UUID of the organization to create the customer for.
      # @param firstname [String, #to_s] (required) Customer's first name.
      # @param lastname [String, #to_s] (required) Customer's last name.
      # @param type [String, #to_s] (required) Type of customer
      #   ("individual", "company", "association" or "publicbody").
      # @param streetaddr [String, #to_s] (required) Customer's street address.
      # @param city [String, #to_s] (required) Customer's city.
      # @param country [String, #to_s] (required) Customer's country.
      # @param email [String, #to_s] (required) Customer's email address.
      # @param phone [String, #to_s] (required) Customer's phone number.
      # @param fax [String, #to_s] (optional) Customer's fax number.
      # @param streetaddr2 [String, #to_s] (optional) Customer's street address (2nd line).
      # @param state [String, #to_s] (optional) Customer's state/province/region.
      # @param zip [String, #to_s] (optional) Customer's postal/zip code.
      # @param reference [String, #to_s] (optional)
      #   Optional text to display on the invoice, such as your own customer reference info.
      # @param orgname [String, #to_s] (optional) Customer Organization's legal name.
      # @return [nil]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error
      def self.create(org_uuid, **params)
        %i[city country email firstname lastname phone streetaddr type].each do |attr|
          fail ArgumentError, "missing keyword: #{attr}" unless params.key?(attr)
        end
        unless %w[individual company association publicbody].include?(params[:type].to_s)
          fail ArgumentError, "invalid type: #{params[:type].inspect}"
        end

        _response, _data = GandiV5.post(url(org_uuid), params.to_json)
        nil
      end

      # List organisation's customers.
      # @see https://api.gandi.net/docs/organization/#get-v5-organization-organizations-id-customers
      # @param org_uuid [String] UUID of the organization to fetch customers for.
      # @param name [String, #to_s] (optional)
      #   filters the list by name, with optional patterns.
      #   e.g. "alice", "ali*", "*ice"
      # @param permission [String, #to_s] (optional)
      #   filters the list by the permission the authenticated user has on
      #   that organization and products in it.
      # @param sort_by [String, #to_s] (optional default "name") how to sort the list.
      # @return [Array<GandiV5::Organization>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.list(org_uuid, **params)
        params['~name'] = params.delete(:name) if params.key?(:name)
        _resp, data = GandiV5.get url(org_uuid), params: params
        data.map { |organisation| from_gandi organisation }
      end

      private

      def self.url(org_uuid)
        "#{BASE}organization/organizations/#{org_uuid}/customers"
      end
      private_class_method :url
    end
  end
end
