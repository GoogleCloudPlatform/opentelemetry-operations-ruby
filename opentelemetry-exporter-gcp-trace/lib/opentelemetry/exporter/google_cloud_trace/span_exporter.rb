# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# frozen_string_literal: true

require "google/cloud/trace/v2/trace_service"

module Opentelemetry
  module Exporter
    module GoogleCloudTrace
      class SpanExporter
        SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
        FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
        private_constant(:SUCCESS, :FAILURE)

        def initialize project_id: nil,
                       credentials: nil,
                       scope: nil,
                       timeout: nil,
                       endpoint: nil

          p "before intialise"           
          @client = ::Google::Cloud::Trace::V2::TraceService::Client.new do |config|
            config.project_id = project_id if project_id
            config.credentials = credentials if credentials
            config.scope = scope if scope
            config.timeout = timeout if timeout
            config.endpoint = endpoint if endpoint
          end
          p "after initialise"
          @shutdown = false
        end

        # Called to export sampled {OpenTelemetry::SDK::Trace::SpanData} structs.
        #
        # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] span_data the
        #   list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
        #   exported.
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] the result of the export.
        def export(span_data, timeout: nil)
          return FAILURE if @shutdown

          begin
            batch_request = create_batch span_data 
            p "REquest"
            p batch_request
            @client.batch_write_spans batch_request
          rescue => exception
            p "**********************"
            p exception.message
            p exception.backtrace
          end
          
        end

        # Called when {OpenTelemetry::SDK::Trace::TracerProvider#force_flush} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::TracerProvider}
        # object.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        def force_flush(timeout: nil)
          SUCCESS
        end

        # Called when {OpenTelemetry::SDK::Trace::TracerProvider#shutdown} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::TracerProvider}
        # object.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        def shutdown(timeout: nil)
          @shutdown = true
          SUCCESS
        end

        private


        def create_batch(spans)
          begin
            cloud_trace_spans = []
          
          spans.each do |span|
            trace_id = span.hex_trace_id
            span_id = span.hex_span_id
            parent_id = span.hex_parent_span_id
            span_name = "projects/helical-zone-771/traces/#{trace_id}/spans/#{span_id}"
            cloud_trace_spans << Google::Cloud::Trace::V2::Span.new(name: span_name,
                                               span_id: span_id,
                                               parent_span_id: parent_id,
                                               display_name: Google::Cloud::Trace::V2::TruncatableString.new(value:"test_span", truncated_byte_count:0),
                                               start_time:Time.now,
                                               end_time:Time.now)
          end
          
          
          {
            name: "projects/helical-zone-771",
            spans: cloud_trace_spans
          }
          rescue => exception
            p "((((((((((((((((("
            p exception.message
            p exception.backtrace
          end
          
        end

      end
    end
  end
end
