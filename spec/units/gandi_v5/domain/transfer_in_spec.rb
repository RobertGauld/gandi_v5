# frozen_string_literal: true

describe GandiV5::Domain::TransferIn do
  subject { described_class.new fqdn: 'example.com' }

  describe '.fetch' do
    subject { described_class.fetch 'example.com' }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain_TransferIn', 'fetch.yml'))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/transferin/example.com')
                                      .and_return([nil, YAML.load_file(body_fixture)])
    end

    its('fqdn') { should eq 'example.com' }
    its('created_at') { should eq Time.new(2011, 2, 21, 10, 39, 0, 0) }
    its('owner_contact') { should eq 'owner contact' }
    its('duration') { should eq 1 }
    its('reseller_uuid') { should eq 'reseller-uuid' }
    its('version') { should eq 0 }
    its('step') { should eq 'step text' }
    its('step_number') { should eq 2 }
    its('updated_at') { should eq Time.new(2011, 2, 22, 10, 39, 0, 0) }
    its('errortype') { should eq 'error-type' }
    its('errortype_label') { should eq 'error label' }
    its('inner_step') { should eq 'inner-step' }
    its('regac_at') { should eq Time.new(2011, 2, 23, 10, 39, 0, 0) }
    its('start_at') { should eq Time.new(2011, 2, 24, 10, 39, 0, 0) }
    its('transfer_procedure') { should eq 'transfer-procedure' }
    its('foa_status') { should eq({ 'user@example.com' => 'ans' }) }
  end

  describe '.create' do
    let(:url) { 'https://api.gandi.net/v5/domain/transferin' }

    describe 'Sets dry-run header' do
      let(:body) { '{"owner":{},"fqdn":"example.com"}' }

      it 'False by default' do
        expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0).and_return([nil, { 'message' => 'confirmation' }])
        described_class.create 'example.com', owner: {}
      end

      it 'True' do
        expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 1).and_return([nil, nil])
        described_class.create 'example.com', owner: {}, dry_run: true
      end

      it 'False' do
        expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0).and_return([nil, { 'message' => 'confirmation' }])
        described_class.create 'example.com', owner: {}, dry_run: false
      end

      it 'Dry run was successful' do
        returns = { 'status' => 'success' }
        expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 1)
                                         .and_return([nil, returns])
        expect(described_class.create('example.com', owner: {}, dry_run: true)).to be returns
      end

      it 'Dry run has errors' do
        returns = {
          'status' => 'error',
          'errors' => [{ 'description' => 'd', 'location' => 'l', 'name' => 'n' }]
        }
        expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 1)
                                         .and_return([nil, returns])
        expect(described_class.create('example.com', owner: {}, dry_run: true)).to be returns
      end
    end

    describe 'Sets sharing_id' do
      it 'Absent by default' do
        expect(GandiV5).to receive(:post).with(url, any_args).and_return([nil, { 'message' => 'confirmation' }])
        described_class.create('example.com', owner: {})
      end

      it 'Paying as another organization' do
        expect(GandiV5).to receive(:post).with("#{url}?sharing_id=organization_id", any_args)
                                         .and_return([nil, { 'message' => 'confirmation' }])
        described_class.create('example.com', sharing_id: 'organization_id', owner: {})
      end

      it 'Buy as a reseller' do
        expect(GandiV5).to receive(:post).with("#{url}?sharing_id=reseller_id", any_args)
                                         .and_return([nil, { 'message' => 'confirmation' }])
        described_class.create('example.com', sharing_id: 'reseller_id', owner: {})
      end
    end

    it 'Success' do
      body = '{"owner":{},"fqdn":"example.com"}'
      expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0)
                                       .and_return([nil, { 'message' => 'confirmation' }])
      expect(described_class.create('example.com', owner: {})).to eq 'confirmation'
    end

    it 'Errors on missing owner' do
      expect { described_class.create 'example.com' }.to raise_error ArgumentError, 'missing keyword: owner'
    end

    it 'Given contact as hash' do
      body = '{"owner":{"email":"owner@example.com"},"fqdn":"example.com"}'
      expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0)
                                       .and_return([nil, { 'message' => 'confirmation' }])
      described_class.create 'example.com', owner: { email: 'owner@example.com' }
    end

    it 'Given contact as GandiV5::Domain::Contact' do
      body = '{"owner":{"email":"owner@example.com"},"fqdn":"example.com"}'
      expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0)
                                       .and_return([nil, { 'message' => 'confirmation' }])
      owner = double GandiV5::Domain::Contact, to_gandi: { 'email' => 'owner@example.com' }
      described_class.create 'example.com', owner: owner
    end
  end

  it '.relaunch' do
    expect(GandiV5).to receive(:put).with('https://api.gandi.net/v5/domain/transferin/example.com')
                                    .and_return([nil, { 'message' => 'confirmation' }])
    expect(described_class.relaunch('example.com')).to eq 'confirmation'
  end

  it '.resend_foa_emails' do
    url = 'https://api.gandi.net/v5/domain/transferin/example.com/foa'
    body = '{"email":"user@example.com"}'
    expect(GandiV5).to receive(:post).with(url, body)
                                     .and_return([nil, { 'message' => 'confirmation' }])
    expect(described_class.resend_foa_emails('example.com', 'user@example.com')).to eq 'confirmation'
  end

  it '#relaunch' do
    returned = double String
    expect(described_class).to receive(:relaunch).with('example.com').and_return(returned)
    expect(subject.relaunch).to be returned
  end

  it '#resend_foa_emails' do
    returned = double String
    expect(described_class).to receive(:resend_foa_emails).with('example.com', 'user@example.com').and_return(returned)
    expect(subject.resend_foa_emails('user@example.com')).to be returned
  end
end
