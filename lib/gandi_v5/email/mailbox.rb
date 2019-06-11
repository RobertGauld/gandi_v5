# frozen_string_literal: true

require_relative 'mailbox/responder'

class GandiV5
  class Email
    # A mailbox that lives within a domain.
    # @!attribute [r] address
    #   @return [String] full email address.
    # @!attribute [r] fqdn
    #   @return [String] domain name.
    # @!attribute [r] uuid
    #   @return [String]
    # @!attribute [r] login
    #   @return [String] mailbox login.
    # @!attribute [r] type
    #   @return [:standard, :premium, :free]
    # @!attribute [r] quota_used
    #   @return [Integer]
    # @!attribute [r] aliases
    #   @return [nil, Array<String>] mailbox alias list.
    #     A local-part (what comes before the "@") of an email address. It can contain a wildcard
    #     "*" before or after at least two characters to redirect everything thats matches the
    #     local-part pattern.
    # @!attribute [r] fallback_email
    #   @return [nil, String] fallback email addresse.
    # @!attribute [r] responder
    #   @return [nil, GandiV5::Email::Mailbox::Responder]
    class Mailbox
      include GandiV5::Data

      TYPES = %i[standard premium free].freeze
      QUOTAS = {
        free: 3 * 1024**3,
        standard: 3 * 1024**3,
        premium: 50 * 1024**3
      }.freeze

      members :address, :login, :quota_used, :aliases, :fallback_email
      member :type, gandi_key: 'mailbox_type', converter: GandiV5::Data::Converter::Symbol
      member :uuid, gandi_key: 'id'
      member :fqdn, gandi_key: 'domain'
      member :responder, converter: GandiV5::Email::Mailbox::Responder

      alias mailbox_uuid uuid

      # Create a new GandiV5::Email::Mailbox
      # @param members [Hash<Symbol => Object>]
      # @return [GandiV5::Email::Slot]
      def initialize(**members)
        super(**members)
        responder.instance_exec(self) { |mb| @mailbox = mb } if responder?
      end

      # Delete the mailbox and it's contents.
      # If you delete a mailbox for which you have purchased a slot,
      # this action frees the slot so it once again becomes available
      # for use with a new mailbox, or for deletion.
      # @see https://api.gandi.net/docs/email#delete-v5-email-mailboxes-domain-mailbox_id
      # @return [String] The confirmation message from Gandi.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def delete
        _response, data = GandiV5.delete url
        data['message']
      end

      # Purge the contents of the mailbox.
      # @see https://api.gandi.net/docs/email#delete-v5-email-mailboxes-domain-mailbox_id-contents
      # @return [String] The confirmation message from Gandi.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def purge
        _response, data = GandiV5.delete "#{url}/contents"
        data['message']
      end

      # Requery Gandi fo this mailbox's information.
      # @return [GandiV5::Email::Mailbox]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def refresh
        _response, data = GandiV5.get url
        from_gandi data
        responder.instance_exec(self) { |mb| @mailbox = mb } if responder?
        self
      end

      # Update the mailbox's settings.
      # @see https://api.gandi.net/docs/email#patch-v5-email-mailboxes-domain-mailbox_id
      # @param login [String, #to_s] the login name (and first part of email address).
      # @param password [String, #to_s] the password to use.
      # @param aliases [Array<String, #to_s>] any alternative email address to be used.
      # @param responder [Hash, GandiV5::Mailbox::Responder, #to_gandi, #to_h]
      #   auto responder settings.
      # @return [String] The confirmation message from Gandi.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def update(**body)
        return 'Nothing to update.' if body.empty?

        check_password body[:password] if body.key?(:password)

        body[:password] = crypt_password(body[:password]) if body.key?(:password)
        if (responder = body[:responder])
          body[:responder] = responder.respond_to?(:to_gandi) ? responder.to_gandi : responder.to_h
        end

        _response, data = GandiV5.patch url, body.to_json
        refresh
        data['message']
      end

      # Create a new mailbox.
      # Note that before you can create a mailbox, you must have a slot available.
      # @see https://api.gandi.net/docs/email#post-v5-email-mailboxes-domain
      # @param fqdn [String, #to_s] the fully qualified domain name for the mailbox.
      # @param login [String, #to_s] the login name (and first part of email address).
      # @param password [String, #to_s] the password to use.
      # @param aliases [Array<String, #to_s>] any alternative email address to be used.
      # @param type [:standard, :premium] the type of mailbox slot to use.
      # @return [GandiV5::Email::Mailbox] The created mailbox.
      # @raise [GandiV5::Error] if no slots are available.
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.create(fqdn, login, password, aliases: [], type: :standard)
        fail ArgumentError, "#{type.inspect} is not a valid type" unless TYPES.include?(type)
        if GandiV5::Email::Slot.list.none? { |slot| slot.mailbox_type == type && slot.inactive? }
          fail GandiV5::Error, "no available #{type} slots"
        end

        check_password password

        body = {
          mailbox_type: type,
          login: login,
          password: crypt_password(password),
          aliases: aliases.push
        }.to_json

        response, _data = GandiV5.post url(fqdn), body
        fetch fqdn, response.headers[:location].split('/').last
      end

      # Get information for a mailbox.
      # @see https://api.gandi.net/docs/email#get-v5-email-mailboxes-domain-mailbox_id
      # @param fqdn [String, #to_s] the fully qualified domain name for the mailbox.
      # @param uuid [String, #to_s] unique identifier of the mailbox.
      # @return [GandiV5::Email::Mailbox]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.fetch(fqdn, uuid)
        _response, data = GandiV5.get url(fqdn, uuid)
        from_gandi data
      end

      # List mailboxes for a domain.
      # @see https://api.gandi.net/docs/email#get-v5-email-mailboxes-domain
      # @param fqdn [String, #to_s] the fully qualified domain name for the mailboxes.
      # @param page [Integer, #each<Integer>] which page(s) of results to get.
      #   If page is not provided keep querying until an empty list is returned.
      #   If page responds to .each then iterate until an empty list is returned.
      # @param per_page [Integer, #to_s] (optional default 100) how many results ot get per page.
      # @param sort_by [#to_s] (optional default "login")
      #   how to sort the results ("login", "-login").
      # @param login [String] (optional) filter the list by login (pattern)
      #   e.g. ("alice" "*lice", "alic*").
      # @return [Array<GandiV5::Email::Mailbox>]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.list(fqdn, page: (1..), **params)
        page = [page.to_i] unless page.respond_to?(:each)

        params['~login'] = params.delete(:login)
        params.reject! { |_k, v| v.nil? }

        mailboxes = []
        page.each do |page_number|
          _response, data = GandiV5.get url(fqdn), params: params.merge(page: page_number)
          break if data.empty?

          mailboxes += data.map { |mailbox| from_gandi mailbox }
          break if data.count < params.fetch(:per_page, 100)
        end
        mailboxes
      end

      # Get the quota for this type of mailbox.
      # @return [Integer] bytes.
      def quota
        QUOTAS[type]
      end

      # Get the quota usage for this mailbox.
      # @return [Float] fraction of quota used (typically between 0.0 and 1.0)
      def quota_usage
        quota_used.to_f / quota
      end

      # Returns the string representation of the mailbox.
      # Includes the type, address, quota usage, activeness of responder (if present)
      # and aliases (if present).
      # @return [String]
      def to_s
        s = "[#{type}] #{address} (#{quota_used}/#{quota} (#{(quota_usage * 100).round}%))"
        s += " with #{responder.active? ? 'active' : 'inactive'} responder" if responder
        s += " aka: #{aliases.join(', ')}" if aliases&.any?
        s
      end

      private

      # rubocop:disable Style/GuardClause
      def self.check_password(password)
        if !(9..200).cover?(password.length)
          fail ArgumentError, 'password must be between 9 and 200 characters'
        elsif password.count('A-Z') < 1
          fail ArgumentError, 'password must contain at least one upper case character'
        elsif password.count('0-9') < 3
          fail ArgumentError, 'password must contain at least three numbers'
        elsif password.count('^a-z^A-Z^0-9') < 1
          fail ArgumentError, 'password must contain at least one special character'
        end
      end
      private_class_method :check_password
      # rubocop:enable Style/GuardClause

      def check_password(password)
        self.class.send :check_password, password
      end

      def url
        "#{BASE}email/mailboxes/#{CGI.escape fqdn}/#{CGI.escape uuid}"
      end

      def self.url(fqdn, uuid = nil)
        "#{BASE}email/mailboxes/#{CGI.escape fqdn}" +
          (uuid ? "/#{CGI.escape uuid}" : '')
      end
      private_class_method :url

      def self.crypt_password(password)
        # You can also send a hashed password in sha512-crypt ie: {SHA512-CRYPT}$6$xxxx$yyyy
        salt = SecureRandom.random_number(36**8).to_s(36)
        password.crypt('$6$' + salt)
      end
      private_class_method :crypt_password

      def crypt_password(password)
        self.class.send :crypt_password, password
      end
    end
  end
end
