# frozen_string_literal: true

describe GandiV5::Email::Slot do
  subject do
    described_class.new id: 123, capacity: 1, mailbox_type: :standard, status: :inactive, fqdn: 'example.com'
  end

  it '#delete' do
    expect(GandiV5).to receive(:delete).with('https://api.gandi.net/v5/email/slots/example.com/123')
                                       .and_return('message' => 'Confirmation message.')
    expect(subject.delete).to eq 'Confirmation message.'
  end

  describe '#refresh' do
    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Email_Slot', 'get.yaml'))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/slots/example.com/123')
                                      .and_return(YAML.load_file(body_fixture))
      subject.refresh
    end

    its('fqdn') { should eq 'example.com' }
    its('id') { should eq 125 }
    its('created_at') { should eq Time.new(2019, 4, 8, 8, 48, 41, 0) }
    its('mailbox_type') { should be :premium }
    its('status') { should be :inactive }
    its('refundable') { should be true }
    its('capacity') { should eq 53_687_091_200 }
    its('refund_amount') { should eq 16.16 }
    its('refund_currency') { should eq 'EUR' }
  end

  describe '#active?' do
    it 'When active' do
      slot = described_class.new status: :active
      expect(slot.active?).to be true
    end

    it 'When inactive' do
      slot = described_class.new status: :inactive
      expect(slot.active?).to be false
    end
  end

  describe '.create' do
    let(:url) { 'https://api.gandi.net/v5/email/slots/example.com' }
    it 'With default type' do
      expect(GandiV5).to receive(:post).with(url, '{"mailbox_type":"standard"}')
                                       .and_return('message' => 'Confirmation message.')
      expect(described_class.create('example.com')).to eq 'Confirmation message.'
    end

    it 'With passed type' do
      expect(GandiV5).to receive(:post).with(url, '{"mailbox_type":"premium"}')
                                       .and_return('message' => 'Confirmation message.')
      expect(described_class.create('example.com', :premium)).to eq 'Confirmation message.'
    end
  end

  describe '.fetch' do
    subject { described_class.fetch 'example.com', 123 }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Email_Slot', 'get.yaml'))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/slots/example.com/123')
                                      .and_return(YAML.load_file(body_fixture))
    end

    its('fqdn') { should eq 'example.com' }
    its('id') { should eq 125 }
    its('created_at') { should eq Time.new(2019, 4, 8, 8, 48, 41, 0) }
    its('mailbox_type') { should be :premium }
    its('status') { should be :inactive }
    its('refundable') { should be true }
    its('capacity') { should eq 53_687_091_200 }
    its('refund_amount') { should eq 16.16 }
    its('refund_currency') { should eq 'EUR' }
  end

  describe '.list' do
    subject { described_class.list 'example.com' }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Email_Slot', 'list.yaml'))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/slots/example.com')
                                      .and_return(YAML.load_file(body_fixture))
    end

    its('count') { should eq 1 }
    its('first.fqdn') { should eq 'example.com' }
    its('first.id') { should eq 125 }
    its('first.created_at') { should eq Time.new(2019, 4, 8, 8, 48, 41, 0) }
    its('first.mailbox_type') { should be :standard }
    its('first.status') { should be :inactive }
    its('first.refundable') { should be true }
    its('first.capacity') { should eq 3_221_225_472 }
    its('first.refund_amount') { should be nil }
    its('first.refund_currency') { should be nil }
  end
end
