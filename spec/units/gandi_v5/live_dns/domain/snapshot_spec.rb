# frozen_string_literal: true

describe GandiV5::LiveDNS::Domain::Snapshot do
  subject do
    described_class.new(
      created_at: Time.new(2016, 12, 16, 16, 51, 26, 0),
      uuid: 'snapshot-uuid',
      name: 'snapshot-name',
      automatic: false,
      records: [],
      fqdn: 'example.com'
    )
  end

  it '#update' do
    url = 'https://api.gandi.net/v5/livedns/domains/example.com/snapshots/snapshot-uuid'
    body = '{"name":"NEW NAME"}'
    expect(GandiV5).to receive(:patch).with(url, body)
                                      .and_return([nil, { 'message' => 'Confirmation message.' }])
    expect(subject.update(name: 'NEW NAME')).to eq 'Confirmation message.'
    expect(subject.name).to eq 'NEW NAME'
  end

  it '#delete' do
    expect(GandiV5).to receive(:delete).with('https://api.gandi.net/v5/livedns/domains/example.com/snapshots/snapshot-uuid')
                                       .and_return([nil, { 'message' => 'Confirmation message.' }])
    expect(subject.delete).to eq 'Confirmation message.'
  end

  describe '#records' do
    it 'Returns existing if present' do
      expect(GandiV5).to_not receive(:get)
      expect(subject.records).to eq []
    end

    it 'Fetches and saves if not present' do
      subject = described_class.new fqdn: 'example.com', uuid: 'snapshot-uuid'
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/livedns/domains/example.com/snapshots/snapshot-uuid')
                                      .and_return([nil, { 'zone_data' => [{ 'rrset_name' => 'HELLO' }] }])
      expect(subject.records.count).to eq 1
      expect(subject.records.first.name).to eq 'HELLO'
    end
  end

  describe '.list' do
    let :body_fixture do
      File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Domain_Snapshot', 'list.yml'))
    end
    let(:url) { 'https://api.gandi.net/v5/livedns/domains/example.com/snapshots' }

    it 'With default parameters' do
      expect(GandiV5).to receive(:paginated_get).with(url, (1..), 100, params: {})
                                                .and_yield(YAML.load_file(body_fixture))
      results = described_class.list('example.com')
      result = results.first
      expect(results.count).to eq 1
      expect(result.name).to eq 'snapshot-name'
      expect(result.created_at).to eq Time.new(2016, 12, 16, 16, 51, 26, 0)
      expect(result.uuid).to eq 'snapshot-uuid'
      expect(result.automatic).to be true
      expect(result.fqdn).to eq 'example.com'
    end

    describe 'Passes optional query params' do
      describe 'automatic' do
        it 'true' do
          expect(GandiV5).to receive(:paginated_get).with(url, (1..), 100, params: { automatic: true })
          described_class.list('example.com', automatic: true)
        end

        it 'false' do
          expect(GandiV5).to receive(:paginated_get).with(url, (1..), 100, params: { automatic: false })
          described_class.list('example.com', automatic: false)
        end
      end
    end
  end

  describe '.fetch' do
    subject { described_class.fetch 'example.com', 'snapshot-uuid' }

    before :each do
      body_fixture = File.expand_path(
        File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Domain_Snapshot', 'fetch.yml')
      )
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/livedns/domains/example.com/snapshots/snapshot-uuid')
                                      .and_return([nil, YAML.load_file(body_fixture)])
    end

    its('created_at') { should eq Time.new(2016, 12, 16, 16, 51, 26, 0) }
    its('uuid') { should eq 'snapshot-uuid' }
    its('name') { should eq 'snapshot-name' }
    its('automatic') { should be true }
    its('fqdn') { should eq 'example.com' }
    its('records.count') { should eq 1 }
    its('records.first.type') { should eq 'A' }
    its('records.first.ttl') { should eq 10_800 }
    its('records.first.name') { should eq 'www' }
    its('records.first.values') { should match_array ['10.0.1.42'] }
  end
end
