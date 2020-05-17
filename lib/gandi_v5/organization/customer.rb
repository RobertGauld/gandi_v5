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
    #   @return [:individual, :company, :association :publicbody]
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

      # List organisation's customers.
      # @see https://api.gandi.net/docs/organization/#get-v5-organization-organizations-id-customers
      # @param org_uuid [String] Organization's UUID to fetch customers for.
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
