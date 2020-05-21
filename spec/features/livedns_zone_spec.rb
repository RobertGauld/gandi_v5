# frozen_string_literal: true

describe 'LiveDNS Zone features' do
  it 'List zones', :vcr do
    list = GandiV5::LiveDNS::Zone.list

    expect(list.count).to eq 1
    expect(list.first.uuid).to eq 'uuid-of-zone'
    expect(list.first.name).to eq 'Zone Name'
    expect(list.first.sharing_uuid).to be nil
    expect(list.first.soa_retry).to eq 3_600
    expect(list.first.soa_minimum).to eq 10_800
    expect(list.first.soa_refresh).to eq 10_800
    expect(list.first.soa_expire).to eq 604_800
    expect(list.first.soa_serial).to eq 1_432_798_405
    expect(list.first.soa_email).to eq 'hostmaster.gandi.net.'
    expect(list.first.soa_primary_ns).to eq 'a.dns.gandi.net.'
  end

  it 'Save zone to file', :vcr do
    zone = GandiV5::LiveDNS::Zone.new uuid: 'zone-uuid'
    expect(File).to receive(:write).with('/path/to/file', "Contents of zone file.\n")

    File.write '/path/to/file', zone.fetch_zone_lines
  end

  it 'Make and save snapshot', :vcr do
    hash = {
      uuid: 'snapshot-uuid',
      zone_uuid: 'zone-uuid',
      created_at: Time.new(2016, 12, 16, 16, 51, 26),
      records: [
        type: 'A',
        ttl: 10_800,
        name: 'www',
        values: ['10.0.1.42']
      ]
    }

    zone = GandiV5::LiveDNS::Zone.new uuid: 'zone-uuid'
    snapshot = zone.take_snapshot
    expect(snapshot.to_h).to eq hash
  end
end
