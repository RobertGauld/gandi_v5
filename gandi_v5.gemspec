# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require File.join(File.dirname(__FILE__), 'lib', 'gandi_v5', 'version')

Gem::Specification.new do |gem|
  gem.name        = 'gandi_v5'
  gem.license     = 'BSD 3 clause'
  gem.version     = GandiV5::VERSION
  gem.authors     = ['Robert Gauld']
  gem.email       = ['robert@robertgauld.uk']
  gem.homepage    = 'https://github.com/robertgauld/gandi_v5'
  gem.summary     = 'Make use of Gandi\'s V5 API.'

  gem.metadata = {
    'bug_tracker_uri' => 'https://github.com/robertgauld/gandi_v5/issues',
    'changelog_uri' => 'https://github.com/robertgauld/gandi_v5/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://rubydoc.info/github/robertgauld/gandi_v5/main',
    'homepage_uri' => gem.homepage,
    'source_code_uri' => 'https://github.com/robertgauld/gandi_v5'
  }
  # Also: mailing_list_uri, wiki_uri, funding_uri

  gem.files         = Dir.glob('lib/**/*', File::FNM_DOTMATCH)
  gem.test_files    = Dir.glob('spec/**/*', File::FNM_DOTMATCH)
  # gem.executables   = Dir.glob('exe/**/*', File::FNM_DOTMATCH).map { |f| File.basename(f) }
  gem.require_paths = ['lib']
  gem.bindir        = 'exe'

  gem.extra_rdoc_files = %w[README.md CHANGELOG.md LICENSE.md]
  gem.rdoc_options += [
    '--title', "#{gem.name} - #{gem.summary}",
    '--main', 'README.md',
    '--line-numbers',
    '--inline-source',
    '--quiet'
  ]

  gem.required_ruby_version     = '>= 2.4'
  gem.required_rubygems_version = '>= 2.6.14'

  gem.add_dependency 'dotenv', '~> 2.5'
  gem.add_dependency 'rest-client', '>= 2', '< 3'
  gem.add_dependency 'zeitwerk', '~> 2.1'

  gem.add_development_dependency 'guard', '~> 2.15'
  gem.add_development_dependency 'guard-bundler', '~> 2.2'
  gem.add_development_dependency 'guard-rspec', '~> 4.2', '>= 4.2.5'
  gem.add_development_dependency 'guard-rubocop', '~> 1.3'
  gem.add_development_dependency 'rake', '~> 12.0'
  gem.add_development_dependency 'rb-inotify', '~> 0.9'
  gem.add_development_dependency 'rspec', '>= 3.7', '< 4'
  gem.add_development_dependency 'rspec-its', '~> 1.3'
  gem.add_development_dependency 'rubocop', '~> 1.7'
  gem.add_development_dependency 'rubocop-performance', '~> 1.7'
  gem.add_development_dependency 'rubocop-rake', '~> 0.5.1'
  gem.add_development_dependency 'rubocop-rspec', '~> 2.1'
  gem.add_development_dependency 'simplecov', '~> 0.18'
  gem.add_development_dependency 'simplecov-lcov', '~> 0.8'
  gem.add_development_dependency 'timecop', '~> 0.5'
  gem.add_development_dependency 'vcr', '~> 4.0'
  gem.add_development_dependency 'webmock', '~> 3.6'
end
