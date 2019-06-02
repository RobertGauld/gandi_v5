# frozen_string_literal: true

class GandiV5
  class Domain
    # Restoration information for a domain.
    # @see https://docs.gandi.net/en/domain_names/renew/restore.html
    # @!attribute [r] restorable
    #   @return [Boolean]
    # @!attribute [r] contracts
    #   @return [nil, Array<GandiV5::Domain::Contract>]
    class RestoreInformation
      include GandiV5::Data

      members :restorable, :contracts
      member :contracts, converter: GandiV5::Domain::Contract, array: true
    end
  end
end
