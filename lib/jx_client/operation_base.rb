# frozen_string_literal: true

class JxClient
  class OperationBase
    attr_reader :sent_options, :response

    # @param operation_name [Symbol] operation name
    # @param client [Savon::Client] client
    # @param default_options [Hash] default options
    # @param operation_default_options [Hash] operation specific default options
    # @param message_id_generate [Proc | Boolean] message id generator
    # @param timestamp_generate [Proc | Boolean] timestamp generator
    def initialize(
      operation_name:,
      client:,
      default_options: {},
      operation_default_options: {},
      message_id_generate: false,
      timestamp_generate: false
    )
      @operation_name = operation_name
      @client = client
      @default_options = default_options
      @operation_default_options = operation_default_options
      @message_id_generate = message_id_generate == true ? -> { SecureRandom.uuid } : message_id_generate
      @timestamp_generate = timestamp_generate == true ? -> { Time.now.utc.iso8601 } : timestamp_generate
    end

    # @return [Hash] sent locals for savon call
    def sent_locals
      locals(@sent_options)
    end

    # @param options [Hash] options
    # @return [self]
    def options(options)
      @sent_options = merge_options(options)
      self
    end

    # call operation
    def call
      @response = wrap_response(@client.call(@operation_name, sent_locals))
      self
    end

    # merge options, default options and operation specific default options
    def merge_options(options)
      with_generated(@default_options.merge(@operation_default_options, options))
    end

    # @param options [Hash] options
    # @return [Hash] locals for savon call
    def locals(options)
      raise NotImplementedError
    end

    # @param options [Hash] options
    # @return [Hash] options with :message_id
    def with_generated(options)
      options[:message_id] ||= new_message_id
      options[:timestamp] ||= new_timestamp
      options
    end

    # @return [String] new message id
    def new_message_id
      raise "message_id must be included because message ID generation is disabled." unless @message_id_generate
      @message_id_generate.call
    end

    def new_timestamp
      raise "timestamp must be included because timestamp generation is disabled." unless @timestamp_generate
      @timestamp_generate.call
    end

    # wraps response
    def wrap_response(response)
      response
    end
  end
end
