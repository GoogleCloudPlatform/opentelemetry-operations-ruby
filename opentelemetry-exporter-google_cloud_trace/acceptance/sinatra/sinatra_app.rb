require "sinatra"
require "opentelemetry-sdk"
require "opentelemetry/instrumentation/sinatra"
require "opentelemetry/instrumentation/rack"
require "opentelemetry/exporter/google_cloud_trace"

OpenTelemetry::SDK.configure do |c|
    c.service_name = 'test_app'
    c.add_span_processor(
        OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
          OpenTelemetry::Exporter::GoogleCloudTrace::SpanExporter.new
        )
      )
    c.use 'OpenTelemetry::Instrumentation::Sinatra'
end

get "/" do
  "Hello !"
end