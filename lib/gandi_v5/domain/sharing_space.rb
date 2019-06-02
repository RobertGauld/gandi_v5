# frozen_string_literal: true

class GandiV5
  class Domain
    # Sharing space which contains a domain.
    # @!attribute [r] uuid
    #   @return [String]
    # @!attribute [r] name
    #   @return [String]
    # @!attribute [r] reseller
    #   @return [nil, Boolean]
    class SharingSpace
      include GandiV5::Data

      members :name, :reseller
      member :uuid, gandi_key: 'id'

      alias sharing_space_uuid uuid
    end
  end
end
