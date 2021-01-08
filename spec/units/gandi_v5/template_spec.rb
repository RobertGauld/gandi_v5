# frozen_string_literal: true

describe GandiV5::Template do
  subject do
    described_class.new uuid: 'template-uuid'
  end

  describe '#refresh' do
    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Template', 'fetch.yml'))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/template/templates/template-uuid')
                                      .and_return([nil, YAML.load_file(body_fixture)])
      subject.refresh
    end

    its('description') { should eq 'description of template' }
    its('editable') { should be true }
    its('uuid') { should eq 'template-uuid' }
    its('name') { should eq 'template name' }
    its('organisation_name') { should eq 'org-name' }
    its('sharing_space.uuid') { should eq 'sharing-space-uuid' }
    its('sharing_space.name') { should eq 'sharing-space-name' }
    its('sharing_space.reseller') { should be true }
    its('sharing_space.type') { should eq 'user' }
    its('sharing_space.reseller_details.uuid') { should eq 'reseller-uuid' }
    its('sharing_space.reseller_details.name') { should eq 'reseller-name' }
    its('variables') { should eq [] }

    its('payload.dns_records.count') { should eq 1 }
    its('payload.dns_records.first.name') { should eq 'record-name' }
    its('payload.dns_records.first.type') { should eq 'TXT' }
    its('payload.dns_records.first.values') { should eq ['record-value'] }
    its('payload.dns_records.first.ttl') { should eq 600 }

    its('payload.mailboxes') { should eq ['user-name'] }

    its('payload.name_servers') { should eq ['1.1.1.1'] }

    its('payload.web_redirects.count') { should eq 1 }
    its('payload.web_redirects.first.type') { should eq :http301 }
    its('payload.web_redirects.first.target') { should eq 'https://example.com/here' }
    its('payload.web_redirects.first.fqdn') { should eq 'here.example.com' }
    its('payload.web_redirects.first.override') { should be true }
    its('payload.web_redirects.first.protocol') { should eq :https }
  end

  describe '#update' do
    let(:url) { 'https://api.gandi.net/v5/template/templates/template-uuid' }
    let(:updated_template) { double GandiV5::Template }

    before :each do
      expect(subject).to receive(:refresh).and_return(updated_template)
    end

    it 'nothing' do
      expect(GandiV5).to receive(:patch).with(url, '{}')
      expect(subject.update).to be updated_template
    end

    it 'name' do
      expect(GandiV5).to receive(:patch).with(url, '{"name":"new"}')
      expect(subject.update(name: 'new')).to be updated_template
    end

    it 'description' do
      expect(GandiV5).to receive(:patch).with(url, '{"description":"new"}')
      expect(subject.update(description: 'new')).to be updated_template
    end

    it 'dns_records' do
      expect(GandiV5).to receive(:patch).with(url, '{"payload":{"dns:records":{"default":true}}}')
      expect(subject.update(dns_records: :default)).to be updated_template
    end

    it 'mailboxes' do
      expect(GandiV5).to receive(:patch).with(url, '{"payload":{"domain:mailboxes":{"values":[{"login":"user"}]}}}')
      expect(subject.update(mailboxes: ['user'])).to be updated_template
    end

    it 'name servers' do
      expect(GandiV5).to receive(:patch).with(url, '{"payload":{"domain:nameservers":{"service":"livedns"}}}')
      expect(subject.update(name_servers: :livedns)).to be updated_template
    end

    it 'web redirects' do
      expect(GandiV5).to receive(:patch).with(url, '{"payload":{"domain:webredirs":{"values":[]}}}')
      expect(subject.update(web_redirects: [])).to be updated_template
    end
  end

  it '#delete' do
    url = 'https://api.gandi.net/v5/template/templates/template-uuid'
    expect(GandiV5).to receive(:delete).with(url)
                                       .and_return([nil, { 'message' => 'Confirmation message.' }])
    expect(subject.delete).to be nil
  end

  it '#apply' do
    url = 'https://api.gandi.net/v5/template/templates/template-uuid'
    body = { 'dispatch_href' => 'https://api.gandi.net/v5/template/dispatch/dispatch-uuid' }
    expect(GandiV5).to receive(:post).with(url, '{"object_type":"domain","object_id":"domain-uuid"}')
                                     .and_return([nil, body])
    expect(subject.apply('domain-uuid')).to eq 'dispatch-uuid'
  end

  describe '.list' do
    subject { described_class.list }

    before :each do
      expect(GandiV5).to receive(:paginated_get).with(url, (1..), 100)
                                                .and_yield(YAML.load_file(body_fixture))
    end

    let(:body_fixture) { File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Template', 'list.yml')) }
    let(:url) { 'https://api.gandi.net/v5/template/templates' }

    its('count') { should eq 1 }

    its('first.description') { should eq 'description of template' }
    its('first.editable') { should be true }
    its('first.uuid') { should eq 'template-uuid' }
    its('first.name') { should eq 'template name' }
    its('first.organisation_name') { should eq 'org-name' }
    its('first.sharing_space.uuid') { should eq 'sharing-space-uuid' }
    its('first.sharing_space.name') { should eq 'sharing-space-name' }
    its('first.sharing_space.reseller') { should be true }
    its('first.sharing_space.type') { should eq 'user' }
    its('first.sharing_space.reseller_details.uuid') { should eq 'reseller-uuid' }
    its('first.sharing_space.reseller_details.name') { should eq 'reseller-name' }
  end

  describe '.fetch' do
    subject { described_class.fetch 'template-uuid' }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Template', 'fetch.yml'))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/template/templates/template-uuid')
                                      .and_return([nil, YAML.load_file(body_fixture)])
    end

    its('description') { should eq 'description of template' }
    its('editable') { should be true }
    its('uuid') { should eq 'template-uuid' }
    its('name') { should eq 'template name' }
    its('organisation_name') { should eq 'org-name' }
    its('sharing_space.uuid') { should eq 'sharing-space-uuid' }
    its('sharing_space.name') { should eq 'sharing-space-name' }
    its('sharing_space.reseller') { should be true }
    its('sharing_space.type') { should eq 'user' }
    its('sharing_space.reseller_details.uuid') { should eq 'reseller-uuid' }
    its('sharing_space.reseller_details.name') { should eq 'reseller-name' }
    its('variables') { should eq [] }

    its('payload.dns_records.count') { should eq 1 }
    its('payload.dns_records.first.name') { should eq 'record-name' }
    its('payload.dns_records.first.type') { should eq 'TXT' }
    its('payload.dns_records.first.values') { should eq ['record-value'] }
    its('payload.dns_records.first.ttl') { should eq 600 }

    its('payload.mailboxes') { should eq ['user-name'] }

    its('payload.name_servers') { should eq ['1.1.1.1'] }

    its('payload.web_redirects.count') { should eq 1 }
    its('payload.web_redirects.first.type') { should eq :http301 }
    its('payload.web_redirects.first.target') { should eq 'https://example.com/here' }
    its('payload.web_redirects.first.fqdn') { should eq 'here.example.com' }
    its('payload.web_redirects.first.override') { should be true }
    its('payload.web_redirects.first.protocol') { should eq :https }
  end

  describe '.fetch' do
    it 'With default dns records' do
      body = { 'payload' => { 'dns:records' => { 'default' => true, 'records' => [] } } }
      expect(GandiV5).to receive(:get).and_return([nil, body])
      expect(described_class.fetch('template-uuid').payload.dns_records).to be :default
    end

    it 'With livedns name servers' do
      body = { 'payload' => { 'domain:nameservers' => { 'service' => 'livedns', 'addresses' => [] } } }
      expect(GandiV5).to receive(:get).and_return([nil, body])
      expect(described_class.fetch('template-uuid').payload.name_servers).to be :livedns
    end
  end

  describe '.create' do
    let(:url) { 'https://api.gandi.net/v5/template/templates' }

    it 'Without sharing_id' do
      body = {
        'name' => 'template name',
        'description' => 'description of template',
        'payload' => {
          'dns:records' => {
            'default' => false,
            'records' => [{ 'name' => 'host', 'ttl' => 600, 'type' => 'TXT', 'values' => ['value'] }]
          },
          'domain:mailboxes' => { 'values' => [{ 'login' => 'user1' }, { 'login' => 'user2' }] },
          'domain:nameservers' => {
            'service' => 'custom',
            'addresses' => ['1.1.1.1', '2.2.2.2']
          },
          'domain:webredirs' => {
            'values' => [
              {
                'type' => 'http302',
                'url' => 'example.com',
                'host' => 'here',
                'override' => true,
                'protocol' => 'httpsonly'
              }
            ]
          }
        }
      }.to_json
      response = double(
        RestClient::Response,
        headers: { location: 'https://api.gandi.net/v5/template/templates/template-uuid' }
      )
      created_template = double GandiV5::Template
      expect(GandiV5).to receive(:post).with(url, body).and_return([response, 'Confirmation message'])
      expect(described_class).to receive(:fetch).with('template-uuid').and_return(created_template)

      create = {
        name: 'template name',
        description: 'description of template',
        'dns_records': [{ name: 'host', ttl: 600, type: 'TXT', values: ['value'] }],
        'mailboxes': %w[user1 user2],
        'name_servers': ['1.1.1.1', '2.2.2.2'],
        'web_redirects': [
          { type: :http302, target: 'example.com', host: 'here', override: true, protocol: :https_only }
        ]
      }
      expect(described_class.create(**create)).to be created_template
    end

    it 'With a :permanent web redirect' do
      url = 'https://api.gandi.net/v5/template/templates'
      body = '{"name":"n","description":"d","payload":{"domain:webredirs":{"values":[{"type":"http301","url":""}]}}}'
      response = double(
        RestClient::Response,
        headers: { location: 'https://api.gandi.net/v5/template/templates/template-uuid' }
      )
      expect(GandiV5).to receive(:post).with(url, body).and_return([response, 'Confirmation message'])
      expect(described_class).to receive(:fetch).with('template-uuid').and_return(double(GandiV5::Template))

      described_class.create(
        name: 'n',
        description: 'd',
        web_redirects: [{ type: :permanent, target: '' }]
      )
    end

    it 'With a :temporary web redirect' do
      url = 'https://api.gandi.net/v5/template/templates'
      body = '{"name":"n","description":"d","payload":{"domain:webredirs":{"values":[{"type":"http302","url":""}]}}}'
      response = double(
        RestClient::Response,
        headers: { location: 'https://api.gandi.net/v5/template/templates/template-uuid' }
      )
      expect(GandiV5).to receive(:post).with(url, body).and_return([response, 'Confirmation message'])
      expect(described_class).to receive(:fetch).with('template-uuid').and_return(double(GandiV5::Template))

      described_class.create(
        name: 'n',
        description: 'd',
        web_redirects: [{ type: :temporary, target: '' }]
      )
    end

    it 'With a :found web redirect' do
      url = 'https://api.gandi.net/v5/template/templates'
      body = '{"name":"n","description":"d","payload":{"domain:webredirs":{"values":[{"type":"http302","url":""}]}}}'
      response = double(
        RestClient::Response,
        headers: { location: 'https://api.gandi.net/v5/template/templates/template-uuid' }
      )
      expect(GandiV5).to receive(:post).with(url, body).and_return([response, 'Confirmation message'])
      expect(described_class).to receive(:fetch).with('template-uuid').and_return(double(GandiV5::Template))

      described_class.create(
        name: 'n',
        description: 'd',
        web_redirects: [{ type: :found, target: '' }]
      )
    end

    it 'With sharing_id' do
      url = 'https://api.gandi.net/v5/template/templates?sharing_id=sharing-uuid'
      body = '{"name":"n","description":"d","payload":{}}'
      response = double(
        RestClient::Response,
        headers: { location: 'https://api.gandi.net/v5/template/templates/template-uuid' }
      )
      expect(GandiV5).to receive(:post).with(url, body).and_return([response, 'Confirmation message'])
      expect(described_class).to receive(:fetch).with('template-uuid').and_return(double(GandiV5::Template))

      described_class.create name: 'n', description: 'd', sharing_id: 'sharing-uuid'
    end

    it 'Use livedns name servers' do
      body = '{"name":"n","description":"d","payload":{"domain:nameservers":{"service":"livedns"}}}'
      response = double(
        RestClient::Response,
        headers: { location: 'https://api.gandi.net/v5/template/templates/template-uuid' }
      )
      expect(GandiV5).to receive(:post).with(url, body).and_return([response, 'Confirmation message'])
      expect(described_class).to receive(:fetch).with('template-uuid').and_return(double(GandiV5::Template))

      described_class.create name: 'n', description: 'd', name_servers: :livedns
    end

    it 'Use default DNS records' do
      body = '{"name":"n","description":"d","payload":{"dns:records":{"default":true}}}'
      response = double(
        RestClient::Response,
        headers: { location: 'https://api.gandi.net/v5/template/templates/template-uuid' }
      )
      expect(GandiV5).to receive(:post).with(url, body).and_return([response, 'Confirmation message'])
      expect(described_class).to receive(:fetch).with('template-uuid').and_return(double(GandiV5::Template))

      described_class.create name: 'n', description: 'd', dns_records: :default
    end

    it 'With empty payload' do
      body = {
        'name' => 'n',
        'description' => 'd',
        'payload' => {}
      }.to_json
      response = double(
        RestClient::Response,
        headers: { location: 'https://api.gandi.net/v5/template/templates/template-uuid' }
      )
      expect(GandiV5).to receive(:post).with(url, body).and_return([response, 'Confirmation message'])
      expect(described_class).to receive(:fetch).with('template-uuid').and_return(double(GandiV5::Template))

      described_class.create name: 'n', description: 'd'
    end
  end
end
