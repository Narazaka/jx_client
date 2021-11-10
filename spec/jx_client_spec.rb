# frozen_string_literal: true

require_relative "./savon_spec_helper"

RSpec.describe(JxClient) do
  include Savon::SpecHelper

  before(:all) { savon.mock! }

  after(:all) { savon.unmock! }

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
      expect(JxClient.new(jx_message_id_generate: -> { "aaaa" }).put_document.new_message_id).to(eq("aaaa"))
    end
  end

  describe "jx_default_options" do
    it "applyed" do
      expect(
        JxClient.new(
          jx_version: 2007,
          jx_message_id_generate: -> { "id" },
          jx_default_options: { from: "1234" }
        ).put_document.options(to: "5678").sent_options
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
        ).put_document.options(to: "5678").sent_options
      ).to(eq({ from: "1234", to: "5678", sender_id: "90", message_id: "id" }))
    end

    it "get_document applyed" do
      expect(
        JxClient.new(
          jx_version: 2007,
          jx_message_id_generate: -> { "id" },
          jx_default_options: { from: "1234" },
          jx_default_get_document_options: { sender_id: "90" }
        ).get_document.options(to: "5678").sent_options
      ).to(eq({ from: "1234", to: "5678", sender_id: "90", message_id: "id" }))
    end

    it "confirm_document applyed" do
      expect(
        JxClient.new(
          jx_version: 2007,
          jx_message_id_generate: -> { "id" },
          jx_default_options: { from: "1234" },
          jx_default_confirm_document_options: { sender_id: "90" }
        ).confirm_document.options(to: "5678").sent_options
      ).to(eq({ from: "1234", to: "5678", sender_id: "90", message_id: "id" }))
    end
  end

  describe "SOAP call" do
    let(:soap_fault) { File.read("spec/fixtures/soap_fault.xml") }
    let(:now) { Time.now }
    let(:jx_message_id_generate) { -> { "id" } }

    describe "#put_document" do
      let(:response_document) { File.read("spec/fixtures/put_document_response.xml") }
      let(:expected_options) do
        {
          message: {
            messageId: "id",
            data: "ZGF0YQ==",
            senderId: "789",
            receiverId: "012",
            formatType: "myformat",
            documentType: "mytype",
            compressType: "none",
          }, soap_header: {
            From: "123",
            To: "456",
            MessageId: "id",
            Timestamp: now,
          },
        }
      end
      let(:options) do
        {
          from: "123",
          to: "456",
          timestamp: now,
          data: "data",
          sender_id: "789",
          receiver_id: "012",
          format_type: "myformat",
          document_type: "mytype",
          compress_type: "none",
        }
      end

      it "正常系" do
        # set up an expectation
        savon.expects(:put_document).with(expected_options).returns(response_document)

        # call the service
        client = JxClient.new(jx_version: 2007, jx_message_id_generate: jx_message_id_generate)
        response = client.put_document.options(options).call.response

        expect(response).to(be_success)
        expect(response.result).to(eq(true))
      end

      it "正常系 with block" do
        # set up an expectation
        savon.expects(:put_document).with(expected_options).returns(response_document)

        # call the service
        client = JxClient.new(jx_version: 2007, jx_message_id_generate: jx_message_id_generate)
        response = client.put_document do |op|
          op.options(options)
          expect(op.sent_locals).to(eq(expected_options))
          op.call
          op.response
        end

        expect(response).to(be_success)
        expect(response.result).to(eq(true))
      end

      it "異常系" do
        # set up an expectation
        savon.expects(:put_document).with(expected_options).returns({ code: 500, headers: {}, body: soap_fault })

        # call the service
        client = JxClient.new(jx_version: 2007, jx_message_id_generate: jx_message_id_generate)
        expect(-> { client.put_document.options(options).call }).to(raise_error(Savon::SOAPFault))
      end
    end

    describe "#get_document" do
      let(:response_document) { File.read("spec/fixtures/get_document_response.xml") }
      let(:expected_options) do
        {
          message: {
            receiverId: "012",
          }, soap_header: {
            From: "123",
            To: "456",
            MessageId: "id",
            Timestamp: now,
          },
        }
      end
      let(:options) do
        {
          from: "123",
          to: "456",
          timestamp: now,
          receiver_id: "012",
        }
      end

      it "正常系" do
        # set up an expectation
        savon.expects(:get_document).with(expected_options).returns(response_document)

        # call the service
        client = JxClient.new(jx_version: 2007, jx_message_id_generate: jx_message_id_generate)
        response = client.get_document.options(options).call.response

        expect(response).to(be_success)
        expect(response.result.decoded_data).to(eq("data"))
      end

      it "正常系 with block" do
        # set up an expectation
        savon.expects(:get_document).with(expected_options).returns(response_document)

        # call the service
        client = JxClient.new(jx_version: 2007, jx_message_id_generate: jx_message_id_generate)
        response = client.get_document do |op|
          op.options(options)
          expect(op.sent_locals).to(eq(expected_options))
          op.call
          op.response
        end

        expect(response).to(be_success)
        expect(response.result.decoded_data).to(eq("data"))
      end

      it "異常系" do
        # set up an expectation
        savon.expects(:get_document).with(expected_options).returns({ code: 500, headers: {}, body: soap_fault })

        # call the service
        client = JxClient.new(jx_version: 2007, jx_message_id_generate: jx_message_id_generate)
        expect(-> { client.get_document.options(options).call }).to(raise_error(Savon::SOAPFault))
      end
    end

    describe "#confirm_document" do
      let(:response_document) { File.read("spec/fixtures/confirm_document_response.xml") }
      let(:expected_options) do
        {
          soap_header: {
            From: "123",
            To: "456",
            MessageId: "id",
            Timestamp: now,
          },
          message: {
            messageId: "id",
            senderId: "789",
            receiverId: "012",
          },
        }
      end
      let(:options) do
        {
          from: "123",
          to: "456",
          timestamp: now,
          receiver_id: "012",
          sender_id: "789",
        }
      end

      it "正常系" do
        # set up an expectation
        savon.expects(:confirm_document).with(expected_options).returns(response_document)

        # call the service
        client = JxClient.new(jx_version: 2007, jx_message_id_generate: jx_message_id_generate)
        response = client.confirm_document.options(options).call.response

        expect(response).to(be_success)
        expect(response.result).to(eq(true))
      end

      it "正常系 with block" do
        # set up an expectation
        savon.expects(:confirm_document).with(expected_options).returns(response_document)

        # call the service
        client = JxClient.new(jx_version: 2007, jx_message_id_generate: jx_message_id_generate)
        response = client.confirm_document do |op|
          op.options(options)
          expect(op.sent_locals).to(eq(expected_options))
          op.call
          op.response
        end

        expect(response).to(be_success)
        expect(response.result).to(eq(true))
      end

      it "異常系" do
        # set up an expectation
        savon.expects(:confirm_document).with(expected_options).returns({ code: 500, headers: {}, body: soap_fault })

        # call the service
        client = JxClient.new(jx_version: 2007, jx_message_id_generate: jx_message_id_generate)
        expect(-> { client.confirm_document.options(options).call }).to(raise_error(Savon::SOAPFault))
      end
    end
  end
end
