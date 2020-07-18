# frozen_string_literal: true

describe GandiV5::SimpleHosting::Instance::VirtualHost::LinkedDnsZone do
  describe 'Helper methods' do
    context 'altered' do
      subject { described_class.new status: :altered }
      its('altered?') { should be true }
      its('livedns_conflict?') { should be false }
      its('livedns_done?') { should be false }
      its('livedns_error?') { should be false }
      its('unknown?') { should be false }
    end

    context 'altered' do
      subject { described_class.new status: :livedns_conflict }
      its('altered?') { should be false }
      its('livedns_conflict?') { should be true }
      its('livedns_done?') { should be false }
      its('livedns_error?') { should be false }
      its('unknown?') { should be false }
    end

    context 'livedns_done' do
      subject { described_class.new status: :livedns_done }
      its('altered?') { should be false }
      its('livedns_conflict?') { should be false }
      its('livedns_done?') { should be true }
      its('livedns_error?') { should be false }
      its('unknown?') { should be false }
    end

    context 'livedns_error' do
      subject { described_class.new status: :livedns_error }
      its('altered?') { should be false }
      its('livedns_conflict?') { should be false }
      its('livedns_done?') { should be false }
      its('livedns_error?') { should be true }
      its('unknown?') { should be false }
    end

    context 'unknown' do
      subject { described_class.new status: :unknown }
      its('altered?') { should be false }
      its('livedns_conflict?') { should be false }
      its('livedns_done?') { should be false }
      its('livedns_error?') { should be false }
      its('unknown?') { should be true }
    end
  end
end
