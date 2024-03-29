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

module OpenTelemetry
  module Exporter
    ##
    # # Google Cloud Trace
    #
    # Cloud Trace is a distributed tracing system that collects latency data
    # from your applications and displays it in the Google Cloud Console.
    # You can track how requests propagate through your application and
    # receive detailed near real-time performance insights.
    # Cloud Trace automatically analyzes all of your application's traces
    # to generate in-depth latency reports to surface performance degradations,
    # and can capture traces from all of your VMs, containers, or App Engine projects.
    module GoogleCloudTrace
    end
  end
end


require "opentelemetry/sdk"
require "opentelemetry/exporter/google_cloud_trace/span_exporter"
require "opentelemetry/exporter/google_cloud_trace/version"
