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

require "test_helper"

describe OpenTelemetry::Exporter::GoogleCloudTrace::SpanExporter do
  let :config do
    OpenStruct.new(
      project_id: "test_project",
      credentials: "credential",
      scope: "scope",
      timeout: 100,
      endpoint: "endpoint"
    )
  end

  it "creates trace client on initialization" do
    trace_mock = Minitest::Mock.new

    Google::Cloud::Trace::V2::TraceService::Client.stub :new, trace_mock, config do
      OpenTelemetry::Exporter::GoogleCloudTrace::SpanExporter.new project_id: "test_project"
    end

    trace_mock.verify
  end

  it "sends a batch write span call to trace on export and returns success" do
    span = OpenStruct.new(
      hex_trace_id: "trace_id",
      hex_span_id: "span_id",
      hex_parent_span_id: "parent_id",
      name: "test_span",
      start_timestamp: 1_241_251_345_423_543,
      end_timestamp: 13_413_243_214_324,
      attributes: { "http.method": "get", "http.host": "google.com" },
      status: OpenStruct.new(code: OpenTelemetry::Trace::Status::OK, description: "message"),
      events: [OpenStruct.new(
        timestamp: 2_132_144_123_423,
        name: "message",
        attributes: { "http.method": "get", "http.host": "google.com" }
      )],
      kind: OpenTelemetry::Trace::SpanKind::INTERNAL
    )

    trace_mock = Minitest::Mock.new
    trace_mock.expect :batch_write_spans, true do |args|
      assert_equal args[:name], "projects/test_project"
      assert_kind_of Google::Cloud::Trace::V2::Span, args[:spans].first
    end

    Google::Cloud::Trace::V2::TraceService::Client.stub :new, trace_mock, config do
      exporter = OpenTelemetry::Exporter::GoogleCloudTrace::SpanExporter.new project_id: "test_project"
      assert_equal OpenTelemetry::SDK::Trace::Export::SUCCESS, exporter.export([span])
    end

    trace_mock.verify
  end

  it "returns Failure if shutdown on export" do
    trace_mock = Minitest::Mock.new
    Google::Cloud::Trace::V2::TraceService::Client.stub :new, trace_mock, config do
      exporter = OpenTelemetry::Exporter::GoogleCloudTrace::SpanExporter.new project_id: "test_project"
      exporter.shutdown
      assert_equal OpenTelemetry::SDK::Trace::Export::FAILURE, exporter.export([])
    end
  end

  it "returns Failure if export fails" do
    trace_mock = Minitest::Mock.new
    Google::Cloud::Trace::V2::TraceService::Client.stub :new, trace_mock, config do
      exporter = OpenTelemetry::Exporter::GoogleCloudTrace::SpanExporter.new project_id: "test_project"
      assert_equal OpenTelemetry::SDK::Trace::Export::FAILURE, exporter.export([])
    end
  end

  it "marks itself as shutdown and returns success on shutdown" do
    trace_mock = Minitest::Mock.new
    Google::Cloud::Trace::V2::TraceService::Client.stub :new, trace_mock, config do
      exporter = OpenTelemetry::Exporter::GoogleCloudTrace::SpanExporter.new project_id: "test_project"
      assert_equal OpenTelemetry::SDK::Trace::Export::SUCCESS, exporter.shutdown
      assert exporter.send(:shutdown?)
    end
  end
end
