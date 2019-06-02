# frozen_string_literal: true

class GandiV5
  class Domain
    # Dates of key events for a domain.
    # @!attribute [r] registry_created_at
    #   @return [Time]
    # @!attribute [r] updated_at
    #   @return [Time]
    # @!attribute [r] authinfo_expires_at
    #   @return [nil, Time]
    # @!attribute [r] created_at
    #   @return [nil, Time]
    # @!attribute [r] deletes_at
    #   @return [nil, Time]
    # @!attribute [r] hold_begins_at
    #   @return [nil, Time]
    # @!attribute [r] hold_ends_at
    #   @return [nil, Time]
    # @!attribute [r] pending_delete_ends_at
    #   @return [nil, Time]
    # @!attribute [r] registry_ends_at
    #   @return [nil, Time]
    # @!attribute [r] renew_begins_at
    #   @return [nil, Time]
    # @!attribute [r] restore_ends_at
    #   @return [nil, Time]
    class Dates
      include GandiV5::Data

      member :registry_created_at, converter: GandiV5::Data::Converter::Time
      member :updated_at, converter: GandiV5::Data::Converter::Time
      member :authinfo_expires_at, converter: GandiV5::Data::Converter::Time
      member :created_at, converter: GandiV5::Data::Converter::Time
      member :deletes_at, converter: GandiV5::Data::Converter::Time
      member :hold_begins_at, converter: GandiV5::Data::Converter::Time
      member :hold_ends_at, converter: GandiV5::Data::Converter::Time
      member :pending_delete_ends_at, converter: GandiV5::Data::Converter::Time
      member :registry_ends_at, converter: GandiV5::Data::Converter::Time
      member :renew_begins_at, converter: GandiV5::Data::Converter::Time
      member :restore_ends_at, converter: GandiV5::Data::Converter::Time
    end
  end
end
