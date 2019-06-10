# frozen_string_literal: true

describe GandiV5::Email::Offer do
  subject { described_class.new status: :active }

  describe '.fetch' do
    subject { described_class.fetch('example.com') }

    before :each do
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/offers/example.com')
                                      .and_return([nil, { 'status' => 'active', 'version' => 2 }])
    end

    its('status') { should be :active }
    its('version') { should eq 2 }
  end
end
