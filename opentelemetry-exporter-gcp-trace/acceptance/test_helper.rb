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


require "minitest/autorun"
require "minitest/focus"
require "minitest/hooks/default"
require "minitest/rg"
require "ostruct"
require "google/cloud"
require "google/cloud/trace/v1"
require "opentelemetry/exporter/google_cloud_trace"

$project_id = ENV["TRACE_EXPORTER_TEST_PROJECT"] || ENV["GCLOUD_TEST_PROJECT"] 
Google::Cloud.configure do |config|
  config.project_id = $project_id
  config.credentials = ENV["TRACE_EXPORTER_TEST_KEYFILE"] || ENV["GCLOUD_TEST_KEYFILE"]
end
