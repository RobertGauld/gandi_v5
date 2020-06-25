# frozen_string_literal: true

class GandiV5
  class Domain
    # Sharing space which contains a domain.
    # @!attribute [r] uuid
    #   @return [String]
    # @!attribute [r] name
    #   @return [String]
    # @!attribute [r] type
    #   @return [String]
    # @!attribute [r] reseller
    #   @return [nil, Boolean]
    # @!attribute [r] reseller_details
    #   @return [nil, GandiV5::Domain::SharingSpace]
    class SharingSpace
      include GandiV5::Data

      members :name, :type, :reseller
      member :uuid, gandi_key: 'id'
      member(
        :reseller_details,
        gandi_key: 'sharing_space',
        converter: GandiV5::Domain::SharingSpace
      )
      alias sharing_space_uuid uuid
    end
  end
end
