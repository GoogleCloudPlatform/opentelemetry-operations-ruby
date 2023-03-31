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

describe Opentelemetry::Exporter::GoogleCloudTrace::Translator do
  let(:translator) { Opentelemetry::Exporter::GoogleCloudTrace::Translator.new "test_project" }

  it "creates truncatable name" do
    truncated_str = translator.send(:create_name, "somename", 4)
    
    assert_kind_of Google::Cloud::Trace::V2::TruncatableString, truncated_str
    assert_equal truncated_str.value, "some"
    assert_equal truncated_str.truncated_byte_count, 4
  end

  it "creates attributes map" do
    attributes = {"http.method": "get", "http.host": "google.com"}
    converted_attr = translator.send(:create_attributes, attributes, 2, true)
    assert_attribute converted_attr, dropped_count: 1
  end

  it "creates time from nanoseconds" do
    time = Time.now
    time_nsec = time.to_i * (10 ** 9) + time.nsec
    
    converted_time = translator.send(:create_time, time_nsec)
    
    assert_time converted_time, time
  end

  it "creates span kind" do
    assert_equal translator.send(:create_span_kind, OpenTelemetry::Trace::SpanKind::INTERNAL), Google::Cloud::Trace::V2::Span::SpanKind::INTERNAL
    assert_equal translator.send(:create_span_kind, OpenTelemetry::Trace::SpanKind::CLIENT), Google::Cloud::Trace::V2::Span::SpanKind::CLIENT
    assert_equal translator.send(:create_span_kind, OpenTelemetry::Trace::SpanKind::SERVER), Google::Cloud::Trace::V2::Span::SpanKind::SERVER
    assert_equal translator.send(:create_span_kind, OpenTelemetry::Trace::SpanKind::PRODUCER), Google::Cloud::Trace::V2::Span::SpanKind::PRODUCER
    assert_equal translator.send(:create_span_kind, OpenTelemetry::Trace::SpanKind::CONSUMER), Google::Cloud::Trace::V2::Span::SpanKind::CONSUMER
    assert_equal translator.send(:create_span_kind, "unknown"), Google::Cloud::Trace::V2::Span::SpanKind::SPAN_KIND_UNSPECIFIED
  end

  it "creates status unknown" do
    status_unknown = OpenStruct.new(code: "", description: "message")
    converted_status = translator.send(:create_status, status_unknown)
    assert_kind_of Google::Rpc::Status, converted_status
    assert_equal converted_status.code, Google::Rpc::Code::UNKNOWN
    assert_equal converted_status.message, status_unknown.description
  end

  it "creates status ok" do
    status_ok = OpenStruct.new(code: OpenTelemetry::Trace::Status::OK, description: "message")
    converted_status = translator.send(:create_status, status_ok)
    assert_kind_of Google::Rpc::Status, converted_status
    assert_equal converted_status.code, Google::Rpc::Code::OK
    assert_equal converted_status.message, status_ok.description
  end

  it "creates status for unset" do
    status_ok = OpenStruct.new(code: OpenTelemetry::Trace::Status::UNSET, description: "message")
    assert_nil translator.send(:create_status, status_ok)
  end

  it "creates time events" do
    time = Time.now
    time_nsec = time.to_i * (10 ** 9) + time.nsec
    time_events = OpenStruct.new(
      timestamp: time_nsec, 
      name: "message", 
      attributes:{"http.method": "get", "http.host": "google.com"}
    )

    converted_events = translator.send(:create_time_events, [time_events])
    event = converted_events.time_event.first

    assert_time_events event, time
  end

  it "creates a batch request hash" do
    time = Time.now
    time_nsec = time.to_i * (10 ** 9) + time.nsec
    span = OpenStruct.new(
      hex_trace_id: "trace_id",
      hex_span_id: "span_id",
      hex_parent_span_id: "parent_id",
      name: "test_span",
      start_timestamp: time_nsec,
      end_timestamp: time_nsec,
      attributes: {"http.method": "get", "http.host": "google.com"},
      status: OpenStruct.new(code: OpenTelemetry::Trace::Status::OK, description: "message"),
      events: [OpenStruct.new(
        timestamp: time_nsec, 
        name: "message", 
        attributes:{"http.method": "get", "http.host": "google.com"}
      )],
      kind: OpenTelemetry::Trace::SpanKind::INTERNAL
    )

    batch_span_request = translator.create_batch [span]
    converted_span = batch_span_request[:spans].first

    assert_equal converted_span.span_id, span.hex_span_id
    assert_equal converted_span.parent_span_id, span.hex_parent_span_id
    assert_equal converted_span.name, "projects/test_project/traces/trace_id/spans/span_id"
    assert_name converted_span.display_name, span.name
    assert_time converted_span.start_time, time
    assert_time converted_span.end_time, time

    event = converted_span.time_events.time_event.first
    assert_time_events event, time

    attributes = converted_span.attributes
    assert_attribute attributes, attr_count: 3


    assert_kind_of Google::Rpc::Status, converted_span.status
    assert_equal converted_span.status.code, Google::Rpc::Code::OK
    assert_equal converted_span.status.message, span.status.description
    assert_equal converted_span.span_kind, :INTERNAL

    assert_equal batch_span_request[:name], "projects/test_project"
  end

  def assert_time_events event, time
     # assert time
     assert_time event.time, time
 
     # assert description
     assert_name event.annotation.description, "message"
     
     # assert attribute
     converted_attr = event.annotation.attributes
     assert_attribute converted_attr
  end

  def assert_time converted_time, time
    assert_kind_of Google::Protobuf::Timestamp, converted_time
    assert_equal converted_time.seconds, time.to_i
    assert_equal converted_time.nanos, time.nsec
  end

  def assert_name converted_str, str
    assert_equal translator.send(:create_name, str, 256), converted_str
  end

  def assert_attribute converted_attr, attr_count: 2, dropped_count: 0
    agent = "opentelemetry-ruby #{Gem.loaded_specs['opentelemetry-sdk'].version.to_s};" \
    "google-cloud-trace-exporter #{Opentelemetry::Exporter::GoogleCloudTrace::VERSION}"
    assert_kind_of Google::Cloud::Trace::V2::Span::Attributes, converted_attr
    assert_equal attr_count, converted_attr.attribute_map.count
    assert_equal dropped_count, converted_attr.dropped_attributes_count
    assert_name converted_attr.attribute_map["/http/method"].string_value, "get"
    assert_name converted_attr.attribute_map["g.co/agent"].string_value, agent  if converted_attr.attribute_map.has_key? :"g.co/agent"
  end
end
