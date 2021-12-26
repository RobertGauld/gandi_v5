# frozen_string_literal: true

describe GandiV5::LiveDNS::Domain::DnssecKey do
  subject do
    described_class.new(
      uuid: 'key-uuid',
      status: 'status',
      fqdn: 'example.com',
      algorithm_id: 2,
      algorithm_name: 'Diffie-Hellman',
      deleted: false,
      ds: 'ds-record',
      flags: 256,
      fingerprint: 'fp',
      public_key: 'pub-key',
      tag: 'tag'
    )
  end

  it '#delete' do
    expect(GandiV5).to receive(:delete).with('https://api.gandi.net/v5/livedns/domains/example.com/keys/key-uuid')
                                       .and_return([nil, { 'message' => 'Confirmation message.' }])
    expect(subject.delete).to eq 'Confirmation message.'
    expect(subject.deleted).to be true
  end

  it '#undelete' do
    subject = described_class.new deleted: true, uuid: 'key-uuid', fqdn: 'example.com'
    url = 'https://api.gandi.net/v5/livedns/domains/example.com/keys/key-uuid'
    expect(GandiV5).to receive(:patch).with(url, '{"deleted":false}')
                                      .and_return([nil, { 'message' => 'Confirmation message.' }])
    expect(subject.undelete).to eq 'Confirmation message.'
    expect(subject.deleted).to be false
  end

  describe 'flags helper methods' do
    describe '256 (zone signing key)' do
      before(:each) { subject.instance_exec { @flags = 256 } }
      its('zone_signing_key?') { should be true }
      its('key_signing_key?') { should be false }
    end

    describe '257 (key signing key)' do
      before(:each) { subject.instance_exec { @flags = 257 } }
      its('zone_signing_key?') { should be false }
      its('key_signing_key?') { should be true }
    end
  end

  describe '.create' do
    let(:url) { 'https://api.gandi.net/v5/livedns/domains/example.com/keys' }
    let(:response) do
      double RestClient::Response, headers: {
        location: 'https://api.gandi.net/v5/livedns/domains/example.com/keys/created-key-uuid'
      }
    end

    it 'Accepts integer for flags' do
      returns = double described_class
      expect(GandiV5).to receive(:post).with(url, '{"flags":256}').and_return([response, nil])
      expect(described_class).to receive(:fetch).with('example.com', 'created-key-uuid')
                                                .and_return(returns)
      expect(described_class.create('example.com', :zone_signing_key)).to be returns
    end

    it 'Accepts :zone_signing_key for flags' do
      expect(GandiV5).to receive(:post).with(url, '{"flags":256}').and_return([response, nil])
      expect(described_class).to receive(:fetch)
      described_class.create('example.com', :zone_signing_key)
    end

    it 'Accepts :key_signing_key for flags' do
      expect(GandiV5).to receive(:post).with(url, '{"flags":257}').and_return([response, nil])
      expect(described_class).to receive(:fetch)
      described_class.create('example.com', :key_signing_key)
    end

    it 'Fails on invalid flags' do
      expect { described_class.create('example.com', :invalid) }.to raise_error ArgumentError, 'flags is invalid'
      expect { described_class.create('example.com', '0') }.to raise_error ArgumentError, 'flags is invalid'
    end
  end

  it '.list' do
    body_fixture = File.expand_path(
      File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Domain_DnssecKey', 'list.yml')
    )
    url = 'https://api.gandi.net/v5/livedns/domains/example.com/keys'

    if RUBY_VERSION >= '3.1.0'
      expect(GandiV5).to receive(:get).with(url).and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
    else
      expect(GandiV5).to receive(:get).with(url).and_return([nil, YAML.load_file(body_fixture)])
    end
    results = described_class.list('example.com')
    result = results.first
    expect(results.count).to eq 1
    expect(result.uuid).to eq 'key-uuid'
    expect(result.status).to eq 'status'
    expect(result.fqdn).to eq 'example.com'
    expect(result.algorithm_id).to eq 2
    expect(result.algorithm_name).to eq 'Diffie-Hellman'
    expect(result.deleted).to be false
    expect(result.ds).to eq 'ds-record'
    expect(result.flags).to eq 256
  end

  describe '.fetch' do
    subject { described_class.fetch 'example.com', 'key-uuid' }

    before :each do
      body_fixture = File.expand_path(
        File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Domain_DnssecKey', 'fetch.yml')
      )
      url = 'https://api.gandi.net/v5/livedns/domains/example.com/keys/key-uuid'
      if RUBY_VERSION >= '3.1.0'
        expect(GandiV5).to receive(:get).with(url)
                                        .and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
      else
        expect(GandiV5).to receive(:get).with(url)
                                        .and_return([nil, YAML.load_file(body_fixture)])
      end
    end

    its('uuid') { should eq 'key-uuid' }
    its('status') { should eq 'status' }
    its('fqdn') { should eq 'example.com' }
    its('algorithm_id') { should eq 2 }
    its('algorithm_name') { should eq 'Diffie-Hellman' }
    its('deleted') { should be false }
    its('ds') { should eq 'ds-record' }
    its('flags') { should eq 256 }
    its('fingerprint') { should eq 'fp' }
    its('public_key') { should eq 'pub-key' }
    its('tag') { should eq 'tag' }
  end
end
