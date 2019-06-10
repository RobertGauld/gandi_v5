# frozen_string_literal: true

guard :bundler do
  watch(/^Gemfile(?:\.lock)$/)
  watch(/^.+\.gemspec$/)
end

# rubocop:disable Metrics/BlockLength
group :red_green_refactor, halt_on_fail: true do
  group :rspec do
    guard(
      :rspec,
      all_on_start: true,
      all_after_pass: false,
      notification: :failed,
      cmd: 'bundle exec rspec'
    ) do
      watch(%r{^spec/.+_spec\.rb$})
      watch(%r{^lib/(.+)\.rb$})       { |m| "spec/units/#{m[1]}_spec.rb" }
      watch('spec/spec_helper.rb')    { 'spec' }
      watch(%r{^spec/.+_shared\.rb$}) { 'spec' }
    end
  end

  group :rubocop do
    guard(
      :rubocop,
      all_on_start: true,
      all_after_pass: false,
      notification: :failed,
      keep_failed: false
    ) do
      watch(%r{^lib/(.+)\.rb$}) { |m| [m[0], "spec/units/#{m[1]}_spec.rb"] }
      watch(%r{^spec/.+?/(.+)_spec\.rb$}) { |m| [m[0], "lib/#{m[1]}.rb"] }
      watch(%r{^(?:.+/)?\.rubocop(?:_todo)?\.yml$}) { |m| File.dirname(m[0]) }
    end
  end
end
# rubocop:enable Metrics/BlockLength
