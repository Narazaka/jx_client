# frozen_string_literal: true

require "test_helper"

class JxClientTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil(::JxClient::VERSION)
  end

  def test_wsdl_version
    assert_includes(JxClient.wsdl(version: 2004), "SOAP-RPC メッセージ転送サービス")
    assert_includes(JxClient.wsdl(version: 2007), "JX 手順メッセージ転送サービス")
  end

  def test_initialize_savon
    assert_equal(JxClient.wsdl(version: 2007), JxClient.new(jx_version: 2007).client.wsdl.document)
  end

  def test_message_id
    assert_equal("aaaa", JxClient.new(jx_message_id_generate: -> { "aaaa" }).new_message_id)
  end

  def test_default_options
    assert_equal({ from: "1234", to: "5678", message_id: "id" },
      JxClient.new(
        jx_version: 2007,
        jx_message_id_generate: -> { "id" },
        jx_default_options: { from: "1234" }
      ).merge_put_document_options(to: "5678"))
  end

  def test_specific_default_options
    assert_equal({ from: "1234", to: "5678", sender_id: "90", message_id: "id" },
      JxClient.new(
        jx_version: 2007,
        jx_message_id_generate: -> { "id" },
        jx_default_options: { from: "1234" },
        jx_default_put_document_options: { sender_id: "90" }
      ).merge_put_document_options(to: "5678"))
    assert_equal({ from: "1234", to: "5678", sender_id: "90", message_id: "id" },
      JxClient.new(
        jx_version: 2007,
        jx_message_id_generate: -> { "id" },
        jx_default_options: { from: "1234" },
        jx_default_get_document_options: { sender_id: "90" }
      ).merge_get_document_options(to: "5678"))
    assert_equal({ from: "1234", to: "5678", sender_id: "90", message_id: "id" },
      JxClient.new(
        jx_version: 2007,
        jx_message_id_generate: -> { "id" },
        jx_default_options: { from: "1234" },
        jx_default_confirm_document_options: { sender_id: "90" }
      ).merge_confirm_document_options(to: "5678"))
  end
end
