# frozen_string_literal: true

class GandiV5
  class Email
    # A slot is attached to a domain and (optionally) contains a mailbox.
    # There must be an available slot for a mailbox to be created.
    # @!attribute [r] capacity
    #   @return [Integer] slot capacity (in MB).
    # @!attribute [r] created_at
    #   @return [Time]
    # @!attribute [r] id
    #   @return [Integer]
    # @!attribute [r] mailbox_type
    #   @return [:standard, :premium]
    # @!attribute [r] status
    #   @return [:active, :inactive]
    # @!attribute [r] refundable
    #   @return [Boolean]
    # @!attribute [r] refund_amount
    #   @return [nil, Numeric] refunded amount if you delete this slot now.
    # @!attribute [r] refund_currency
    #   @return [nil, String] refund currency.
    class Slot
      include GandiV5::Data

      attr_reader :fqdn

      members :id, :refundable, :refund_amount, :refund_currency
      member(
        :capacity,
        converter: GandiV5::Data::Converter.new(
          from_gandi: ->(value) { value * 1_024**2 }
        )
      )
      member :created_at, converter: GandiV5::Data::Converter::Time
      member :mailbox_type, converter: GandiV5::Data::Converter::Symbol
      member :status, converter: GandiV5::Data::Converter::Symbol

      alias slot_id id

      # Create a new GandiV5::Email::Slot
      # @param fqdn [String] the fully qualified domain this slot belongs to.
      # @param members [Hash<Symbol => Object>]
      # @return [GandiV5::Email::Slot]
      def initialize(fqdn: nil, **members)
        super(**members)
        @fqdn = fqdn
      end

      # Delete this slot if it is inactive and refundable.
      # When you delete a slot, the prepaid account that was used to purchase the slot
      # will be refunded for the remaining time that will not be used.
      # @see GandiV5::Email::Mailbox#delete
      # @see https://api.gandi.net/docs/email#delete-v5-email-slots-domain-slot_id
      # @return [String] The confirmation message from Gandi.
      # @raise [GandiV5::Error] if slot is active.
      # @raise [GandiV5::Error] if slot is not refundable.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def delete
        fail GandiV5::Error, 'slot can\'t be deleted whilst active' if active?
        fail GandiV5::Error, 'slot can\'t be deleted if it\'s not refundable' unless refundable

        _response, data = GandiV5.delete url
        data['message']
      end

      # Requery Gandi for this slot's information.
      # @see https://api.gandi.net/docs/email#get-v5-email-slots-domain-slot_id
      # @return [GandiV5::Email::Slot]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def refresh
        _response, data = GandiV5.get url
        from_gandi data
      end

      # Creates a new slot. You must have slots available before you can create a mailbox.
      # If you have used the two free standard 3GB mailbox slots that are included with the domain,
      # but require more mailboxes on that domain, you must first purchase additional slots.
      # @see https://api.gandi.net/docs/email#post-v5-email-slots-domain
      # @param fqdn [String, #to_s] the fully qualified domain name to add the slot to.
      # @param type [:standard, :premium] Tyhe type of slot to add.
      # @return [String] The confirmation message from Gandi.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.create(fqdn, type = :standard)
        body = {
          mailbox_type: type
        }.to_json

        response, _data = GandiV5.post url(fqdn), body
        fetch fqdn, response.headers[:location].split('/').last
      end

      # Get information for a slot.
      # @see https://api.gandi.net/docs/email#get-v5-email-slots-domain-slot_id
      # @param fqdn [String, #to_s] the fully qualified domain name the slot is on.
      # @param id [String, #to_s] the ID of the slot to fetch.
      # @return [GandiV5::Email::Slot]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.fetch(fqdn, id)
        _response, data = GandiV5.get url(fqdn, id)
        slot = from_gandi data
        slot.instance_eval { @fqdn = fqdn }
        slot
      end

      # List slots for a domain.
      # @see https://api.gandi.net/docs/email#
      # @param fqdn [String, #to_s] the fully qualified domain name to list slots for.
      # @return [Array<GandiV5::Email::Slot>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.list(fqdn)
        _response, data = GandiV5.get url(fqdn)
        data.map { |item| from_gandi item }
            .each { |item| item.instance_eval { @fqdn = fqdn } }
      end

      # Check if the slot is active (in use)
      # @return [Boolean]
      def active?
        status.eql?(:active)
      end

      # Check if the slot is inactive (not in use)
      # @return [Boolean]
      def inactive?
        status.eql?(:inactive)
      end

      # Check if the slot's mailbox_type is :free
      # @return [Boolean]
      def free?
        mailbox_type.eql?(:free)
      end

      # Check if the slot's mailbox_type is :standard
      # @return [Boolean]
      def standard?
        mailbox_type.eql?(:standard)
      end

      # Check if the slot's mailbox_type is :premium
      # @return [Boolean]
      def premium?
        mailbox_type.eql?(:premium)
      end

      private

      def url
        "#{BASE}email/slots/#{CGI.escape fqdn}/#{id}"
      end

      def self.url(fqdn, id = nil)
        "#{BASE}email/slots/#{CGI.escape fqdn}" +
          (id ? "/#{id}" : '')
      end
      private_class_method :url
    end
  end
end
