# frozen_string_literal: true

require_relative "./operation_base"

class JxClient
  class PutDocument < OperationBase
    def self.from_jx_client(jx_client)
      new(
        operation_name: :put_document,
        client: jx_client.client,
        default_options: jx_client.jx_default_options,
        operation_default_options: jx_client.jx_default_put_document_options,
        message_id_generate: jx_client.jx_message_id_generate,
      )
    end

    def call
      response = super
      response.define_singleton_method(:result) do
        body[:put_document_response][:put_document_result]
      end
      response
    end

    def locals(options)
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
  end
end
