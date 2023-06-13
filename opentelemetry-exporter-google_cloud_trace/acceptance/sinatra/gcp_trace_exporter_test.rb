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
    @pid = Process.fork do
      exec "bundle", "exec", "ruby", "acceptance/sinatra/sinatra_app.rb" 
    end
    # wait for server to start
    sleep 2
    @trace_client = Google::Cloud::Trace::V1::TraceService::Client.new
  end

  after :all do
    Process.kill "KILL", @pid
    Process.wait2 @pid
  end

  it "test_returns_hello_world" do
    uri = URI("http://127.0.0.1:4567")
    start_time = Google::Protobuf::Timestamp.from_time Time.now
    res = Net::HTTP.get(uri)
    assert_match "Hello !", res
    sleep 20 # wait for trace to be sent
    end_time = Google::Protobuf::Timestamp.from_time Time.now

    assert_trace start_time, end_time
  end

  def assert_trace start_time, end_time
    result = @trace_client.list_traces project_id: $project_id, start_time: start_time, end_time: end_time
    traces = result.response.traces 
    traces.each do |trace|
      p @trace_client.get_trace project_id: $project_id, trace_id: trace.trace_id
    end
  end
end