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
require_relative "./sinatra_app.rb"

# Test the Sinatra server for the Cloud Scheduler sample.
describe "Opentelemety exporter for Google Cloud Trace" do
  before :all do
    @pid = Process.fork do
      Sinatra::Application.start!
    end
    # wait for server to start
    sleep 2
  end

  after :all do
    Sinatra::Application.stop!
    Process.kill "KILL", @pid
    Process.wait2 @pid
  end

  it "test_returns_hello_world" do
    uri = URI("http://127.0.0.1:4567")
    res = Net::HTTP.get(uri)
    assert_match "Hello !", res
  end
end