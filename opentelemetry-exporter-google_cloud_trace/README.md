# Opentelemetry Google Cloud Trace exporter

This library is an exporter for OpenTelemetry instrumentation which will help translate the spans into Google Cloud Trace understandable format and publish it to Trace service.

## Installation

```sh
$ gem install opentelemetry-exporter-google_cloud_trace
```

## Usage

```
require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'
require 'opentelemetry/exporter/google_cloud_trace'
OpenTelemetry::SDK.configure do |c|
  c.service_name = 'test_app'
  c.add_span_processor(
       OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
         OpenTelemetry::Exporter::GoogleCloudTrace::SpanExporter.new
       )
     )
  c.use_all() # enables all instrumentation!
end
```

## Contributing

Contributions to this library are always welcome and highly encouraged.

See the [Contributing Guide](CONTRIBUTING.md)
for more information on how to get started.

Please note that this project is released with a Contributor Code of Conduct. By
participating in this project you agree to abide by its terms. 
See [Code of Conduct](CODE_OF_CONDUCT.md)
for more information.

## License

This library is licensed under Apache 2.0. Full license text is available in
[LICENSE](LICENSE).

## Support

Please [report bugs at the project on
Github](https://github.com/GoogleCloudPlatform/opentelemetry-operations-ruby/issues). Don't
hesitate to [ask
questions](http://stackoverflow.com/questions/tagged/google-cloud-platform+ruby)
about the client or APIs on [StackOverflow](http://stackoverflow.com).
