# frozen_string_literal: true

require 'dotenv'
require 'coveralls'
require 'rspec/its'
require 'simplecov'
require 'timecop'
require 'vcr'
require 'webmock/rspec'
require 'yaml'

allow_http_connections_to = %w[localhost 127.0.0.1]

Dotenv.load File.join(__dir__, 'test.env')

SimpleCov.coverage_dir(File.join('tmp', 'coverage')) unless ENV.key?('TRAVIS')
SimpleCov.start do
  add_filter 'spec/'
end

if ENV.key?('TRAVIS')
  Coveralls.wear!
  allow_http_connections_to.push 'coveralls.io'
end

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec  do |configuration|
    # Using the expect syntax is preferable to the should syntax in some cases.
    # The problem here is that the :should syntax that RSpec uses can fail in
    # the case of proxy objects, and objects that include the delegate module.
    # Essentially it requires that we define methods on every object in the
    # system. Not owning every object means that we cannot ensure this works in
    # a consistent manner. The expect syntax gets around this problem by not
    # relying on RSpec specific methods being defined on every object in the
    # system.
    # configuration.syntax = [:expect, :should]
    configuration.syntax = :expect
  end

  config.before(:each) { Timecop.return }
end

VCR.configure do |config|
  config.ignore_hosts(*allow_http_connections_to)
  config.cassette_library_dir = File.join __dir__, 'fixtures', 'vcr'
  config.hook_into :webmock
  # config.default_cassette_options = { :record => :none }
end
VCR::RSpec::Metadata.configure!

WebMock.disable_net_connect! allow: allow_http_connections_to

require 'gandi_v5'
