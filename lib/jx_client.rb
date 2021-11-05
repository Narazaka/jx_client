# frozen_string_literal: true

require_relative "jx_client/version"
require "savon"
require "base64"

# JX手順クライアント
class JxClient
  class Error < StandardError; end

  DEFAULT_OPTIONS = {
    env_namespace: :soap,
    convert_request_keys_to: :none,
  }.freeze

  class << self
    # WSDL content
    def wsdl(version:)
      @wsdl ||= {}
      @wsdl[version] ||= File.read(wsdl_path(version: version))
    end

    # WSDL file path
    def wsdl_path(version:)
      File.expand_path("../../wsdl/jx#{version}.wsdl.xml", __FILE__)
    end
  end

  # @param [2004 | 2007] [jx_version]
  def initialize(options = {}, &block)
    @savon_client_options = DEFAULT_OPTIONS.merge(options)
    @jx_version = @savon_client_options.delete(:jx_version) || 2007
    @jx_message_id_generate = @savon_client_options.delete(:jx_message_id_generate)
    @jx_default_options = @savon_client_options.delete(:jx_default_options) || {}
    @jx_default_put_document_options = @savon_client_options.delete(:jx_default_put_document_options) || {}
    @jx_default_get_document_options = @savon_client_options.delete(:jx_default_get_document_options) || {}
    @jx_default_confirm_document_options = @savon_client_options.delete(:jx_default_confirm_document_options) || {}
    @savon_client_block = block
  end

  # @return [Savon::Client]
  def client
    @client ||= Savon.client(client_options, &@savon_client_block)
  end

  def client_options
    if @jx_version
      @savon_client_options.merge(wsdl: wsdl)
    else
      @savon_client_options
    end
  end

  # WSDL content
  # @return [String]
  def wsdl
    @wsdl ||= JxClient.wsdl(version: @jx_version)
  end

  def put_document(options)
    merged_options = merge_put_document_options(options)
    client.call(
      :put_document,
      put_document_locals(merged_options),
    )
  end

  def put_document_locals(options)
    {
      soap_header: {
        From: options[:from],
        To: options[:to],
        MessageId: options[:message_id],
        Timestamp: options[:timestamp],
      },
      message: {
        messageId: options[:message_id],
        data: Base64.strict_encode64(options[:data]),
        senderId: options[:sender_id],
        receiverId: options[:receiver_id],
        formatType: options[:format_type],
        documentType: options[:document_type],
        compressType: options[:compress_type],
      },
    }
  end

  def merge_put_document_options(options)
    with_message_id(@jx_default_options.merge(@jx_default_put_document_options, options))
  end

  def get_document(options)
    merged_options = merge_get_document_options(options)
    client.call(
      :get_document,
      get_document_locals(merged_options),
    )
  end

  def get_document_locals(options)
    soap_header = {
      From: options[:from],
      To: options[:to],
      MessageId: options[:message_id],
      Timestamp: options[:timestamp],
    }
    soap_header[:OptionalFormatType] = options[:optional_format_type] if options[:optional_format_type]
    soap_header[:OptionalDocumentType] = options[:optional_document_type] if options[:optional_document_type]

    {
      soap_header: soap_header,
      message: {
        receiverId: options[:receiver_id],
      },
    }
  end

  def merge_get_document_options(options)
    with_message_id(@jx_default_options.merge(@jx_default_get_document_options, options))
  end

  def confirm_document(options)
    merged_options = merge_confirm_document_options(options)
    client.call(
      :confirm_document,
      confirm_document_locals(merged_options),
    )
  end

  def confirm_document_locals(options)
    {
      soap_header: {
        From: options[:from],
        To: options[:to],
        MessageId: options[:message_id],
        Timestamp: options[:timestamp],
      },
      message: {
        messageId: options[:message_id],
        senderId: options[:sender_id],
        receiverId: options[:receiver_id],
      },
    }
  end

  def merge_confirm_document_options(options)
    with_message_id(@jx_default_options.merge(@jx_default_confirm_document_options, options))
  end

  def with_message_id(options)
    options[:message_id] ||= new_message_id
    options
  end

  def new_message_id
    @jx_message_id_generate.call
  end
end
