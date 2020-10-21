# Toplevel Pubnub module.
# frozen_string_literal: true

module Pubnub
  # Holds GetMemberships functionality
  class GetMemberships < SingleEvent
    include Concurrent::Async
    include Pubnub::Validator::GetMemberships

    def initialize(options, app)
      @event = current_operation
      @telemetry_name = :l_obj
      @uuid = options[:uuid]
      @limit = [options[:limit], 100].min unless options[:limit].nil?
      @sort = options[:sort].join(",") if options[:sort] && !options[:sort].empty?
      @filter = options[:filter] if options[:filter] && !options[:filter].empty?
      @start = options[:start] if options[:start] && !options[:start].empty?
      @end = options[:end] if options[:start] && !options[:end].empty?

      if options[:include]
        include = options[:include]
        @include_count = [0, '0', false].include?(include[:count]) ? "0" : "1" unless include[:count].nil?
        @include_custom = "custom" if !include[:custom].nil? && ![0, '0', false].include?(include[:custom])
        @include_channel_metadata = "channel" if !include[:channel_metadata].nil? && ![0, '0', false].include?(include[:channel_metadata])
        @include_channel_custom = "channel.custom" if !include[:channel_custom].nil? && ![0, '0', false].include?(include[:channel_custom])

        @include = [@include_custom, @include_channel_metadata, @include_channel_custom].reject { |flag| flag.to_s.empty? }
      end

      # Collections by default return number of available entries.
      @include_count = "1" if @include_count.nil?

      super
    end

    private

    def current_operation
      Pubnub::Constants::OPERATION_GET_MEMBERSHIPS
    end

    def parameters(signature = false)
      parameters = super(signature)
      parameters[:limit] = @limit unless @limit.nil?
      parameters[:sort] = @sort unless @sort.nil?
      parameters[:filter] = @filter unless @filter.nil?
      parameters[:start] = @start unless @start.nil?
      parameters[:end] = @end if @end && !@start
      parameters[:count] = @include_count unless @include_count.nil?
      parameters[:include] = @include.sort.join(",") if @include && !@include.empty?

      parameters
    end

    def path
      '/' + [
        'v2',
        'objects',
        @subscribe_key,
        'uuids',
        Formatter.encode(@uuid),
        'channels'
      ].join('/')
    end

    def valid_envelope(parsed_response, req_res_objects)
      Pubnub::Envelope.new(
        event: @event,
        event_options: @given_options,
        timetoken: nil,

        result: {
          code: req_res_objects[:response].code,
          operation: current_operation,
          client_request: req_res_objects[:request],
          server_response: req_res_objects[:response],
          data: parsed_response
        },

        status: {
          code: req_res_objects[:response].code,
          operation: current_operation,
          client_request: req_res_objects[:request],
          server_response: req_res_objects[:response],
          data: nil,
          category: Pubnub::Constants::STATUS_ACK,
          error: false,
          auto_retried: false,

          current_timetoken: nil,
          last_timetoken: nil,
          subscribed_channels: nil,
          subscribed_channel_groups: nil,

          config: get_config
        }
      )
    end
  end
end
