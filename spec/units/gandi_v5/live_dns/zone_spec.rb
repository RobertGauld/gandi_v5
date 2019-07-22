# frozen_string_literal: true

describe GandiV5::LiveDNS::Zone do
  subject do
    described_class.new(
      name: 'Zone Name',
      uuid: 'zone-uuid',
      soa_retry: 1,
      soa_minimum: 2,
      soa_refresh: 3,
      soa_expire: 4,
      soa_serial: 5,
      soa_email: 'admin.example.com',
      soa_primary_ns: '192.168.0.1'
    )
  end

  it '#to_s' do
    expect(subject.to_s).to eq [
      '@	IN	SOA	192.168.0.1 admin.example.com (',
      "\t5\t;Serial",
      "\t3\t\t;Refresh",
      "\t1\t\t;Retry",
      "\t4\t\t;Expire",
      "\t2\t\t;Minimum & Negative TTL",
      ')'
    ].join("\n")
  end

  describe '#fetch_records' do
    it 'All of them' do
      expect(GandiV5).to receive(:get).with('https://dns.api.gandi.net/api/v5/zones/zone-uuid/records')
                                      .and_return([nil, []])

      expect(subject.fetch_records).to eq []
    end

    it 'All for a name' do
      expect(GandiV5).to receive(:get).with('https://dns.api.gandi.net/api/v5/zones/zone-uuid/records/name')
                                      .and_return([nil, []])

      expect(subject.fetch_records('name')).to eq []
    end

    it 'A type for a name' do
      expect(GandiV5).to receive(:get).with('https://dns.api.gandi.net/api/v5/zones/zone-uuid/records/name/TXT')
                                      .and_return(
                                        [
                                          nil,
                                          [
                                            {
                                              'rrset_type' => 'TXT',
                                              'rrset_name' => 'name',
                                              'rrset_ttl' => 600,
                                              'rrset_values' => %w[a b]
                                            }
                                          ]
                                        ]
                                      )

      records = subject.fetch_records('name', 'TXT')
      expect(records.count).to eq 1
      expect(records.first.type).to eq 'TXT'
      expect(records.first.ttl).to eq 600
      expect(records.first.name).to eq 'name'
      expect(records.first.values).to match_array %w[a b]
    end

    it 'Invalid type' do
      expect { subject.fetch_records 'name', 'INVALID-TYPE' }.to raise_error ArgumentError
    end
  end

  describe '#fetch_zone_lines' do
    it 'All of them' do
      url = 'https://dns.api.gandi.net/api/v5/zones/zone-uuid/records'
      expect(GandiV5).to receive(:get).with(url, accept: 'text/plain').and_return([nil, 'returned'])
      expect(subject.fetch_zone_lines).to eq 'returned'
    end

    it 'All for a name' do
      url = 'https://dns.api.gandi.net/api/v5/zones/zone-uuid/records/name'
      expect(GandiV5).to receive(:get).with(url, accept: 'text/plain').and_return([nil, 'returned'])
      expect(subject.fetch_zone_lines('name')).to eq 'returned'
    end

    it 'A type for a name' do
      url = 'https://dns.api.gandi.net/api/v5/zones/zone-uuid/records/name/TXT'
      expect(GandiV5).to receive(:get).with(url, accept: 'text/plain').and_return([nil, 'returned'])
      expect(subject.fetch_zone_lines('name', 'TXT')).to eq 'returned'
    end

    it 'Invalid type' do
      expect { subject.fetch_zone_lines 'name', 'INVALID-TYPE' }.to raise_error ArgumentError
    end
  end

  describe '#add_record' do
    it 'Success' do
      url = 'https://dns.api.gandi.net/api/v5/zones/zone-uuid/records'
      body = '{"rrset_name":"name","rrset_type":"TXT","rrset_ttl":900,"rrset_values":["a","b"]}'
      expect(GandiV5).to receive(:post).with(url, body).and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.add_record('name', 'TXT', 900, 'a', 'b')).to eq 'Confirmation message.'
    end

    it 'Bad type' do
      expect { subject.add_record 'name', 'INVALID-TYPE', 900, 'a' }.to raise_error ArgumentError
    end

    it 'Bad TTL' do
      expect { subject.add_record 'name', 'TXT', -900, 'a' }.to raise_error(
        ArgumentError,
        'ttl must be positive and non-zero'
      )
    end

    it 'No values' do
      expect { subject.add_record 'name', 'TXT', 900 }.to raise_error(
        ArgumentError,
        'there must be at least one value'
      )
    end
  end

  describe '#delete_records' do
    it 'All of them' do
      url = 'https://dns.api.gandi.net/api/v5/zones/zone-uuid/records'
      expect(GandiV5).to receive(:delete).with(url).and_return([nil, nil])
      subject.delete_records
    end

    it 'All for a name' do
      url = 'https://dns.api.gandi.net/api/v5/zones/zone-uuid/records/name'
      expect(GandiV5).to receive(:delete).with(url).and_return([nil, nil])
      subject.delete_records 'name'
    end

    it 'A type for a name' do
      url = 'https://dns.api.gandi.net/api/v5/zones/zone-uuid/records/name/TXT'
      expect(GandiV5).to receive(:delete).with(url).and_return([nil, nil])
      subject.delete_records 'name', 'TXT'
    end

    it 'Invalid type' do
      expect { subject.delete_records 'name', 'INVALID-TYPE' }.to raise_error ArgumentError
    end
  end

  describe '#replace_records' do
    it 'Given array of GandiV5::LiveDNS::RecordSet' do
      records = [
        { name: 'name', ttl: 600, type: 'TXT', values: ['a'] }
      ]

      url = 'https://dns.api.gandi.net/api/v5/zones/zone-uuid/records'
      body = '{"items":[{"rrset_name":"name","rrset_ttl":600,"rrset_type":"TXT","rrset_values":["a"]}]}'
      expect(GandiV5).to receive(:put).with(url, body)
                                      .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.replace_records(records: records)).to eq 'Confirmation message.'
    end

    it 'Given string' do
      records = [
        '@ 86400 IN A 192.168.0.1',
        '* 86400 IN A 192.168.0.1'
      ].join("\n")

      url = 'https://dns.api.gandi.net/api/v5/zones/zone-uuid/records'
      expect(GandiV5).to receive(:put).with(url, records, 'content-type': 'text/plain')
                                      .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.replace_records(text: records)).to eq 'Confirmation message.'
    end

    it 'Given both' do
      expect { subject.replace_records text: '', records: [] }.to raise_error(
        ArgumentError,
        'you must pass ONE of records: or text:'
      )
    end

    it 'Given nothing' do
      expect { subject.replace_records }.to raise_error ArgumentError, 'you must pass ONE of records: or text:'
    end
  end

  it '#replace_records_for' do
    url = 'https://dns.api.gandi.net/api/v5/zones/zone-uuid/records/name'
    body = '{"items":[{"rrset_type":"TXT","rrset_values":["a"]}]}'
    expect(GandiV5).to receive(:put).with(url, body)
                                    .and_return([nil, { 'message' => 'Confirmation message.' }])
    records = { type: 'TXT', values: ['a'] }
    expect(subject.replace_records_for('name', records)).to eq 'Confirmation message.'
  end

  describe '#replace_??_records_for' do
    it '#replace_a_records_for' do
      url = 'https://dns.api.gandi.net/api/v5/zones/zone-uuid/records/name/A'
      body = '{"rrset_ttl":600,"rrset_values":["192.168.0.1","192.168.0.2"]}'
      expect(GandiV5).to receive(:put).with(url, body)
                                      .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.replace_a_records_for('name', 600, '192.168.0.1', '192.168.0.2')).to eq 'Confirmation message.'
    end

    it '#replace_txt_records_for' do
      url = 'https://dns.api.gandi.net/api/v5/zones/zone-uuid/records/name/TXT'
      body = '{"rrset_ttl":600,"rrset_values":["a","b"]}'
      expect(GandiV5).to receive(:put).with(url, body)
                                      .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.replace_txt_records_for('name', 600, 'a', 'b')).to eq 'Confirmation message.'
    end
  end

  it '#list_domains' do
    expect(GandiV5).to receive(:get).with('https://dns.api.gandi.net/api/v5/zones/zone-uuid/domains')
                                    .and_return([nil, [{ 'fqdn' => 'example.com' }]])
    expect(subject.list_domains).to match_array ['example.com']
  end

  describe '#attach_domain' do
    it 'Given a fqdn' do
      url = 'https://dns.api.gandi.net/api/v5/domains/example.com'
      body = '{"zone_uuid":"zone-uuid"}'
      expect(GandiV5).to receive(:patch).with(url, body)
                                        .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.attach_domain('example.com')).to eq 'Confirmation message.'
    end

    it 'Given something with a fqdn method' do
      url = 'https://dns.api.gandi.net/api/v5/domains/example.com'
      body = '{"zone_uuid":"zone-uuid"}'
      expect(GandiV5).to receive(:patch).with(url, body)
                                        .and_return([nil, { 'message' => 'Confirmation message.' }])
      domain = double GandiV5::LiveDNS::Domain, fqdn: 'example.com'
      expect(subject.attach_domain(domain)).to eq 'Confirmation message.'
    end
  end

  it '#snapshots' do
    returns = double Hash
    expect(GandiV5::LiveDNS::Zone::Snapshot).to receive(:list).with('zone-uuid')
                                                              .and_return(returns)
    expect(subject.snapshots).to be returns
  end

  it '#snapshot' do
    returns = double GandiV5::LiveDNS::Zone::Snapshot
    expect(GandiV5::LiveDNS::Zone::Snapshot).to receive(:fetch).with('zone-uuid', 'snapshot-uuid')
                                                               .and_return(returns)
    expect(subject.snapshot('snapshot-uuid')).to be returns
  end

  it '#take_snapshot' do
    returns = double GandiV5::LiveDNS::Zone::Snapshot
    expect(GandiV5).to receive(:post).with('https://dns.api.gandi.net/api/v5/zones/zone-uuid/snapshots')
                                     .and_return([nil, { 'message' => 'Confirmation message.', 'uuid' => 'snapshot-uuid' }])
    expect(GandiV5::LiveDNS::Zone::Snapshot).to receive(:fetch).with('zone-uuid', 'snapshot-uuid')
                                                               .and_return(returns)
    expect(subject.take_snapshot).to be returns
  end

  it '#update' do
    body = '{"name":"new-name"}'
    expect(GandiV5).to receive(:patch).with('https://dns.api.gandi.net/api/v5/zones/zone-uuid', body)
                                      .and_return([nil, { 'message' => 'Confirmation message.' }])
    expect(subject.update(name: 'new-name')).to eq 'Confirmation message.'
  end

  it '#delete' do
    expect(GandiV5).to receive(:delete).with('https://dns.api.gandi.net/api/v5/zones/zone-uuid')
    subject.delete
  end

  describe '.create' do
    it 'With sharing-id' do
      body = '{"name":"Name"}'
      params = { sharing_id: 'sharing-id' }
      expect(GandiV5).to receive(:post).with('https://dns.api.gandi.net/api/v5/zones', body, params: params)
                                       .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(described_class.create('Name', sharing_id: 'sharing-id')).to eq 'Confirmation message.'
    end

    it 'Without sharing-id' do
      body = '{"name":"Name"}'
      expect(GandiV5).to receive(:post).with('https://dns.api.gandi.net/api/v5/zones', body, params: {})
                                       .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(described_class.create('Name')).to eq 'Confirmation message.'
    end
  end

  describe '.list' do
    subject { described_class.list }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Zone', 'list.yaml'))
      expect(GandiV5).to receive(:get).with('https://dns.api.gandi.net/api/v5/zones')
                                      .and_return([nil, YAML.load_file(body_fixture)])
    end

    its('count') { should eq 1 }
    its('first.uuid') { should eq 'zone-uuid' }
    its('first.name') { should eq 'Name' }
    its('first.sharing_uuid') { should be nil }
    its('first.soa_retry') { should eq 3_600 }
    its('first.soa_minimum') { should eq 900 }
    its('first.soa_refresh') { should eq 10_800 }
    its('first.soa_expire') { should eq 604_800 }
    its('first.soa_serial') { should eq 1_432_798_405 }
    its('first.soa_email') { should eq 'hostmaster.gandi.net.' }
    its('first.soa_primary_ns') { should eq 'a.dns.gandi.net.' }
  end

  describe '.fetch' do
    subject { described_class.fetch 'zone-uuid' }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Zone', 'get.yaml'))
      expect(GandiV5).to receive(:get).with('https://dns.api.gandi.net/api/v5/zones/zone-uuid')
                                      .and_return([nil, YAML.load_file(body_fixture)])
    end

    its('uuid') { should eq 'zone-uuid' }
    its('name') { should eq 'Name' }
    its('sharing_uuid') { should be nil }
    its('soa_retry') { should eq 3_600 }
    its('soa_minimum') { should eq 900 }
    its('soa_refresh') { should eq 10_800 }
    its('soa_expire') { should eq 604_800 }
    its('soa_serial') { should eq 1_432_798_405 }
    its('soa_email') { should eq 'hostmaster.gandi.net.' }
    its('soa_primary_ns') { should eq 'a.dns.gandi.net.' }
  end
end
