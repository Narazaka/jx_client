# frozen_string_literal: true

require "savon/mock/spec_helper"

RSpec.describe(JxClient) do
  describe "version" do
    it "is defined" do
      expect(JxClient::VERSION).to(be_a(String))
    end
  end

  describe "JxClient.wsdl" do
    it "works with 2004" do
      expect(JxClient.wsdl(version: 2004)).to(be_include("SOAP-RPC メッセージ転送サービス"))
    end

    it "works with 2007" do
      expect(JxClient.wsdl(version: 2007)).to(be_include("JX 手順メッセージ転送サービス"))
    end
  end

  describe "JxClient.new" do
    it "initialize wsdl by jx_version" do
      expect(JxClient.new(jx_version: 2007).client.wsdl.document).to(eq(JxClient.wsdl(version: 2007)))
    end

    it "initialize message id generation" do
      expect(JxClient.new(jx_message_id_generate: -> { "aaaa" }).new_message_id).to(eq("aaaa"))
    end
  end

  describe "jx_default_options" do
    it "applyed" do
      expect(
        JxClient.new(
          jx_version: 2007,
          jx_message_id_generate: -> { "id" },
          jx_default_options: { from: "1234" }
        ).merge_put_document_options(to: "5678")
      ).to(eq({ from: "1234", to: "5678", message_id: "id" }))
    end
  end

  describe "jx_*_default_options" do
    it "put_document applyed" do
      expect(
        JxClient.new(
          jx_version: 2007,
          jx_message_id_generate: -> { "id" },
          jx_default_options: { from: "1234" },
          jx_default_put_document_options: { sender_id: "90" }
        ).merge_put_document_options(to: "5678")
      ).to(eq({ from: "1234", to: "5678", sender_id: "90", message_id: "id" }))
    end

    it "get_document applyed" do
      expect(
        JxClient.new(
          jx_version: 2007,
          jx_message_id_generate: -> { "id" },
          jx_default_options: { from: "1234" },
          jx_default_get_document_options: { sender_id: "90" }
        ).merge_get_document_options(to: "5678")
      ).to(eq({ from: "1234", to: "5678", sender_id: "90", message_id: "id" }))
    end

    it "confirm_document applyed" do
      expect(
        JxClient.new(
          jx_version: 2007,
          jx_message_id_generate: -> { "id" },
          jx_default_options: { from: "1234" },
          jx_default_confirm_document_options: { sender_id: "90" }
        ).merge_confirm_document_options(to: "5678")
      ).to(eq({ from: "1234", to: "5678", sender_id: "90", message_id: "id" }))
    end
  end
end
