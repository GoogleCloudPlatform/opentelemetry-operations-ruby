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
require "google/protobuf/well_known_types"
require "google/rpc/status_pb"
require "opentelemetry/trace/status"
require "opentelemetry/trace/span_kind"
require_relative "version"

module Opentelemetry
  module Exporter
    module GoogleCloudTrace
      class Translator
        MAX_LINKS = 128
        MAX_EVENTS = 32
        MAX_EVENT_ATTRIBUTES = 4
        MAX_LINK_ATTRIBUTES = 32
        MAX_SPAN_ATTRIBUTES = 32
        MAX_ATTRIBUTES_KEY_BYTES = 128
        MAX_ATTRIBUTES_VAL_BYTES = 16 * 1024  # 16 kilobytes
        MAX_DISPLAY_NAME_BYTE_COUNT = 128
        MAX_EVENT_NAME_BYTE_COUNT = 256
        LABELS_MAPPING = {
            "http.scheme": "/http/client_protocol",
            "http.host": "/http/host",
            "http.method": "/http/method",
            # https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/semantic_conventions/http.md#common-attributes
            "http.request_content_length": "/http/request/size",
            "http.response_content_length": "/http/response/size",
            "http.route": "/http/route",
            "http.status_code": "/http/status_code",
            "http.url": "/http/url",
            "http.user_agent": "/http/user_agent",
        }
        
        def initialize project_id
            @project_id = project_id
        end
        
        # Creates batch_write_spans_request from opentelemetry spans
        # 
        # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] span_data the
        # list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
        # exported.
        # @return [Google::Cloud::Trace::V2::BatchWriteSpansRequest] 
        # The request message for the BatchWriteSpans method.
        def create_batch spans
          cloud_trace_spans = []
            
          spans.each do |span|
            trace_id = span.hex_trace_id
            span_id = span.hex_span_id
            parent_id = span.hex_parent_span_id
            span_name = "projects/#{@project_id}/traces/#{trace_id}/spans/#{span_id}"
            cloud_trace_spans << Google::Cloud::Trace::V2::Span.new(
                                    name: span_name,
                                    span_id: span_id,
                                    parent_span_id: parent_id,
                                    display_name: create_name(span.name, MAX_DISPLAY_NAME_BYTE_COUNT),
                                    start_time: create_time(span.start_timestamp),
                                    end_time: create_time(span.end_timestamp),
                                    attributes: create_attributes(span.attributes, MAX_SPAN_ATTRIBUTES),
                                    links: create_links(span.links),
                                    status: create_status(span.status),
                                    time_events: create_time_events(span.events),
                                    span_kind: create_span_kind(span.kind)
                                 )
          end
            
          {
            name: "projects/#{@project_id}",
            spans: cloud_trace_spans
          }
        end
        
        private
          
        def create_time epoch
          return if epoch.nil?  
          time_nsec = Time.at(0, epoch, :nsec) # create Time from nanoseconds epoch
          Google::Protobuf::Timestamp.from_time time_nsec
        end  
          
        def create_name name, max_bytes
          truncated_str, truncated_byte_count = truncate_str name, max_bytes
          Google::Cloud::Trace::V2::TruncatableString.new(value:truncated_str, truncated_byte_count:truncated_byte_count)
        end  

        def truncate_str str, max_bytes
          encoded = str.encode("utf-8")
          truncated_str = encoded.byteslice(0, max_bytes)
          [truncated_str, encoded.length - truncated_str.encode("utf-8").length]
        end
        
        def create_attributes  attributes, max_attributes, add_agent_attribute = false
            return if attributes.nil? || attributes.empty?
            attribute_map = {}

            if add_agent_attribute
              attribute_map["g.co/agent"] = create_attribute_value(
                "opentelemetry-ruby #{Gem.loaded_specs['opentelemetry-sdk'].version.to_s};" \
                "google-cloud-trace-exporter #{Opentelemetry::Exporter::GoogleCloudTrace::VERSION}"
              ) 
            end

            attributes.each_pair do |k,v|
                key = truncate_str(k, MAX_ATTRIBUTES_KEY_BYTES).first
                key = LABELS_MAPPING[key] if LABELS_MAPPING.has_key? key
                value = create_attribute_value(v)
                attribute_map[key] = value if !value.nil?

                break if attribute_map.count == max_attributes
            end
            
            Google::Cloud::Trace::V2::Span::Attributes.new(
                attribute_map: attribute_map,
                dropped_attributes_count: attributes.count - attribute_map.count
            )
        end  

        def create_attribute_value value
          case value
          when (TrueClass || FalseClass)
            Google::Cloud::Trace::V2::AttributeValue.new bool_value: value
          when Integer
            Google::Cloud::Trace::V2::AttributeValue.new int_value: value
          else
            Google::Cloud::Trace::V2::AttributeValue.new(
              string_value: create_name(value.to_s, MAX_ATTRIBUTES_VAL_BYTES)
            )
          end
        end
        
        def create_links  links
          return if links.nil?
          trace_links = []
          dropped_links_count = 0

          if links.length > MAX_LINKS
            dropped_links_count = links.length - MAX_LINKS
            links = links[0...MAX_LINKS]
          end  

          links.each do |link|
            trace_id = link.context.hex_trace_id
            span_id = link.context.hex_span_id
            trace_links << Google::Cloud::Trace::V2::Span::Link.new(
              trace_id: trace_id,
              span_id: span_id,
              type: "TYPE_UNSPECIFIED",
              attributes: create_attributes(link.attributes, MAX_LINK_ATTRIBUTES)
            )
          end

          Google::Cloud::Trace::V2::Span::Links.new( 
            link: trace_links, 
            dropped_links_count: dropped_links_count
          )          
        end  
        
        def create_status status 
          case status.code 
          when OpenTelemetry::Trace::Status::OK
              Google::Rpc::Status.new(code: Google::Rpc::Code::OK, message: status.description)
          when OpenTelemetry::Trace::Status::UNSET
              nil
          else
              Google::Rpc::Status.new(code: Google::Rpc::Code::UNKNOWN, message: status.description)
          end  
        end  
        
        def create_time_events  events
          return if events.nil?
          time_events = []
          dropped_message_events_count = 0
          
          dropped_annotations_count = 0
          if events.length > MAX_EVENTS
              dropped_annotations_count = events.length - MAX_EVENTS
              events = events[0...MAX_EVENTS]
          end  

          events.each do |event|
              time_events << Google::Cloud::Trace::V2::Span::TimeEvent.new(
                  time: create_time(event.timestamp),
                  annotation: Google::Cloud::Trace::V2::Span::TimeEvent::Annotation.new(
                      description: create_name(event.name, MAX_EVENT_NAME_BYTE_COUNT),
                      annotation: create_attributes(event.attributes, MAX_EVENT_ATTRIBUTES)
                  )
              )
          end
          
          Google::Cloud::Trace::V2::Span::TimeEvents.new( 
            time_event: time_events, 
            dropped_annotations_count: dropped_annotations_count,
            dropped_message_events_count: dropped_message_events_count
          )
        end  
        
        def create_span_kind  kind
          case kind
          when OpenTelemetry::Trace::SpanKind::INTERNAL
              Google::Cloud::Trace::V2::Span::SpanKind::INTERNAL
          when OpenTelemetry::Trace::SpanKind::CLIENT
              Google::Cloud::Trace::V2::Span::SpanKind::CLIENT
          when OpenTelemetry::Trace::SpanKind::SERVER
              Google::Cloud::Trace::V2::Span::SpanKind::SERVER
          when OpenTelemetry::Trace::SpanKind::PRODUCER
              Google::Cloud::Trace::V2::Span::SpanKind::PRODUCER
          when OpenTelemetry::Trace::SpanKind::CONSUMER
              Google::Cloud::Trace::V2::Span::SpanKind::CONSUMER    
          else
              Google::Cloud::Trace::V2::Span::SpanKind::SPAN_KIND_UNSPECIFIED
          end 
        end
      end    
    end
  end
end
