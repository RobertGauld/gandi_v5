# frozen_string_literal: true

class GandiV5
  class Domain
    # Automatic renewal information for a domain.
    # @!attribute [r] dates
    #   @return [nil, Array<Time>]
    # @!attribute [r] duration
    #   @return [nil, Integer]
    # @!attribute [r] enabled
    #   @return [nil, Boolean]
    # @!attribute [r] org_id
    #   @return [nil, String]
    class AutoRenew
      include GandiV5::Data

      attr_accessor :domain

      members :duration, :enabled, :org_id
      member :dates, converter: GandiV5::Data::Converter::Time, array: true

      # Disable auto renewal for the associated domain.
      # @return [String] The confirmation message from Gandi.
      # @raise [GandiV5::Error::GandiError::GandiError] if Gandi returns an error.
      def disable
        body = { enabled: false }.to_json
        _response, data = GandiV5.patch url, body
        self.enabled = false
        data['message']
      end

      # Disable auto renewal for the associated domain.
      # @param duration [Integer, #to_s] how long to renew for.
      # @param org_id [String, #to_s] UUID of the organisation that should pay.
      # @return [String] The confirmation message from Gandi.
      # @raise [ArgumentError] if duration is invalid (not 1 to 9 (inclusive)).
      # @raise [ArgumentError] if org_id is not passed and not set for this domain.
      # @raise [GandiV5::Error::GandiError::GandiError] if Gandi returns an error.
      def enable(duration: self.duration || 1, org_id: self.org_id)
        fail ArgumentError, 'duration can not be less than 1' if duration < 1
        fail ArgumentError, 'duration can not be more than 9' if duration > 9
        fail ArgumentError, 'org_id is required' if org_id.nil?

        body = {
          enabled: true,
          duration: duration,
          org_id: org_id
        }.to_json

        _response, data = GandiV5.patch url, body
        self.enabled = true
        self.duration = duration
        self.org_id = org_id
        data['message']
      end

      private

      def url
        "#{BASE}domain/domains/#{CGI.escape domain.fqdn}/autorenew"
      end
    end
  end
end
