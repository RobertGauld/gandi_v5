# frozen_string_literal: true

describe GandiV5::LiveDNS::Domain do
  subject do
    described_class.new fqdn: 'example.com', automatic_snapshots: false
  end

  describe '#refresh' do
    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Domain', 'fetch.yml'))
      if RUBY_VERSION >= '3.1.0'
        expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/livedns/domains/example.com')
                                        .and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
      else
        expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/livedns/domains/example.com')
                                        .and_return([nil, YAML.load_file(body_fixture)])
      end
      subject.refresh
    end

    its('fqdn') { should eq 'example.com' }
    its('automatic_snapshots') { should be true }
  end

  it '#update' do
    url = 'https://api.gandi.net/v5/livedns/domains/example.com'
    body = '{"automatic_snapshots":true}'
    expect(GandiV5).to receive(:patch).with(url, body)
                                      .and_return([nil, { 'message' => 'Confirmation message.' }])
    expect(subject.update(automatic_snapshots: true)).to eq 'Confirmation message.'
    expect(subject.automatic_snapshots).to be true
  end

  describe '#fetch_records' do
    let(:url) { 'https://api.gandi.net/v5/livedns/domains/example.com/records' }
    it 'All of them' do
      expect(GandiV5).to receive(:paginated_get).with(url, (1..), 100)
                                                .and_yield([])
      expect(subject.fetch_records).to eq []
    end

    it 'All for a name' do
      expect(GandiV5).to receive(:paginated_get).with("#{url}/name", (1..), 100)
                                                .and_yield([])
      expect(subject.fetch_records('name')).to eq []
    end

    it 'A type for a name' do
      record = {
        'rrset_type' => 'TXT',
        'rrset_name' => 'name',
        'rrset_ttl' => 600,
        'rrset_values' => %w[a b]
      }
      expect(GandiV5).to receive(:paginated_get).with("#{url}/name/TXT", (1..), 100)
                                                .and_yield([record])

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
      url = 'https://api.gandi.net/v5/livedns/domains/example.com/records'
      expect(GandiV5).to receive(:get).with(url, accept: 'text/plain').and_return([nil, 'returned'])
      expect(subject.fetch_zone_lines).to eq 'returned'
    end

    it 'All for a name' do
      url = 'https://api.gandi.net/v5/livedns/domains/example.com/records/name'
      expect(GandiV5).to receive(:get).with(url, accept: 'text/plain').and_return([nil, 'returned'])
      expect(subject.fetch_zone_lines('name')).to eq 'returned'
    end

    it 'A type for a name' do
      url = 'https://api.gandi.net/v5/livedns/domains/example.com/records/name/TXT'
      expect(GandiV5).to receive(:get).with(url, accept: 'text/plain').and_return([nil, 'returned'])
      expect(subject.fetch_zone_lines('name', 'TXT')).to eq 'returned'
    end

    it 'Invalid type' do
      expect { subject.fetch_zone_lines 'name', 'INVALID-TYPE' }.to raise_error ArgumentError
    end
  end

  describe '#add_record' do
    it 'Success' do
      url = 'https://api.gandi.net/v5/livedns/domains/example.com/records'
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
      url = 'https://api.gandi.net/v5/livedns/domains/example.com/records'
      expect(GandiV5).to receive(:delete).with(url).and_return([nil, nil])
      subject.delete_records
    end

    it 'All for a name' do
      url = 'https://api.gandi.net/v5/livedns/domains/example.com/records/name'
      expect(GandiV5).to receive(:delete).with(url).and_return([nil, nil])
      subject.delete_records 'name'
    end

    it 'A type for a name' do
      url = 'https://api.gandi.net/v5/livedns/domains/example.com/records/name/TXT'
      expect(GandiV5).to receive(:delete).with(url).and_return([nil, nil])
      subject.delete_records 'name', 'TXT'
    end

    it 'Invalid type' do
      expect { subject.delete_records 'name', 'INVALID-TYPE' }.to raise_error ArgumentError
    end
  end

  describe '#replace_records' do
    it 'All of them' do
      url = 'https://api.gandi.net/v5/livedns/domains/example.com/records'
      body = '{"items":[{"rrset_name":"name","rrset_type":"TXT","rrset_values":["a"]}]}'
      expect(GandiV5).to receive(:put).with(url, body)
                                      .and_return([nil, { 'message' => 'Confirmation message.' }])
      records = [{ name: 'name', type: 'TXT', values: ['a'] }]
      expect(subject.replace_records(records)).to eq 'Confirmation message.'
    end

    it 'All for a name' do
      url = 'https://api.gandi.net/v5/livedns/domains/example.com/records/name'
      body = '{"items":[{"rrset_type":"TXT","rrset_values":["a"]}]}'
      expect(GandiV5).to receive(:put).with(url, body)
                                      .and_return([nil, { 'message' => 'Confirmation message.' }])
      records = [{ type: 'TXT', values: ['a'] }]
      expect(subject.replace_records(records, name: 'name')).to eq 'Confirmation message.'
    end

    it 'All of a type for a name' do
      url = 'https://api.gandi.net/v5/livedns/domains/example.com/records/name/TXT'
      body = '{"rrset_values":["a"]}'
      expect(GandiV5).to receive(:put).with(url, body)
                                      .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.replace_records(['a'], name: 'name', type: 'TXT')).to eq 'Confirmation message.'
    end

    it 'Given type but no name' do
      expect(GandiV5).to_not receive(:put)
      expect { subject.replace_records(['a'], type: 'TXT') }.to raise_error ArgumentError, 'missing keyword: name'
    end
  end

  it '#replace_zone_lines' do
    records = [
      '@ 86400 IN A 192.168.0.1',
      '* 86400 IN A 192.168.0.1'
    ].join("\n")

    url = 'https://api.gandi.net/v5/livedns/domains/example.com/records'
    expect(GandiV5).to receive(:put).with(url, records, 'content-type': 'text/plain')
                                    .and_return([nil, { 'message' => 'Confirmation message.' }])
    expect(subject.replace_zone_lines(records)).to eq 'Confirmation message.'
  end

  describe '#name_servers' do
    let(:nameservers) { double Array }

    it 'Already fetched' do
      subject.instance_exec(nameservers) { |ns| @name_servers = ns }
      expect(subject).to_not receive(:fetch_name_servers)
      expect(subject.name_servers).to be nameservers
    end

    it 'Not already fetched' do
      expect(subject).to receive(:fetch_name_servers).and_return(nameservers)
      expect(subject.name_servers).to be nameservers
    end
  end

  it '#fetch_name_servers' do
    body_fixture = File.expand_path(
      File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Domain', 'nameservers.yml')
    )

    if RUBY_VERSION >= '3.1.0'
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/livedns/domains/example.com/nameservers')
                                      .and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
    else
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/livedns/domains/example.com/nameservers')
                                      .and_return([nil, YAML.load_file(body_fixture)])
    end

    expect(subject.fetch_name_servers).to match_array ['a.example.com', 'b.example.com']
  end

  describe '#dnssec_keys' do
    let(:dnsseckeys) { double Array }

    it 'Already fetched' do
      subject.instance_exec(dnsseckeys) { |k| @dnssec_keys = k }
      expect(subject).to_not receive(:fetch_dnssec_keys)
      expect(subject.dnssec_keys).to be dnsseckeys
    end

    it 'Not already fetched' do
      expect(subject).to receive(:fetch_dnssec_keys).and_return(dnsseckeys)
      expect(subject.dnssec_keys).to be dnsseckeys
    end
  end

  it '#fetch_dnssec_keys' do
    keys = double Array
    expect(GandiV5::LiveDNS::Domain::DnssecKey).to receive(:list).with('example.com')
                                                                 .and_return(keys)

    expect(subject.fetch_dnssec_keys).to be keys
    expect(subject.instance_exec { @dnssec_keys }).to be keys
  end

  describe '#tsig_keys' do
    let(:tsigkeys) { double Array }

    it 'Already fetched' do
      subject.instance_exec(tsigkeys) { |k| @tsig_keys = k }
      expect(subject).to_not receive(:fetch_tsig_keys)
      expect(subject.tsig_keys).to be tsigkeys
    end

    it 'Not already fetched' do
      expect(subject).to receive(:fetch_tsig_keys).and_return(tsigkeys)
      expect(subject.tsig_keys).to be tsigkeys
    end
  end

  it '#fetch_tsig_keys' do
    body_fixture = File.expand_path(
      File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Domain', 'list_tsig.yml')
    )
    url = 'https://api.gandi.net/v5/livedns/domains/example.com/axfr/tsig'

    if RUBY_VERSION >= '3.1.0'
      expect(GandiV5).to receive(:get).with(url).and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
    else
      expect(GandiV5).to receive(:get).with(url).and_return([nil, YAML.load_file(body_fixture)])
    end
    results = subject.fetch_tsig_keys
    result = results.first
    expect(results.count).to eq 1
    expect(result.uuid).to eq 'key-uuid'
    expect(result.name).to eq 'key-name'
  end

  describe '#add_tsig_key' do
    let(:url) { 'https://api.gandi.net/v5/livedns/domains/example.com/axfr/tsig/key-uuid' }

    it 'Passed a key' do
      key = GandiV5::LiveDNS::Domain::TsigKey.new uuid: 'key-uuid'
      expect(GandiV5).to receive(:put).with(url).and_return([nil, nil])
      subject.add_tsig_key key
    end

    it 'Passed a string' do
      expect(GandiV5).to receive(:put).with(url).and_return([nil, nil])
      subject.add_tsig_key 'key-uuid'
    end

    it 'With sharing_id' do
      expect(GandiV5).to receive(:put).with("#{url}?sharing_id=sharing-id").and_return([nil, nil])
      subject.add_tsig_key 'key-uuid', sharing_id: 'sharing-id'
    end
  end

  describe '#remove_tsig_key' do
    let(:url) { 'https://api.gandi.net/v5/livedns/domains/example.com/axfr/tsig/key-uuid' }

    it 'Passed a key' do
      key = GandiV5::LiveDNS::Domain::TsigKey.new uuid: 'key-uuid'
      expect(GandiV5).to receive(:delete).with(url).and_return([nil, nil])
      subject.remove_tsig_key key
    end

    it 'Passed a string' do
      expect(GandiV5).to receive(:delete).with(url).and_return([nil, nil])
      subject.remove_tsig_key 'key-uuid'
    end

    it 'With sharing_id' do
      expect(GandiV5).to receive(:delete).with("#{url}?sharing_id=sharing-id").and_return([nil, nil])
      subject.remove_tsig_key 'key-uuid', sharing_id: 'sharing-id'
    end
  end

  describe '#axfr_clients' do
    let(:clients) { double Array }

    it 'Already fetched' do
      subject.instance_exec(clients) { |k| @axfr_clients = k }
      expect(subject).to_not receive(:fetch_axfr_clients)
      expect(subject.axfr_clients).to be clients
    end

    it 'Not already fetched' do
      expect(subject).to receive(:fetch_axfr_clients).and_return(clients)
      expect(subject.axfr_clients).to be clients
    end
  end

  it '#fetch_axfr_clients' do
    url = 'https://api.gandi.net/v5/livedns/domains/example.com/axfr/slaves'
    expect(GandiV5).to receive(:get).with(url).and_return([nil, ['1.2.3.4']])
    expect(subject.fetch_axfr_clients).to match_array ['1.2.3.4']
  end

  it '#add_axfr_client' do
    url = 'https://api.gandi.net/v5/livedns/domains/example.com/axfr/slaves/1.2.3.4'
    expect(GandiV5).to receive(:put).with(url).and_return([nil, nil])
    subject.add_axfr_client '1.2.3.4'
  end

  it '#remove_axfr_client' do
    url = 'https://api.gandi.net/v5/livedns/domains/example.com/axfr/slaves/1.2.3.4'
    expect(GandiV5).to receive(:delete).with(url).and_return([nil, nil])
    subject.remove_axfr_client '1.2.3.4'
  end

  describe '.list' do
    let(:body_fixture) do
      File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Domain', 'list.yml'))
    end
    let(:url) { 'https://api.gandi.net/v5/livedns/domains' }

    it 'With default parameters' do
      headers = { params: { page: 1, per_page: 100 } }
      if RUBY_VERSION >= '3.1.0'
        expect(GandiV5).to receive(:get).with(url, headers)
                                        .and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
      else
        expect(GandiV5).to receive(:get).with(url, headers)
                                        .and_return([nil, YAML.load_file(body_fixture)])
      end

      subject = described_class.list
      expect(subject.count).to eq 1
      expect(subject.first).to eq 'example.com'
    end

    it 'Keeps fetching until no more to get' do
      headers1 = { params: { page: 1, per_page: 1 } }
      headers2 = { params: { page: 2, per_page: 1 } }
      if RUBY_VERSION >= '3.1.0'
        expect(GandiV5).to receive(:get).with(url, headers1)
                                        .ordered
                                        .and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
      else
        expect(GandiV5).to receive(:get).with(url, headers1)
                                        .ordered
                                        .and_return([nil, YAML.load_file(body_fixture)])
      end
      expect(GandiV5).to receive(:get).with(url, headers2)
                                      .ordered
                                      .and_return([nil, []])

      expect(described_class.list(per_page: 1).count).to eq 1
    end

    it 'Given a range as page number' do
      headers = { params: { page: 1, per_page: 1 } }
      if RUBY_VERSION >= '3.1.0'
        expect(GandiV5).to receive(:get).with(url, headers)
                                        .and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
      else
        expect(GandiV5).to receive(:get).with(url, headers)
                                        .and_return([nil, YAML.load_file(body_fixture)])
      end

      described_class.list(page: (1..1), per_page: 1)
    end

    describe 'Passes optional query params' do
      it 'per_page' do
        headers = { params: { page: 1, per_page: 10 } }
        expect(GandiV5).to receive(:get).with(url, headers)
                                        .and_return([nil, []])
        described_class.list(per_page: 10)
      end

      it 'sharing_id' do
        headers = { params: { sharing_id: 'SHARING-UUID', page: 1, per_page: 100 } }
        expect(GandiV5).to receive(:get).with(url, headers)
                                        .and_return([nil, []])
        described_class.list(sharing_id: 'SHARING-UUID')
      end
    end
  end

  describe '.fetch' do
    subject { described_class.fetch 'example.com' }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Domain', 'fetch.yml'))
      if RUBY_VERSION >= '3.1.0'
        expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/livedns/domains/example.com')
                                        .and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
      else
        expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/livedns/domains/example.com')
                                        .and_return([nil, YAML.load_file(body_fixture)])
      end
    end

    its('fqdn') { should eq 'example.com' }
    its('automatic_snapshots') { should be true }
  end

  describe '.create' do
    let(:url) { 'https://api.gandi.net/v5/livedns/domains' }
    let(:response) do
      double RestClient::Response, headers: { location: 'https://api.gandi.net/v5/livedns/domains/example.com' }
    end

    it 'When passed only fqdn' do
      returns = double described_class
      body = '{"fqdn":"example.com","zone":{}}'
      expect(GandiV5).to receive(:post).with(url, body).and_return([response, nil])
      expect(described_class).to receive(:fetch).with('example.com').and_return(returns)
      expect(described_class.create('example.com')).to be returns
    end

    it 'When passed soa_ttl' do
      body = '{"fqdn":"example.com","zone":{"ttl":123}}'
      expect(GandiV5).to receive(:post).with(url, body).and_return([response, nil])
      expect(described_class).to receive(:fetch).with('example.com').and_return(nil)
      described_class.create('example.com', soa_ttl: 123)
    end

    it 'When passed records' do
      body = '{"fqdn":"example.com","zone":{"items":' \
             '[{"rrset_type":"TXT","rrset_ttl":234,"rrset_name":"test","rrset_values":["value"]}]}}'
      record = GandiV5::LiveDNS::Domain::Record.new name: 'test', type: 'TXT', ttl: 234, values: ['value']
      expect(GandiV5).to receive(:post).with(url, body).and_return([response, nil])
      expect(described_class).to receive(:fetch).with('example.com').and_return(nil)
      described_class.create('example.com', [record])
    end

    it 'When passed sharing_id' do
      body = '{"fqdn":"example.com","zone":{}}'
      expect(GandiV5).to receive(:post).with("#{url}?sharing_id=organization_id", body).and_return([response, nil])
      expect(described_class).to receive(:fetch).with('example.com').and_return(nil)
      described_class.create('example.com', sharing_id: 'organization_id')
    end
  end

  it '.record_types' do
    list = double Array
    expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/livedns/dns/rrtypes')
                                    .and_return([nil, list])
    expect(described_class.record_types).to be list
  end

  it '.generic_name_servers' do
    list = double Array
    expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/livedns/nameservers/example.com')
                                    .and_return([nil, list])
    expect(described_class.generic_name_servers('example.com')).to be list
  end
end
