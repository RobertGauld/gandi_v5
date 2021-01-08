# frozen_string_literal: true

class GandiV5
  class Template
    # The current state of a template dispatch.
    # @!attribute [r] uuid
    #   @return [String]
    # @!attribute [r] template_uuid
    #   @return [String, nil]
    # @!attribute [r] template_name
    #   @return [String, nil]
    # @!attribute [r] target_uuid
    #   @return [String]
    # @!attribute [r] attempt
    #   @return [Integer]
    # @!attribute [r] created_at
    #   @return [Time]
    # @!attribute [r] created_by
    #   @return [String] the UUID of the user who applied the template.
    # @!attribute [r] updated_at
    #   @return [Time, nil]
    # @!attribute [r] state
    #   @return [:pending, :running, :done, :error]
    # @!attribute [r] state_message
    #   @return [String, nil]
    # @!attribute [r] task_statuses
    #   @return [Array<Hash{Symbol => Synbol}>]
    #     maps namespace (e.g. :dns_records) to current status (e.g. :done)
    # @!attribute [r] task_history
    #   @return [Array<Hash{:at => Time, :what => Symbol, :status => Symbol, :message => String}>]
    # @!attribute [r] payload
    #   @return [Array<GandiV5::Template::Payload] the settings which will be applied
    #                                              when this template is used.
    class Dispatch
      include GandiV5::Data

      members :attempt, :template_name
      member :uuid, gandi_key: 'id'
      member :template_uuid, gandi_key: 'template_id'
      member :created_at, converter: GandiV5::Data::Converter::Time
      member :created_by, gandi_key: 'sharing_id'
      member :target_uuid, gandi_key: 'target_id'
      member :state_message, gandi_key: 'state_msg'
      member :updated_at, gandi_key: 'task_updated_at', converter: GandiV5::Data::Converter::Time
      member :payload, converter: GandiV5::Template::Payload

      member(
        :state,
        converter: GandiV5::Data::Converter.new(
          from_gandi: lambda { |value|
            values = { 0 => :pending, 10 => :running, 20 => :done, 30 => :error }
            values.fetch(value)
          }
        )
      )

      member(
        :task_statuses,
        gandi_key: 'task_status',
        converter: GandiV5::Data::Converter.new(
          from_gandi: lambda { |hash|
            keys = {
              'dns:records' => :dns_records,
              'domain:mailboxes' => :mailboxes,
              'domain:nameservers' => :name_servers,
              'domain:webredirs' => :web_forwardings
            }
            values = { 0 => :pending, 10 => :running, 20 => :done, 30 => :error }
            hash.transform_keys { |key| keys.fetch(key) }
                .transform_values { |value| values.fetch(value.fetch('status')) }
          }
        )
      )

      member(
        :task_history,
        converter: GandiV5::Data::Converter.new(
          from_gandi: lambda { |array|
            namespace = {
              'dns:records' => :dns_records,
              'domain:mailboxes' => :mailboxes,
              'domain:nameservers' => :name_servers,
              'domain:webredirs' => :web_forwardings
            }
            status = { 0 => :pending, 10 => :running, 20 => :done, 30 => :error }
            array.map do |item|
              {
                at: Time.parse(item.fetch('date')),
                what: namespace.fetch(item.fetch('namespace')),
                status: status.fetch(item.fetch('status')),
                message: item.fetch('message')
              }
            end
          }
        )
      )

      # Get a template dispatch.
      # @see https://api.gandi.net/docs/template/#get-v5-template-dispatch-id
      # @param uuid [String, #to_s] unique identifier of the dispatch.
      # @return [GandiV5::Template::Dispatch]
      # @raise [GandiV5::Error::GandiError] if Gandi returns an error.
      def self.fetch(uuid)
        _response, data = GandiV5.get "#{BASE}template/dispatch/#{CGI.escape uuid}"
        from_gandi data
      end
    end
  end
end
