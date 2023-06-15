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

require "test_helper"
require "webrick"
require "fileutils"
require "google/protobuf/well_known_types"

# Test the Sinatra server for the Cloud Scheduler sample.
describe "Opentelemety exporter for Google Cloud Trace" do
  before :all do
    @project_id = ENV["TRACE_EXPORTER_TEST_PROJECT"] || ENV["GCLOUD_TEST_PROJECT"]
    Google::Cloud.configure do |config|
      config.project_id = @project_id
      config.credentials = ENV["TRACE_EXPORTER_TEST_KEYFILE"] || ENV["GCLOUD_TEST_KEYFILE"]
    end

    @pid = Process.fork do
      exec "bundle", "exec", "ruby", "acceptance/sinatra/sinatra_app.rb"
    end
    # wait for server to start
    sleep 10
    @trace_client = Google::Cloud::Trace::V1::TraceService::Client.new
  end

  after :all do
    Process.kill "KILL", @pid
    Process.wait2 @pid
  end

  it "test_returns_hello_world" do
    uri = URI("http://127.0.0.1:4567")
    start_time = Google::Protobuf::Timestamp.from_time Time.now
    res = Net::HTTP.get uri
    assert_match "Hello !", res
    sleep 10 # wait for trace to be sent
    end_time = Google::Protobuf::Timestamp.from_time Time.now

    assert_trace start_time, end_time
  end
end

def assert_trace start_time, end_time
  result = @trace_client.list_traces project_id: @project_id, start_time: start_time, end_time: end_time
  traces = result.response.traces
  test_span = nil
  parent_span = nil

  traces.each do |trace|
    full_trace = @trace_client.get_trace project_id: @project_id, trace_id: trace.trace_id
    full_trace.spans.each do |span|
      if span.name === "test_span"
        test_span = span
        break
      end
    end

    if test_span
      parent_span = full_trace.spans.find { |span| span.span_id === test_span.parent_span_id }
      break
    end
  end

  assert_child_span test_span
  assert_parent_span parent_span
end

def assert_child_span span
  refute_nil span
  assert_equal span.labels["span_attr"], "span_value"
end

def assert_parent_span span
  refute_nil span
  assert_equal span.kind, :RPC_SERVER
  assert_equal span.name, "GET /"
  assert_equal span.labels["g.co/agent"], "opentelemetry-ruby #{OpenTelemetry::SDK::VERSION};" \
                                          "google-cloud-trace-exporter " \
                                          "#{OpenTelemetry::Exporter::GoogleCloudTrace::VERSION}"
  assert_equal span.labels["/http/client_protocol"], "http"
  assert_equal span.labels["/http/status_code"], "200"
  assert_equal span.labels["http.target"], "/"
  assert_equal span.labels["/http/method"], "GET"
  assert_equal span.labels["/http/host"], "127.0.0.1:4567"
  assert_equal span.labels["/http/route"], "/"
  assert_equal span.labels["/http/user_agent"], "Ruby"
end
