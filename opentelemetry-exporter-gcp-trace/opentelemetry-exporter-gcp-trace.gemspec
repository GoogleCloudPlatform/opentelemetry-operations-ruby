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


require_relative "lib/opentelemetry/exporter/google_cloud_trace/version"

Gem::Specification.new do |spec|
  spec.name = "opentelemetry-exporter-gcp-trace"
  spec.version = OpenTelemetry::Exporter::GoogleCloudTrace::VERSION
  spec.authors = ["Nivedha"]
  spec.email = ["nivedhasenthil@gmail.com"]

  spec.summary = "Opentelemetry exporter for Google Cloud Trace"
  spec.description = "opentelemetry-exporter-gcp-trace is the officially supported exporter for Google Cloud Trace"
  spec.homepage = "https://github.com/GoogleCloudPlatform/opentelemetry-operations-ruby/tree/main/opentelemetry-exporter-gcp-trace"
  spec.required_ruby_version = ">= 2.6.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.require_paths = ["lib"]
  spec.license = "Apache-2.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir __dir__ do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end

  spec.add_dependency "google-cloud-env"
  spec.add_dependency "google-cloud-trace-v2", "~> 0.0"
  spec.add_dependency "opentelemetry-sdk"

  spec.add_development_dependency "google-style", "~> 1.26.1"
  spec.add_development_dependency "minitest", "~> 5.16"
  spec.add_development_dependency "minitest-autotest", "~> 1.0"
  spec.add_development_dependency "minitest-focus", "~> 1.1"
  spec.add_development_dependency "minitest-rg", "~> 5.2"
end
