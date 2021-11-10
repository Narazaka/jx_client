# frozen_string_literal: true

require "base64"

class JxClient
  GET_DOCUMENT_PROPERTIES = [
    :get_document_result,
    :message_id,
    :data,
    :sender_id,
    :receiver_id,
    :format_type,
    :document_type,
  ].freeze

  GetDocumentResult = Struct.new(
    *GET_DOCUMENT_PROPERTIES,
    keyword_init: true
  ) do
    def initialize(**args)
      super(**args.slice(*GET_DOCUMENT_PROPERTIES))
    end

    # decoded data
    # @return [String]
    def decoded_data
      @decoded_data ||= Base64.decode64(data)
    end
  end
end
