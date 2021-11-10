# frozen_string_literal: true

require_relative "./operation_base"
require_relative "./get_document_result"

class JxClient
  class GetDocument < OperationBase
    def self.from_jx_client(jx_client)
      new(
        operation_name: :get_document,
        client: jx_client.client,
        default_options: jx_client.jx_default_options,
        operation_default_options: jx_client.jx_default_get_document_options,
        message_id_generate: jx_client.jx_message_id_generate,
      )
    end

    def call
      response = super
      response.define_singleton_method(:result) do
        @result ||= GetDocumentResult.new(**body[:get_document_response])
      end
      response
    end

    def locals(options)
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
  end
end
