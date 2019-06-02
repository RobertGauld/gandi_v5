# frozen_string_literal: true

class GandiV5
  class Domain
    # A contract relevant to renewing/restoring a domain.
    # @!attribute [r] id
    #   @return [String]
    # @!attribute [r] name
    #   @return [String]
    # @!attribute [r] href
    #   @return [nil, String]
    # @!attribute [r] registry_contract_href
    #   @return [nil, String]
    class Contract
      include GandiV5::Data

      members :id, :name, :href, :registry_contract_href

      alias contract_id id
    end
  end
end
