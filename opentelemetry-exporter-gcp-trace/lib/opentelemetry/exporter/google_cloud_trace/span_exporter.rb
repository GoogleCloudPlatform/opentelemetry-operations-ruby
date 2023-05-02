# frozen_string_literal: true

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


require "google/cloud/trace/v2/trace_service"
require "opentelemetry/exporter/google_cloud_trace/translator"
require "google/cloud/env"

module OpenTelemetry
  module Exporter
    module GoogleCloudTrace
      ##
      # This provides an implementation of span exporter for Google Cloud Trace
      # It will convert the Opentelemetry span data into Clould Trace spans
      # and publish them to the Cloud trace service.
      class SpanExporter
        SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
        FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
        private_constant :SUCCESS, :FAILURE


        ##
        # Creates a new object for google cloud trace 
        # opentelemetry span exporter. It creates client for 
        # Google cloud trace service to be used for publihing span.
        #
        #
        # @param [String] project_id Project identifier for the Trace service
        #   you are connecting to. If not present, the default project for the
        #   credentials is used.
        # @param [String, Hash, Google::Auth::Credentials] credentials The path to
        #   the keyfile as a String, the contents of the keyfile as a Hash, or a
        #   Google::Auth::Credentials object.
        # @param [String, Array<String>] scope The OAuth 2.0 scopes controlling
        #   the set of resources and operations that the connection can access.
        #   See [Using OAuth 2.0 to Access Google
        #   APIs](https://developers.google.com/identity/protocols/OAuth2).
        #
        #   The default scope is:
        #
        #   * `https://www.googleapis.com/auth/trace.append`
        # @param [Numeric] timeout Default timeout to use in requests. Optional.
        # @param [String] endpoint Override of the endpoint host name. Optional.
        #   If the param is nil, uses the default endpoint.
        #
        # @return [OpenTelemetry::Exporter::GoogleCloudTrace::SpanExporter]
        #
        # @example
        #   require 'opentelemetry/sdk'
        #   require 'opentelemetry/instrumentation/all'
        #   require 'opentelemetry/exporter/google_cloud_trace'
        #   OpenTelemetry::SDK.configure do |c|
        #     c.service_name = 'test_app'
        #     c.add_span_processor(
        #          OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
        #            OpenTelemetry::Exporter::GoogleCloudTrace::SpanExporter.new
        #          )
        #        )
        #     c.use_all() # enables all instrumentation!
        #   end
        #
        def initialize project_id: nil,
                       credentials: nil,
                       scope: nil,
                       timeout: nil,
                       endpoint: nil

          @client = ::Google::Cloud::Trace::V2::TraceService::Client.new do |config|
            config.project_id = project_id if project_id
            config.credentials = credentials if credentials
            config.scope = scope if scope
            config.timeout = timeout if timeout
            config.endpoint = endpoint if endpoint
          end
          @project_id = (project_id || default_project_id || credentials&.project_id)
          @project_id = @project_id.to_s
          raise ArgumentError, "project_id is missing" if @project_id.empty?
          @shutdown = false
          @translator = Translator.new @project_id
        end

        # rubocop:disable Lint/UnusedMethodArgument
        # timeout is needed to match Opentelemetry exporter interface
        
        # Called to export sampled {OpenTelemetry::SDK::Trace::SpanData} structs.
        #
        # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] span_data the
        #   list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
        #   exported.
        # @return [Integer] the result of the export.
        def export span_data, timeout: nil
          return FAILURE if @shutdown

          begin
            batch_request = @translator.create_batch span_data
            @client.batch_write_spans batch_request
            SUCCESS
          rescue StandardError
            FAILURE
          end
        end

        # Called when {OpenTelemetry::SDK::Trace::TracerProvider#force_flush} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::TracerProvider}
        # object.
        def force_flush timeout: nil
          SUCCESS
        end

        # Called when {OpenTelemetry::SDK::Trace::TracerProvider#shutdown} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::TracerProvider}
        # object.
        def shutdown timeout: nil
          @shutdown = true
          SUCCESS
        end
        
        # rubocop:enable Lint/UnusedMethodArgument
        
        private

        def default_project_id
          Google::Cloud.env.project_id
        end

        def shutdown?
          @shutdown
        end
      end
    end
  end
end
