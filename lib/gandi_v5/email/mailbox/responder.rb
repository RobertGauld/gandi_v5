# frozen_string_literal: true

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

        attr_reader :mailbox

        members :enabled, :message
        member :starts_at, converter: GandiV5::Data::Converter::Time
        member :ends_at, converter: GandiV5::Data::Converter::Time

        # Create a new GandiV5::Email::Mailbox::Responder
        # @param mailbox [GandiV5::Email::Mailbox] the mailbox this responder belongs to.
        # @param members [Hash<Symbol => Object>]
        # @return [GandiV5::Email::Slot]
        def initialize(mailbox: nil, **members)
          super(**members)
          @mailbox = mailbox
        end

        # Check if this responder is currently active.
        # @return [Boolean] whether the responder is enabled,
        #   started in the past and ends in the future.
        def active?
          enabled &&
            (starts_at.nil? || starts_at < Time.now) &&
            (ends_at.nil? || ends_at > Time.now)
        end

        # Enable the auto responder in Gandi.
        # @param message [String]
        # @param starts_at [Time]
        # @param ends_at [Time]
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def enable(message:, ends_at:, starts_at: Time.now)
          mailbox.update responder: {
            message: message,
            starts_at: GandiV5::Data::Converter::Time.to_gandi(starts_at),
            ends_at: GandiV5::Data::Converter::Time.to_gandi(ends_at),
            enabled: true
          }

          self.starts_at = starts_at
          self.ends_at = ends_at
          self.message = message
          self.enabled = true
        end

        # Disable the auto responder in Gandi.
        # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
        def disable
          mailbox.update responder: { enabled: false }

          self.starts_at = nil
          self.ends_at = nil
          self.message = nil
          self.enabled = false
        end
      end
    end
  end
end
