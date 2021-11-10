# frozen_string_literal: true

require_relative "jx_client/version"
require_relative "jx_client/put_document"
require_relative "jx_client/get_document"
require_relative "jx_client/confirm_document"
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
    # @param [2004 | 2007] version
    def wsdl(version:)
      @wsdl ||= {}
      @wsdl[version] ||= File.read(wsdl_path(version: version))
    end

    # WSDL file path
    # @param [2004 | 2007] version
    def wsdl_path(version:)
      File.expand_path("../../wsdl/jx#{version}.wsdl.xml", __FILE__)
    end
  end

  attr_reader :jx_version,
    :jx_default_options,
    :jx_default_put_document_options,
    :jx_default_get_document_options,
    :jx_default_confirm_document_options,
    :jx_message_id_generate,
    :jx_timestamp_generate

  # @param options [Hash]
  # @option options [2004 | 2007] :jx_version JX手順のバージョン
  # @option options [Proc | Boolean] :jx_message_id_generate メッセージID生成 (true: デフォルト, false: 無効, Proc: カスタム生成)
  # @option options [Proc | Boolean] :jx_timestamp_generate timestamp生成 (true: デフォルト, false: 無効, Proc: カスタム生成)
  # @option options [Hash] :jx_default_options デフォルトオプション
  # @option options [Hash] :jx_default_put_document_options PutDocumentのデフォルトオプション
  # @option options [Hash] :jx_default_get_document_options GetDocumentのデフォルトオプション
  # @option options [Hash] :jx_default_confirm_document_options ConfirmDocumentのデフォルトオプション
  # @yield [client] Savon.client(&block)
  def initialize(options = {}, &block)
    @savon_client_options = DEFAULT_OPTIONS.merge(options)
    @jx_version = @savon_client_options.delete(:jx_version) || 2007
    @jx_message_id_generate = @savon_client_options.delete(:jx_message_id_generate)
    @jx_timestamp_generate = @savon_client_options.delete(:jx_timestamp_generate)
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

  # @return [Hash] Savon.clientのオプション
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

  # @return [JxClient::PutDocument]
  # @yield [operation]
  # @yieldparam operation [JxClient::PutDocument]
  def put_document
    PutDocument.from_jx_client(self).tap do |operation|
      return yield operation if block_given?
    end
  end

  # @return [JxClient::GetDocument]
  # @yield [operation]
  # @yieldparam operation [JxClient::GetDocument]
  def get_document # rubocop:disable Naming/AccessorMethodName
    GetDocument.from_jx_client(self).tap do |operation|
      return yield operation if block_given?
    end
  end

  # @return [JxClient::ConfirmDocument]
  # @yield [operation]
  # @yieldparam operation [JxClient::ConfirmDocument]
  def confirm_document
    ConfirmDocument.from_jx_client(self).tap do |operation|
      return yield operation if block_given?
    end
  end
end
