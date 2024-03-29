# frozen_string_literal: true

describe GandiV5::SimpleHosting::Instance::VirtualHost do
  let :body_list do
    if RUBY_VERSION >= '3.1.0'
      YAML.load_file(
        File.expand_path(
          File.join('spec', 'fixtures', 'bodies', 'GandiV5_SimpleHosting_Instance_VirtualHost', 'list.yml')
        ),
        permitted_classes: [Time]
      )
    else
      YAML.load_file(
        File.expand_path(
          File.join('spec', 'fixtures', 'bodies', 'GandiV5_SimpleHosting_Instance_VirtualHost', 'list.yml')
        )
      )
    end
  end
  let :body_fetch do
    if RUBY_VERSION >= '3.1.0'
      YAML.load_file(
        File.expand_path(
          File.join('spec', 'fixtures', 'bodies', 'GandiV5_SimpleHosting_Instance_VirtualHost', 'fetch.yml')
        ),
        permitted_classes: [Time]
      )
    else
      YAML.load_file(
        File.expand_path(
          File.join('spec', 'fixtures', 'bodies', 'GandiV5_SimpleHosting_Instance_VirtualHost', 'fetch.yml')
        )
      )
    end
  end

  subject do
    described_class.new instance_uuid: 'instance-uuid', fqdn: 'vh.example.com'
  end

  it '#refresh' do
    url = 'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/vhosts/vh.example.com'
    expect(GandiV5).to receive(:get).with(url)
                                    .and_return([nil, body_fetch])
    subject.refresh
    expect(subject.linked_dns_zone.cname).to_not be nil
  end

  describe '#update' do
    describe 'application' do
      it 'Given a GandiV5::SimpleHosting::Instance::Application' do
        application = GandiV5::SimpleHosting::Instance::Application.new(
          name: 'app-name',
          parameters: {}
        )

        expect(GandiV5).to receive(:put).with(
          'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/vhosts/vh.example.com',
          '{"application":{"name":"app-name","parameters":{}}}'
        ).and_return([nil, body_fetch])
        subject.update(application: application)

        expect(subject.application.name).to eq 'app-name'
        expect(subject.application.parameters).to eq({})
      end

      it 'Given a Hash' do
        expect(GandiV5).to receive(:put).with(
          'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/vhosts/vh.example.com',
          '{"application":{"name":"app-name"}}'
        ).and_return([nil, body_fetch])
        subject.update(application: { name: 'app-name' })
      end
    end

    describe 'https_strategy' do
      it ':redirect_http_to_https' do
        expect(GandiV5).to receive(:put).with(
          'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/vhosts/vh.example.com',
          '{"https_strategy":"redirect_HTTP_to_HTTPS"}'
        ).and_return([nil, body_fetch])
        subject.update(https_strategy: :redirect_http_to_https)
        expect(subject.https_strategy).to be :redirect_http_to_https
      end

      it ':allow_http_and_https' do
        expect(GandiV5).to receive(:put).with(
          'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/vhosts/vh.example.com',
          '{"https_strategy":"allow_HTTP_and_HTTPS"}'
        ).and_return([nil, body_fetch])
        subject.update(https_strategy: :allow_http_and_https)
        expect(subject.https_strategy).to be :redirect_http_to_https
      end

      it ':http_only' do
        expect(GandiV5).to receive(:put).with(
          'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/vhosts/vh.example.com',
          '{"https_strategy":"HTTP_only"}'
        ).and_return([nil, body_fetch])
        subject.update(https_strategy: :http_only)
        expect(subject.https_strategy).to be :redirect_http_to_https
      end

      it 'invalid' do
        expect(GandiV5).not_to receive(:put)
        expect { subject.update(https_strategy: :invalid) }.to \
          raise_error ArgumentError, 'https_strategy :invalid is invalid'
      end
    end

    it 'linked_dns_zone' do
      expect(GandiV5).to receive(:put).with(
        'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/vhosts/vh.example.com',
        '{"linked_dns_zone":{"allow_alteration":false,"allow_alteration_override":true}}'
      ).and_return([nil, body_fetch])
      subject.update(linked_dns_zone_allow_alteration: false, linked_dns_zone_allow_alteration_override: true)
      expect(subject.linked_dns_zone.allow_alteration).to be true
    end
  end

  it '#delete' do
    expect(GandiV5).to receive(:delete).with(
      'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/vhosts/vh.example.com'
    ).and_return([nil, { 'message' => 'Confirmation message.' }])
    expect(subject.delete).to eq 'Confirmation message.'
  end

  describe 'Helper methods' do
    describe 'Status' do
      context 'being_created' do
        subject { described_class.new status: :being_created }
        its('being_created?') { should be true }
        its('running?') { should be false }
        its('being_deleted?') { should be false }
        its('locked?') { should be false }
        its('waiting_ownership?') { should be false }
        its('ownership_validated?') { should be false }
        its('validation_failed?') { should be false }
      end
      context 'running' do
        subject { described_class.new status: :running }
        its('being_created?') { should be false }
        its('running?') { should be true }
        its('being_deleted?') { should be false }
        its('locked?') { should be false }
        its('waiting_ownership?') { should be false }
        its('ownership_validated?') { should be false }
        its('validation_failed?') { should be false }
      end
      context 'being_deleted' do
        subject { described_class.new status: :being_deleted }
        its('being_created?') { should be false }
        its('running?') { should be false }
        its('being_deleted?') { should be true }
        its('locked?') { should be false }
        its('waiting_ownership?') { should be false }
        its('ownership_validated?') { should be false }
        its('validation_failed?') { should be false }
      end
      context 'locked' do
        subject { described_class.new status: :locked }
        its('being_created?') { should be false }
        its('running?') { should be false }
        its('being_deleted?') { should be false }
        its('locked?') { should be true }
        its('waiting_ownership?') { should be false }
        its('ownership_validated?') { should be false }
        its('validation_failed?') { should be false }
      end
      context 'waiting_ownership' do
        subject { described_class.new status: :waiting_ownership }
        its('being_created?') { should be false }
        its('running?') { should be false }
        its('being_deleted?') { should be false }
        its('locked?') { should be false }
        its('waiting_ownership?') { should be true }
        its('ownership_validated?') { should be false }
        its('validation_failed?') { should be false }
      end
      context 'ownership_validated' do
        subject { described_class.new status: :ownership_validated }
        its('being_created?') { should be false }
        its('running?') { should be false }
        its('being_deleted?') { should be false }
        its('locked?') { should be false }
        its('waiting_ownership?') { should be false }
        its('ownership_validated?') { should be true }
        its('validation_failed?') { should be false }
      end
      context 'validation_failed' do
        subject { described_class.new status: :validation_failed }
        its('being_created?') { should be false }
        its('running?') { should be false }
        its('being_deleted?') { should be false }
        its('locked?') { should be false }
        its('waiting_ownership?') { should be false }
        its('ownership_validated?') { should be false }
        its('validation_failed?') { should be true }
      end
    end

    describe 'HTTP(S)' do
      context 'HTTP_only' do
        subject { described_class.new https_strategy: :http_only }
        its('http_only?') { should be true }
        its('http_and_https?') { should be false }
        its('redirect_http_to_https?') { should be false }
        its('http?') { should be true }
        its('https?') { should be false }
      end
      context 'HTTP_and_HTTPS' do
        subject { described_class.new https_strategy: :http_and_https }
        its('http_only?') { should be false }
        its('http_and_https?') { should be true }
        its('redirect_http_to_https?') { should be false }
        its('http?') { should be true }
        its('https?') { should be true }
      end
      context 'redirect_HTTP_to_HTTPS' do
        subject { described_class.new https_strategy: :redirect_http_to_https }
        its('http_only?') { should be false }
        its('http_and_https?') { should be false }
        its('redirect_http_to_https?') { should be true }
        its('http?') { should be false }
        its('https?') { should be false }
      end
    end
  end

  describe '.create' do
    it 'With just fqdn' do
      expect(GandiV5).to receive(:post).with(
        'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/vhosts',
        '{"fqdn":"vh.example.com"}'
      ).and_return([nil, nil])

      url = 'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/vhosts/vh.example.com'
      expect(GandiV5).to receive(:get).with(url).and_return([nil, body_fetch])

      subject = described_class.create('instance-uuid', 'vh.example.com')
      expect(subject.created_at).to eq Time.new(2020, 1, 2, 12, 34, 56, 0)
    end

    it 'Also with application' do
      expect(GandiV5).to receive(:post).with(
        'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/vhosts',
        '{"fqdn":"vh.example.com","application":{"name":"app-name"}}'
      ).and_return([nil, nil])

      url = 'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/vhosts/vh.example.com'
      expect(GandiV5).to receive(:get).with(url).and_return([nil, body_fetch])

      subject = described_class.create('instance-uuid', 'vh.example.com', application: { name: 'app-name' })
      expect(subject.created_at).to eq Time.new(2020, 1, 2, 12, 34, 56, 0)
    end

    it 'Also with linked_dns_zone' do
      expect(GandiV5).to receive(:post).with(
        'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/vhosts',
        '{"fqdn":"vh.example.com","linked_dns_zone":{"allow_alteration":false,"allow_alteration_override":true}}'
      ).and_return([nil, nil])

      url = 'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/vhosts/vh.example.com'
      expect(GandiV5).to receive(:get).with(url).and_return([nil, body_fetch])

      subject = described_class.create(
        'instance-uuid',
        'vh.example.com',
        linked_dns_zone_allow_alteration: false,
        linked_dns_zone_allow_alteration_override: true
      )
      expect(subject.created_at).to eq Time.new(2020, 1, 2, 12, 34, 56, 0)
    end
  end

  describe '.list' do
    subject { described_class.list('instance-uuid') }
    let(:url) { 'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/vhosts' }

    describe 'With default parameters' do
      before :each do
        expect(GandiV5).to receive(:paginated_get).with(url, (1..), 100, params: {})
                                                  .and_yield(body_list)
      end

      its('count') { should eq 1 }
      its('first.created_at') { should eq Time.new(2020, 1, 2, 12, 34, 56, 0) }
      its('first.fqdn') { should eq 'vh.example.com' }
      its('first.is_a_test_virtual_host') { should be false }
      its('first.linked_dns_zone.allow_alteration') { should be true }
      its('first.linked_dns_zone.status') { should eq :unknown }
      its('first.linked_dns_zone.last_checked_at') { should eq Time.new(2020, 2, 3, 23, 45, 56, 0) }
      its('first.status') { should eq :running }
      its('first.application.name') { should eq 'app-name' }
      its('first.application.status') { should eq :being_created }
      its('first.application.parameters') { should eq({}) }
      its('first.certificates') { should eq({ 'cert-id' => true }) }
      its('first.https_strategy') { should eq :redirect_http_to_https }
    end

    describe 'Passes optional query params' do
      %i[fqdn status sort_by].each do |param|
        it param do
          expect(GandiV5).to receive(:paginated_get).with(url, (1..), 100, params: { param => 'value' })
                                                    .and_return([nil, []])
          described_class.list('instance-uuid', param => 'value')
        end
      end
    end
  end

  describe '.fetch' do
    subject { described_class.fetch 'instance-uuid', 'vh.example.com' }

    before :each do
      url = 'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/vhosts/vh.example.com'
      expect(GandiV5).to receive(:get).with(url)
                                      .and_return([nil, body_fetch])
    end

    its('created_at') { should eq Time.new(2020, 1, 2, 12, 34, 56, 0) }
    its('fqdn') { should eq 'vh.example.com' }
    its('is_a_test_virtual_host') { should be false }
    its('linked_dns_zone.allow_alteration') { should be true }
    its('linked_dns_zone.cname') { should eq 'cn' }
    its('linked_dns_zone.domain') { should eq 'example.com' }
    its('linked_dns_zone.ipv4') { should eq '1.2.3.4' }
    its('linked_dns_zone.ipv6') { should eq '1:2::3:4' }
    its('linked_dns_zone.is_alterable') { should be true }
    its('linked_dns_zone.is_root') { should be true }
    its('linked_dns_zone.key') { should eq 'www' }
    its('linked_dns_zone.txt') { should eq 'abcd1234' }
    its('linked_dns_zone.status') { should eq :unknown }
    its('linked_dns_zone.last_checked_at') { should eq Time.new(2020, 2, 3, 23, 45, 56, 0) }
    its('status') { should eq :running }
    its('application.name') { should eq 'app-name' }
    its('application.status') { should eq :being_created }
    its('application.parameters') { should eq({}) }
    its('certificates') { should eq({ 'cert-id' => true }) }
    its('https_strategy') { should eq :redirect_http_to_https }
  end
end
