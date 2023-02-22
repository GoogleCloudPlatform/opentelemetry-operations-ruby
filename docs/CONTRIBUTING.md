# Contributing to OpenTelemetry operations Ruby

1. **Sign one of the contributor license agreements below.**
2. Fork the repo, develop and test your code changes.
3. Send a pull request.

## Contributor License Agreements

Before we can accept your pull requests you'll need to sign a Contributor
License Agreement (CLA):

- **If you are an individual writing original source code** and **you own the
  intellectual property**, then you'll need to sign an [individual
  CLA](https://developers.google.com/open-source/cla/individual).
- **If you work for a company that wants to allow you to contribute your work**,
  then you'll need to sign a [corporate
  CLA](https://developers.google.com/open-source/cla/corporate).

You can sign these electronically (just scroll to the bottom). After that, we'll
be able to accept your pull requests.

## Setup

This is a mono repo that will contain tools that will support OpenTelemetry instrumentation for Google Cloud using Ruby.

1. Install Ruby. OpenTelemetry operations Ruby requires Ruby 2.7+. You may choose to
   manage your Ruby and gem installations with [RVM](https://rvm.io/),
   [rbenv](https://github.com/rbenv/rbenv), or
   [chruby](https://github.com/postmodern/chruby), or
   [asdf](https://github.com/asdf-vm/asdf).

2. Install [Bundler](http://bundler.io/).

   ```sh
   $ gem install bundler
   ```

3. Install the top-level project dependencies.

   ```sh
   $ bundle install
   ```

4. Install the specific tool dependencies.

   ```sh
   $ cd opentelemetry-exporter-gcp-trace/
   $ bundle install
   ```

## GCP trace exporter tests

Tests are very important part of OpenTelemetry operations Ruby. All contributions
should include tests that ensure the contributed code behaves as expected.

To run the unit tests, documentation tests, and code style checks together for a
package:

``` sh
$ cd opentelemetry-exporter-gcp-trace/
$ bundle exec rake ci
```

To run the command above, plus all acceptance tests, use `rake ci:acceptance` or
its handy alias, `rake ci:a`.

### Unit Tests


The project uses the [minitest](https://github.com/seattlerb/minitest) library and
[mocks](https://github.com/seattlerb/minitest#mocks).

To run the unit tests:

``` sh
$ cd opentelemetry-exporter-gcp-trace/
$ bundle exec rake test
```


### Acceptance Tests

The acceptance tests interact with the live service API. Follow the
instructions in the [Authentication Guide](AUTHENTICATION.md) for enabling
the required API. Occasionally, some API features may not yet be generally
available, making it difficult for some contributors to successfully run the
entire acceptance test suite. However, please ensure that you do successfully
run acceptance tests for any code areas covered by your pull request.

To run the acceptance tests, first create and configure a project in the Google
Developers Console, as described in the
[Authentication Guide](AUTHENTICATION.md). Be sure to download the JSON KEY
file. Make note of the PROJECT_ID and the KEYFILE location on your system.


#### Running the acceptance tests

To run the acceptance tests:

``` sh
$ cd opentelemetry-exporter-gcp-trace/
$ bundle exec rake acceptance[\\{my-project-id},\\{/path/to/keyfile.json}]
```

Or, if you prefer you can store the values in the `GCLOUD_TEST_PROJECT` and
`GCLOUD_TEST_KEYFILE` environment variables:

``` sh
$ cd opentelemetry-exporter-gcp-trace/
$ export GCLOUD_TEST_PROJECT=\\{my-project-id}
$ export GCLOUD_TEST_KEYFILE=\\{/path/to/keyfile.json}
$ bundle exec rake acceptance
```


## Coding Style

Please follow the established coding style in the library. The style is is
largely based on [The Ruby Style
Guide](https://github.com/bbatsov/ruby-style-guide) with a few exceptions based
on seattle-style:

* Avoid parenthesis when possible, including in method definitions.
* Always use double quotes strings. ([Option
  B](https://github.com/bbatsov/ruby-style-guide#strings))

You can check your code against these rules by running Rubocop like so:

```sh
$ cd opentelemetry-exporter-gcp-trace/
$ bundle exec rake rubocop
```

## Code of Conduct

Please note that this project is released with a Contributor Code of Conduct. By
participating in this project you agree to abide by its terms. See the
[Code of Conduct](CODE_OF_CONDUCT.md) for more information.
