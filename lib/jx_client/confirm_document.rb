# frozen_string_literal: true

require_relative "./operation_base"

class JxClient
  class ConfirmDocument < OperationBase
    def self.from_jx_client(jx_client)
      new(
        operation_name: :confirm_document,
        client: jx_client.client,
        default_options: jx_client.jx_default_options,
        operation_default_options: jx_client.jx_default_confirm_document_options,
        message_id_generate: jx_client.jx_message_id_generate,
        timestamp_generate: jx_client.jx_timestamp_generate,
      )
    end

    def wrap_response(response)
      response.define_singleton_method(:result) do
        body[:confirm_document_response][:confirm_document_result]
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
          senderId: options[:sender_id],
          receiverId: options[:receiver_id],
        },
      }
    end
  end
end
