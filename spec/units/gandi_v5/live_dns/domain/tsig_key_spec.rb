# frozen_string_literal: true

describe GandiV5::LiveDNS::Domain::TsigKey do
  subject do
    described_class.new(
      uuid: 'key-uuid',
      name: 'key-name',
      secret: 'key-secret',
      config_examples: { test: 'test config sample' }
    )
  end

  describe '.create' do
    it 'Without sharing_id' do
      url = 'https://api.gandi.net/v5/livedns/axfr/tsig'
      created = { 'href' => '', 'id' => 'created-key-uuid', 'key_name' => 'based on id' }
      returns = double described_class

      expect(GandiV5).to receive(:post).with(url).and_return([nil, created])
      expect(described_class).to receive(:fetch).with('created-key-uuid')
                                                .and_return(returns)
      expect(described_class.create).to be returns
    end

    it 'With sharing_id' do
      url = 'https://api.gandi.net/v5/livedns/axfr/tsig?sharing_id=sharing-id'
      created = { 'href' => '', 'id' => 'created-key-uuid', 'key_name' => 'based on id' }
      returns = double described_class

      expect(GandiV5).to receive(:post).with(url).and_return([nil, created])
      expect(described_class).to receive(:fetch).with('created-key-uuid')
                                                .and_return(returns)
      expect(described_class.create('sharing-id')).to be returns
    end
  end

  it '.list' do
    body_fixture = File.expand_path(
      File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Domain_TsigKey', 'list.yml')
    )
    url = 'https://api.gandi.net/v5/livedns/axfr/tsig'

    if RUBY_VERSION >= '3.1.0'
      expect(GandiV5).to receive(:get).with(url).and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
    else
      expect(GandiV5).to receive(:get).with(url).and_return([nil, YAML.load_file(body_fixture)])
    end
    results = described_class.list
    result = results.first
    expect(results.count).to eq 1
    expect(result.uuid).to eq 'key-uuid'
    expect(result.name).to eq 'key-name'
    expect(result.secret).to eq 'key-secret'
  end

  describe '.fetch' do
    subject { described_class.fetch 'key-uuid' }

    before :each do
      body_fixture = File.expand_path(
        File.join('spec', 'fixtures', 'bodies', 'GandiV5_LiveDNS_Domain_TsigKey', 'fetch.yml')
      )
      url = 'https://api.gandi.net/v5/livedns/axfr/tsig/key-uuid'
      if RUBY_VERSION >= '3.1.0'
        expect(GandiV5).to receive(:get).with(url)
                                        .and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
      else
        expect(GandiV5).to receive(:get).with(url)
                                        .and_return([nil, YAML.load_file(body_fixture)])
      end
    end

    its('uuid') { should eq 'key-uuid' }
    its('name') { should eq 'key-name' }
    its('secret') { should eq 'key-secret' }
    its('config_examples') do
      should eq(
        {
          bind: 'bind-sample',
          knot: 'knot-sample',
          nsd: 'nsd-sample',
          powerdns: 'powerdns-sample'
        }
      )
    end
  end
end
