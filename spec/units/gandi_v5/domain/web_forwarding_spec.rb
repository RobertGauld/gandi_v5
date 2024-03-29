# frozen_string_literal: true

describe GandiV5::Domain::WebForwarding do
  subject { described_class.new fqdn: 'host.example.com' }

  describe '#update' do
    let(:url) { 'https://api.gandi.net/v5/domain/domains/example.com/webredirs/host.example.com' }
    let(:updated_forwarding) { double GandiV5::Domain::WebForwarding }

    before :each do
      expect(subject).to receive(:refresh).and_return(updated_forwarding)
      subject.instance_exec { @domain = 'example.com' }
    end

    it 'nothing' do
      expect(GandiV5).to receive(:patch).with(url, '{}')
      expect(subject.update).to be updated_forwarding
    end

    it 'target' do
      expect(GandiV5).to receive(:patch).with(url, '{"url":"new"}')
      expect(subject.update(target: 'new')).to be updated_forwarding
    end

    it 'override' do
      expect(GandiV5).to receive(:patch).with(url, '{"override":false}')
      expect(subject.update(override: false)).to be updated_forwarding
    end

    it 'protocol' do
      expect(GandiV5).to receive(:patch).with(url, '{"protocol":"httpsonly"}')
      expect(subject.update(protocol: :httpsonly)).to be updated_forwarding
    end

    it 'type' do
      expect(GandiV5).to receive(:patch).with(url, '{"type":"http302"}')
      expect(subject.update(type: :http302)).to be updated_forwarding
    end
  end

  it '#delete' do
    url = 'https://api.gandi.net/v5/domain/domains/example.com/webredirs/host.example.com'
    expect(GandiV5).to receive(:delete).with(url).and_return([nil, { 'message' => 'Confirmation message.' }])
    subject.instance_exec { @domain = 'example.com' }
    expect(subject.delete).to eq 'Confirmation message.'
  end

  describe 'helper methods' do
    context 'an HTTP 301 redirect' do
      subject { described_class.new type: :http301 }
      it('#permanent?') { expect(subject.permanent?).to be true }
      it('#http301?') { expect(subject.http301?).to be true }
      it('#temporary?') { expect(subject.temporary?).to be false }
      it('#http302?') { expect(subject.http302?).to be false }
      it('#found?') { expect(subject.found?).to be false }
    end

    context 'an HTTP 302 redirect' do
      subject { described_class.new type: :http302 }
      it('#permanent?') { expect(subject.permanent?).to be false }
      it('#http301?') { expect(subject.http301?).to be false }
      it('#temporary?') { expect(subject.temporary?).to be true }
      it('#http302?') { expect(subject.http302?).to be true }
      it('#found?') { expect(subject.found?).to be true }
    end

    context 'an http endpoint' do
      subject { described_class.new protocol: :http }
      it('#http?') { expect(subject.http?).to be true }
      it('#https?') { expect(subject.https?).to be false }
      it('#https_only?') { expect(subject.https_only?).to be false }
    end

    context 'an https endpoint' do
      subject { described_class.new protocol: :https }
      it('#http?') { expect(subject.http?).to be true }
      it('#https?') { expect(subject.https?).to be true }
      it('#https_only?') { expect(subject.https_only?).to be false }
    end

    context 'an https_only endpoint' do
      subject { described_class.new protocol: :https_only }
      it('#http?') { expect(subject.http?).to be false }
      it('#https?') { expect(subject.https?).to be true }
      it('#https_only?') { expect(subject.https_only?).to be true }
    end
  end

  describe '.fetch' do
    subject { described_class.fetch 'example.com', 'host' }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain_WebForwarding', 'fetch.yml'))
      url = 'https://api.gandi.net/v5/domain/domains/example.com/webredirs/host.example.com'
      if RUBY_VERSION >= '3.1.0'
        expect(GandiV5).to receive(:get).with(url).and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
      else
        expect(GandiV5).to receive(:get).with(url).and_return([nil, YAML.load_file(body_fixture)])
      end
    end

    its('created_at') { should eq Time.new(2020, 11, 29, 14, 57, 14) }
    its('updated_at') { should eq Time.new(2020, 11, 29, 14, 57, 15) }
    its('type') { should eq :http301 }
    its('fqdn') { should eq 'here.example.com' }
    its('protocol') { should eq :https }
    its('target') { should eq 'https://example.com/here' }
    its('cert_status') { should eq '?' }
    its('cert_uuid') { should eq 'cert-uuid' }
  end

  describe '.list' do
    subject { described_class.list 'example.com' }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain_WebForwarding', 'list.yml'))
      url = 'https://api.gandi.net/v5/domain/domains/example.com/webredirs'
      if RUBY_VERSION >= '3.1.0'
        expect(GandiV5).to receive(:paginated_get).with(url, (1..), 100)
                                                  .and_yield(YAML.load_file(body_fixture, permitted_classes: [Time]))
      else
        expect(GandiV5).to receive(:paginated_get).with(url, (1..), 100)
                                                  .and_yield(YAML.load_file(body_fixture))
      end
    end

    its('count') { should eq 1 }
    its('first.created_at') { should eq Time.new(2020, 11, 29, 14, 57, 14) }
    its('first.updated_at') { should eq Time.new(2020, 11, 29, 14, 57, 15) }
    its('first.type') { should eq :http301 }
    its('first.fqdn') { should eq 'here.example.com' }
    its('first.protocol') { should eq :https }
    its('first.target') { should eq 'https://example.com/here' }
    its('first.cert_status') { should eq '?' }
    its('first.cert_uuid') { should eq 'cert-uuid' }
  end

  it '.create' do
    url = 'https://api.gandi.net/v5/domain/domains/example.com/webredirs'
    body = '{"host":"host","protocol":"httpsonly","type":"http302","url":"example.com","override":true}'
    response = double(
      RestClient::Response,
      headers: { location: ' https://api.gandi.net/v5/domain/domains/example.com/webredirs/host.example.com' }
    )
    created_forwarding = double GandiV5::Domain::WebForwarding
    expect(GandiV5).to receive(:post).with(url, body).and_return([response, 'Confirmation message'])
    expect(described_class).to receive(:fetch).with('example.com', 'host').and_return(created_forwarding)

    create = {
      domain: 'example.com',
      host: 'host',
      target: 'example.com',
      protocol: :https_only,
      type: :http302,
      override: true
    }
    expect(described_class.create(**create)).to be created_forwarding
  end
end
