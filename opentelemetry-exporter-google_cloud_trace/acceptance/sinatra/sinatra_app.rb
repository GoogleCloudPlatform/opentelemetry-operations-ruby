require "sinatra"
require "opentelemetry-sdk"
require "opentelemetry/instrumentation/sinatra"
require "opentelemetry/instrumentation/rack"
require "opentelemetry/exporter/google_cloud_trace"

OpenTelemetry::SDK.configure do |c|
  c.service_name = "test_app"
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::GoogleCloudTrace::SpanExporter.new
    )
  )
  c.use "OpenTelemetry::Instrumentation::Sinatra"
end

get "/" do
  test_tracer = OpenTelemetry.tracer_provider.tracer "test_tracer"
  span_to_link_from = OpenTelemetry::Trace.current_span
  link = OpenTelemetry::Trace::Link.new(span_to_link_from.context, { "some.attribute" => 12 })
  test_tracer.in_span "test_span", attributes: { "span_attr" => "span_value" }, links: [link] do |span|
    span.add_event "Creating test span event!!", attributes: { "event_attr" => "event_value" }
  end
  "Hello !"
end
