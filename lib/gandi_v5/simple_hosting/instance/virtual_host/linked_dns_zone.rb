# frozen_string_literal: true

class GandiV5
  class SimpleHosting
    class Instance
      class VirtualHost
        # A DNS Zone linked to a virtual host on a simple hosting instance.
        # @!attribute [r] allow_zone_alteration
        #   @return [Boolean]
        # @!attribute [r] cname
        #   @return [String]
        # @!attribute [r] domain
        #   @return [String]
        # @!attribute [r] ipv4
        #   @return [String]
        # @!attribute [r] ipv6
        #   @return [String]
        # @!attribute [r] is_alterable
        #   @return [Boolean]
        # @!attribute [r] is_root
        #   @return [Boolean]
        # @!attribute [r] key
        #   @return [String]
        # @!attribute [r] txt
        #   @return [String]
        # @!attribute [r] last_checked_at
        #   @return [Time]
        # @!attribute [r] status
        #   @return [Symbol] :altered, :livedns_conflict, :livedns_done, :livedns_error, :unknown
        class LinkedDnsZone
          include GandiV5::Data

          members :allow_alteration, :is_alterable, :last_checked_at,
                  :cname, :domain, :is_root, :ipv4, :ipv6, :key, :txt

          member(
            :status,
            gandi_key: 'last_checked_status',
            converter: GandiV5::Data::Converter::Symbol
          )

          # Check if the linked zone is currently in an altered state
          # @return [Boolean]
          def altered?
            status == :altered
          end

          # Check if the linked zone is currently in a conflicted state
          # @return [Boolean]
          def livedns_conflict?
            status == :livedns_conflict
          end

          # Check if the linked zone has been updated
          # @return [Boolean]
          def livedns_done?
            status == :livedns_done
          end

          # Check if the linked zone had an error updating
          # @return [Boolean]
          def livedns_error?
            status == :livedns_error
          end

          # Check if the linked zone is in an unknown state
          # @return [Boolean]
          def unknown?
            status == :unknown
          end
        end
      end
    end
  end
end
