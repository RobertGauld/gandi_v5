# frozen_string_literal: true

describe GandiV5::LiveDNS::Zone::Snapshot do
  subject do
    described_class.new(
      created_at: Time.new(2016, 12, 16, 16, 51, 26, 0),
      uuid: 'snapshot-uuid',
      zone_uuid: 'zone-uuid',
      records: []
    )
  end

  it '#delete' do
    expect(GandiV5).to receive(:delete).with('https://dns.api.gandi.net/api/v5/zones/zone-uuid/snapshots/snapshot-uuid')
                                       .and_return([nil, { 'message' => 'Confirmation message.' }])
    expect(subject.delete).to eq 'Confirmation message.'
  end

  it '#fetch_zone' do
    returns = double GandiV5::LiveDNS::Zone
    expect(GandiV5::LiveDNS::Zone).to receive(:fetch).with('zone-uuid')
                                                     .and_return(returns)
    expect(subject.fetch_zone).to be returns
  end

  describe '#zone' do
    it 'Not previously fetched' do
      returns = double GandiV5::LiveDNS::Zone
      expect(subject).to receive(:fetch_zone).and_return(returns)
      expect(subject.zone).to be returns
    end

    it 'Previously fetched' do
      returns = double GandiV5::LiveDNS::Zone
      subject.instance_exec { @zone = returns }
      expect(subject).to_not receive(:fetch_zone)
      expect(subject.zone).to be returns
    end
  end

  it '.list' do
    body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Zone_Snapshot', 'list.yml'))
    expect(GandiV5).to receive(:get).with('https://dns.api.gandi.net/api/v5/zones/zone-uuid/snapshots')
                                    .and_return([nil, YAML.load_file(body_fixture)])
    expect(described_class.list('zone-uuid')).to eq('snapshot-uuid' => Time.new(2016, 12, 16, 16, 51, 26, 0))
  end

  describe '.fetch' do
    subject { described_class.fetch 'zone-uuid', 'snapshot-uuid' }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Zone_Snapshot', 'fetch.yml'))
      expect(GandiV5).to receive(:get).with('https://dns.api.gandi.net/api/v5/zones/zone-uuid/snapshots/snapshot-uuid')
                                      .and_return([nil, YAML.load_file(body_fixture)])
    end

    its('created_at') { should eq Time.new(2016, 12, 16, 16, 51, 26, 0) }
    its('uuid') { should eq 'snapshot-uuid' }
    its('zone_uuid') { should eq 'zone-uuid' }
    its('records.count') { should eq 1 }
    its('records.first.type') { should eq 'A' }
    its('records.first.ttl') { should eq 10_800 }
    its('records.first.name') { should eq 'www' }
    its('records.first.values') { should match_array ['10.0.1.42'] }
  end
end
