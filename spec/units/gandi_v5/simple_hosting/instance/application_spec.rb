# frozen_string_literal: true

describe GandiV5::SimpleHosting::Instance::Application do
  describe 'Helper methods' do
    context 'being_created' do
      subject { described_class.new status: :being_created }
      its('being_created?') { should be true }
      its('cancelled?') { should be false }
      its('running?') { should be false }
      its('error?') { should be false }
    end

    context 'cancelled' do
      subject { described_class.new status: :cancelled }
      its('being_created?') { should be false }
      its('cancelled?') { should be true }
      its('running?') { should be false }
      its('error?') { should be false }
    end

    context 'running' do
      subject { described_class.new status: :running }
      its('being_created?') { should be false }
      its('cancelled?') { should be false }
      its('running?') { should be true }
      its('error?') { should be false }
    end

    context 'error' do
      subject { described_class.new status: :error }
      its('being_created?') { should be false }
      its('cancelled?') { should be false }
      its('running?') { should be false }
      its('error?') { should be true }
    end
  end
end
