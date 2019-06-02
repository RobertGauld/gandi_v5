# frozen_string_literal: true

describe GandiV5::Billing do
  describe '.info' do
    subject { described_class.info }
    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Billing', 'info.yaml'))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/billing/info')
                                      .and_return(YAML.load_file(body_fixture))
    end

    its('annual_balance') { should eq 123.45 }
    its('grid') { should eq 'A' }
    its('outstanding_amount') { should eq 0 }
    its('prepaid_monthly_invoice') { should be_nil }
    its('prepaid.amount') { should eq 1 }
    its('prepaid.created_at') { should eq Time.new(2011, 2, 19, 11, 23, 25) }
    its('prepaid.currency') { should eq 'GBP' }
    its('prepaid.updated_at') { should eq Time.new(2019, 2, 23, 21, 47, 22) }
    its('prepaid.warning_threshold') { should be_nil }
  end

  describe '.info (for a sharing_id)' do
    subject { described_class.info('sharing-id') }
    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Billing', 'info.yaml'))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/billing/info/sharing-id')
                                      .and_return(YAML.load_file(body_fixture))
    end

    its('annual_balance') { should eq 123.45 }
    its('grid') { should eq 'A' }
    its('outstanding_amount') { should eq 0 }
    its('prepaid_monthly_invoice') { should be_nil }
    its('prepaid.amount') { should eq 1 }
    its('prepaid.created_at') { should eq Time.new(2011, 2, 19, 11, 23, 25) }
    its('prepaid.currency') { should eq 'GBP' }
    its('prepaid.updated_at') { should eq Time.new(2019, 2, 23, 21, 47, 22) }
    its('prepaid.warning_threshold') { should be_nil }
  end
end
