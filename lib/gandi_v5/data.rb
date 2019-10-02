# frozen_string_literal: true

class GandiV5
  # Addin providing a DSL to manage declaring attributes and how to map
  # and convert to/from Gandi's fields.
  module Data
    # api private
    # Add contents of ClassMethods to the Class which includes this module.
    # @param host_class [Class] the class which included us.
    def self.included(host_class)
      host_class.extend ClassMethods

      host_class.instance_exec do
        @data_members ||= Set.new
        @data_converters ||= {}
        @data_map_key_to_member ||= {}
        @data_map_member_to_key ||= {}
      end
    end

    # Get a hash representation of the object.
    # @return [Hash<Symbol => Object>]
    def to_h
      Hash[
        data_members.map do |key|
          value = send(key)
          next [key, value] if value.nil?

          if value.is_a?(Enumerable)
            value = to_h_transform_enumerable(value)
          elsif value.respond_to?(:to_h)
            value = value.to_h
          end
          [key, value]
        end
      ]
    end

    # Get a hash representation of this object suitable for passing back to Gandi.
    # @return [Hash<String => nil, Boolean, String, Numeric, Hash, Array>]
    def to_gandi
      data = {}

      data_members.each do |member|
        key = data_member_to_gandi_key(member)
        value = send(member)
        converter = data_converter_for(member)

        data[key] = if value.respond_to?(:to_gandi)
                      value.to_gandi
                    elsif converter && !value.nil?
                      converter.to_gandi(value)
                    else
                      value
                    end
      end

      data
    end

    # Get an array of values from particular members.
    # @param keys [Array<Symbol, String>] e.g. :fqdn, "contacts.owner"
    # @return [Array<Object>]
    # rubocop:disable Style/IfUnlessModifier
    def values_at(*keys)
      keys.map(&:to_s).map do |key|
        key, sub_key = key.split('.', 2)
        unless data_member?(key.to_sym)
          fail ArgumentError, "#{key} is not a member."
        end

        sub_key.empty? ? send(key) : send(key).values_at(sub_key)
      end
    end
    # rubocop:enable Style/IfUnlessModifier

    # Update instance with data from Gandi.
    # @param data [Hash]
    # @return [self]
    def from_gandi(data)
      translate_gandi(data).each do |key, value|
        next unless data_member?(key.to_sym)

        send "#{key}=", value
      end
      self
    end

    # Create a new instance from any passed members.
    # @param members [Hash<Symbol => Object>]
    # rubocop:disable Style/IfUnlessModifier
    def initialize(**members)
      members.each do |member, value|
        unless data_member?(member)
          fail ArgumentError, "unknown keyword: #{member}"
        end

        send "#{member}=", value
      end
    end
    # rubocop:enable Style/IfUnlessModifier

    private

    def data_members
      self.class.send(:data_members)
    end

    def data_member?(member)
      self.class.send(:data_member?, member)
    end

    def data_gandi_key_to_member(gandi_key)
      self.class.send(:data_gandi_key_to_member, gandi_key)
    end

    def data_member_to_gandi_key(member)
      self.class.send(:data_member_to_gandi_key, member)
    end

    def data_converter_for(member)
      self.class.send(:data_converter_for, member)
    end

    def data_converter_for?(member)
      self.class.send(:data_converter_for?, member)
    end

    def translate_gandi(data)
      self.class.send(:translate_gandi, data)
    end

    def to_h_transform_enumerable(value)
      method = :transform_keys if value.respond_to?(:transform_keys)
      method ||= :map if value.respond_to?(:map)

      value.send(method) do |v|
        next to_h_transform_value(v) if v.is_a?(Enumerable)

        v.respond_to?(:to_h) ? v.to_h : v
      end
    end

    # Class methods to add to classes which include this module.
    module ClassMethods
      # Create a new instance with data from Gandi.
      # @param data [Hash]
      def from_gandi(data)
        return nil if data.nil?

        new(
          translate_gandi(data).transform_keys(&:to_sym)
                               .select { |k, _v| data_member?(k) }
        )
      end

      private

      def members(*names)
        names.each do |name|
          member name
        end
      end

      def member(name, gandi_key: name.to_s, converter: nil, array: false)
        @data_members.add name
        @data_map_key_to_member[gandi_key] = name
        @data_map_member_to_key[name] = gandi_key
        convert_member_with(name, gandi_key, converter, array) if converter

        define_method name do
          instance_variable_get "@#{name}"
        end

        define_method "#{name}?" do
          !instance_variable_get("@#{name}").nil?
        end

        define_method "#{name}=" do |value|
          instance_variable_set("@#{name}", value)
        end

        private "#{name}="
      end

      # @api private
      def data_members
        instance_variable_get(:@data_members).to_a
      end

      # @api private
      def data_member?(member)
        instance_variable_get(:@data_members).include?(member)
      end

      # @api private
      def data_gandi_key_to_member(gandi_key)
        instance_variable_get(:@data_map_key_to_member).fetch(gandi_key)
      end

      # @api private
      def data_member_to_gandi_key(member)
        instance_variable_get(:@data_map_member_to_key).fetch(member)
      end

      # @api private
      def data_converter_for(member)
        instance_variable_get(:@data_converters)[member]
      end

      # @api private
      def data_converter_for?(member)
        instance_variable_get(:@data_converters).key?(member)
      end

      # @api private
      def convert_member_with(name, gandi_key, converter, array)
        converter = GandiV5::Data::Converter::ArrayOf.new(converter) if array
        @data_converters[name] = converter
        @data_converters[gandi_key] = converter
      end

      def translate_gandi(data)
        return nil unless data.is_a?(Hash)

        data = data.clone

        # Do name mapping
        @data_map_key_to_member.each do |key, member|
          data[member] = data.delete(key) if data.key?(key)
        end

        # Do value conversions
        data.each do |key, value|
          converter = data_converter_for(key)
          data[key] = converter.from_gandi(value) if converter
        end

        data
      end
    end
  end
end
