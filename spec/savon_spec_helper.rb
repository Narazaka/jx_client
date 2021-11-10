# frozen_string_literal: true

require "savon/mock/spec_helper"

module Savon
  class MockExpectation
    module SavonMockPatch
      def with(locals)
        @expected[:message] = locals[:message]
        @expected[:soap_header] = locals[:soap_header]
        self
      end

      def actual(operation_name, builder, globals, locals)
        @actual = {
          operation_name: operation_name,
          message: locals[:message],
          soap_header: locals[:soap_header],
        }
      end

      def verify!
        unless @actual
          raise ExpectationError, "Expected a request to the #{@expected[:operation_name].inspect} operation, " \
            "but no request was executed."
        end

        verify_operation_name!
        verify_message!
        verify_soap_header!
      end

      def verify_soap_header!
        return if @expected[:soap_header].eql?(:any)
        unless equals_except_any(@expected[:soap_header], @actual[:soap_header])
          expected_message = "  with this soap_header: #{@expected[:soap_header].inspect}" if @expected[:soap_header]
          expected_message ||= "  with no soap_header."

          actual_message = "  with this soap_header: #{@actual[:soap_header].inspect}" if @actual[:soap_header]
          actual_message ||= "  with no soap_header."

          raise Savon::ExpectationError,
            "Expected a request to the #{@expected[:operation_name].inspect} operation\n#{expected_message}\n" \
              "Received a request to the #{@actual[:operation_name].inspect} operation\n#{actual_message}"
        end
      end
    end
  end
end

module Savon
  class SavonMockExpectation
    prepend Savon::MockExpectation::SavonMockPatch
  end
end
