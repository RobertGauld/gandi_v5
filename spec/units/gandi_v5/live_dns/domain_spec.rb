# frozen_string_literal: true

describe GandiV5::LiveDNS::Domain do
  subject do
    described_class.new fqdn: 'example.com', zone_uuid: 'zone-uuid'
  end

  describe '#refresh' do
    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Domain', 'get.yaml'))
      expect(GandiV5).to receive(:get).with('https://dns.api.gandi.net/api/v5/domains/example.com')
                                      .and_return([nil, YAML.load_file(body_fixture)])
      subject.refresh
    end

    its('fqdn') { should eq 'example.com' }
    its('zone_uuid') { should eq 'zone-uuid' }
  end

  describe '#fetch_records' do
    it 'All of them' do
      expect(GandiV5).to receive(:get).with('https://dns.api.gandi.net/api/v5/domains/example.com/records')
                                      .and_return([nil, []])

      expect(subject.fetch_records).to eq []
    end

    it 'All for a name' do
      expect(GandiV5).to receive(:get).with('https://dns.api.gandi.net/api/v5/domains/example.com/records/name')
                                      .and_return([nil, []])

      expect(subject.fetch_records('name')).to eq []
    end

    it 'A type for a name' do
      expect(GandiV5).to receive(:get).with('https://dns.api.gandi.net/api/v5/domains/example.com/records/name/TXT')
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
      url = 'https://dns.api.gandi.net/api/v5/domains/example.com/records'
      expect(GandiV5).to receive(:get).with(url, accept: 'text/plain').and_return([nil, 'returned'])
      expect(subject.fetch_zone_lines).to eq 'returned'
    end

    it 'All for a name' do
      url = 'https://dns.api.gandi.net/api/v5/domains/example.com/records/name'
      expect(GandiV5).to receive(:get).with(url, accept: 'text/plain').and_return([nil, 'returned'])
      expect(subject.fetch_zone_lines('name')).to eq 'returned'
    end

    it 'A type for a name' do
      url = 'https://dns.api.gandi.net/api/v5/domains/example.com/records/name/TXT'
      expect(GandiV5).to receive(:get).with(url, accept: 'text/plain').and_return([nil, 'returned'])
      expect(subject.fetch_zone_lines('name', 'TXT')).to eq 'returned'
    end

    it 'Invalid type' do
      expect { subject.fetch_zone_lines 'name', 'INVALID-TYPE' }.to raise_error ArgumentError
    end
  end

  describe '#add_record' do
    it 'Success' do
      url = 'https://dns.api.gandi.net/api/v5/domains/example.com/records'
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
      url = 'https://dns.api.gandi.net/api/v5/domains/example.com/records'
      expect(GandiV5).to receive(:delete).with(url).and_return([nil, nil])
      subject.delete_records
    end

    it 'All for a name' do
      url = 'https://dns.api.gandi.net/api/v5/domains/example.com/records/name'
      expect(GandiV5).to receive(:delete).with(url).and_return([nil, nil])
      subject.delete_records 'name'
    end

    it 'A type for a name' do
      url = 'https://dns.api.gandi.net/api/v5/domains/example.com/records/name/TXT'
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

      url = 'https://dns.api.gandi.net/api/v5/domains/example.com/records'
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

      url = 'https://dns.api.gandi.net/api/v5/domains/example.com/records'
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
    url = 'https://dns.api.gandi.net/api/v5/domains/example.com/records/name'
    body = '{"items":[{"rrset_type":"TXT","rrset_values":["a"]}]}'
    expect(GandiV5).to receive(:put).with(url, body)
                                    .and_return([nil, { 'message' => 'Confirmation message.' }])
    records = { type: 'TXT', values: ['a'] }
    expect(subject.replace_records_for('name', records)).to eq 'Confirmation message.'
  end

  describe '#replace_??_records_for' do
    it '#replace_a_records_for' do
      url = 'https://dns.api.gandi.net/api/v5/domains/example.com/records/name/A'
      body = '{"rrset_ttl":600,"rrset_values":["192.168.0.1","192.168.0.2"]}'
      expect(GandiV5).to receive(:put).with(url, body)
                                      .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.replace_a_records_for('name', 600, '192.168.0.1', '192.168.0.2')).to eq 'Confirmation message.'
    end

    it '#replace_txt_records_for' do
      url = 'https://dns.api.gandi.net/api/v5/domains/example.com/records/name/TXT'
      body = '{"rrset_ttl":600,"rrset_values":["a","b"]}'
      expect(GandiV5).to receive(:put).with(url, body)
                                      .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.replace_txt_records_for('name', 600, 'a', 'b')).to eq 'Confirmation message.'
    end
  end

  describe '#change_zone' do
    it 'Given a uuid' do
      url = 'https://dns.api.gandi.net/api/v5/domains/example.com'
      body = '{"zone_uuid":"zone-uuid"}'
      expect(GandiV5).to receive(:patch).with(url, body)
                                        .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.change_zone('zone-uuid')).to eq 'Confirmation message.'
      expect(subject.zone_uuid).to eq 'zone-uuid'
    end

    it 'Given something with a uuid method' do
      url = 'https://dns.api.gandi.net/api/v5/domains/example.com'
      body = '{"zone_uuid":"zone-uuid"}'
      expect(GandiV5).to receive(:patch).with(url, body)
                                        .and_return([nil, { 'message' => 'Confirmation message.' }])
      zone = double GandiV5::LiveDNS::Zone, uuid: 'zone-uuid'
      expect(subject.change_zone(zone)).to eq 'Confirmation message.'
      expect(subject.zone_uuid).to eq 'zone-uuid'
    end
  end

  describe '.list' do
    subject { described_class.list }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Domain', 'list.yaml'))
      expect(GandiV5).to receive(:get).with('https://dns.api.gandi.net/api/v5/domains')
                                      .and_return([nil, YAML.load_file(body_fixture)])
    end

    its('count') { should eq 1 }
    its('first.fqdn') { should eq 'example.com' }
    its('first.zone_uuid') { should be nil }
  end

  describe '.fetch' do
    subject { described_class.fetch 'example.com' }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Domain', 'get.yaml'))
      expect(GandiV5).to receive(:get).with('https://dns.api.gandi.net/api/v5/domains/example.com')
                                      .and_return([nil, YAML.load_file(body_fixture)])
    end

    its('fqdn') { should eq 'example.com' }
    its('zone_uuid') { should eq 'zone-uuid' }
  end
end
