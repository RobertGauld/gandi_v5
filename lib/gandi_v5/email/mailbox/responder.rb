# frozen_string_literal: true

# TODO: Allow enable/disable from here too ???

class GandiV5
  class Email
    class Mailbox
      # Status of a mailbox's auto responder.
      # @see https://api.gandi.net/docs/email#get-v5-email-mailboxes-domain-mailbox_id
      # @!attribute [r] enabled
      #   @return [Boolean]
      # @!attribute [r] starts_at
      #   @return [nil, Time]
      # @!attribute [r] ends_at
      #   @return [nil, Time]
      # @!attribute [r] message
      #   @return [nil, String]
      class Responder
        include GandiV5::Data

        members :enabled, :message
        member :starts_at, converter: GandiV5::Data::Converter::Time
        member :ends_at, converter: GandiV5::Data::Converter::Time

        # Check if this responder is currently active.
        # @return [Boolean] whether the responder is enabled,
        #   started in the past and ends in the future.
        def active?
          enabled &&
            (starts_at.nil? || starts_at < Time.now) &&
            (ends_at.nil? || ends_at > Time.now)
        end
      end
    end
  end
end
