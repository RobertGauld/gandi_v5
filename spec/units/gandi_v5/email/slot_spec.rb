# frozen_string_literal: true

describe GandiV5::Email::Slot do
  subject do
    described_class.new id: 123, capacity: 1, mailbox_type: :standard, status: :inactive, fqdn: 'example.com'
  end

  describe '#delete' do
    it 'Is deletable' do
      subject = described_class.new fqdn: 'example.com', id: 123, status: :inactive, refundable: true
      expect(GandiV5).to receive(:delete).with('https://api.gandi.net/v5/email/slots/example.com/123')
                                         .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.delete).to eq 'Confirmation message.'
    end

    it 'Is in use' do
      subject = described_class.new fqdn: 'example.com', id: 123, status: :active, refundable: true
      expect(GandiV5).to_not receive(:delete)
      expect { subject.delete }.to raise_error GandiV5::Error, 'slot can\'t be deleted whilst active'
    end

    it 'Is not refundable' do
      subject = described_class.new fqdn: 'example.com', id: 123, status: :inactive, refundable: false
      expect(GandiV5).to_not receive(:delete)
      expect { subject.delete }.to raise_error GandiV5::Error, 'slot can\'t be deleted if it\'s not refundable'
    end
  end

  describe '#refresh' do
    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Email_Slot', 'fetch.yml'))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/slots/example.com/123')
                                      .and_return([nil, YAML.load_file(body_fixture)])
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

  describe '#inactive?' do
    it 'When active' do
      slot = described_class.new status: :active
      expect(slot.inactive?).to be false
    end

    it 'When inactive' do
      slot = described_class.new status: :inactive
      expect(slot.inactive?).to be true
    end
  end

  describe '#free?' do
    it 'When free' do
      slot = described_class.new mailbox_type: :free
      expect(slot.free?).to be true
    end

    it 'When standard' do
      slot = described_class.new mailbox_type: :standard
      expect(slot.free?).to be false
    end

    it 'When premium' do
      slot = described_class.new mailbox_type: :premium
      expect(slot.free?).to be false
    end
  end

  describe '#standard?' do
    it 'When free' do
      slot = described_class.new mailbox_type: :free
      expect(slot.standard?).to be false
    end

    it 'When standard' do
      slot = described_class.new mailbox_type: :standard
      expect(slot.standard?).to be true
    end

    it 'When premium' do
      slot = described_class.new mailbox_type: :premium
      expect(slot.standard?).to be false
    end
  end

  describe '#premium?' do
    it 'When free' do
      slot = described_class.new mailbox_type: :free
      expect(slot.premium?).to be false
    end

    it 'When standard' do
      slot = described_class.new mailbox_type: :standard
      expect(slot.premium?).to be false
    end

    it 'When premium' do
      slot = described_class.new mailbox_type: :premium
      expect(slot.premium?).to be true
    end
  end

  describe '.create' do
    let(:url) { 'https://api.gandi.net/v5/email/slots/example.com' }
    let(:created_response) do
      double(
        RestClient::Response,
        headers: { location: 'https://api.gandi.net/v5/email/slots/example.com/created-slot-uuid' }
      )
    end
    let(:created_slot) { double GandiV5::Email::Slot }

    it 'With default type' do
      expect(GandiV5).to receive(:post).with(url, '{"mailbox_type":"standard"}')
                                       .and_return([created_response, { 'message' => 'Confirmation message.' }])
      expect(described_class).to receive(:fetch).with('example.com', 'created-slot-uuid').and_return(created_slot)

      expect(described_class.create('example.com')).to be created_slot
    end

    it 'With passed type' do
      expect(GandiV5).to receive(:post).with(url, '{"mailbox_type":"premium"}')
                                       .and_return([created_response, { 'message' => 'Confirmation message.' }])
      expect(described_class).to receive(:fetch).with('example.com', 'created-slot-uuid').and_return(created_slot)

      expect(described_class.create('example.com', :premium)).to be created_slot
    end
  end

  describe '.fetch' do
    subject { described_class.fetch 'example.com', 123 }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Email_Slot', 'fetch.yml'))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/slots/example.com/123')
                                      .and_return([nil, YAML.load_file(body_fixture)])
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
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Email_Slot', 'list.yml'))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/slots/example.com')
                                      .and_return([nil, YAML.load_file(body_fixture)])
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
