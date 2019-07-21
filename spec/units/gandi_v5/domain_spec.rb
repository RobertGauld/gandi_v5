# frozen_string_literal: true

describe GandiV5::Domain do
  subject { described_class.new fqdn: 'example.com' }

  describe '.list' do
    let(:body_fixture) { File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain', 'list.yaml')) }

    describe 'With default values' do
      subject { described_class.list }

      before :each do
        headers = { params: { page: 1, per_page: 100 } }
        expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/domains', headers)
                                        .and_return([nil, YAML.load_file(body_fixture)])
      end

      its('count') { should eq 1 }
      its('first.uuid') { should eq 'domain-uuid' }
      its('first.fqdn') { should eq 'example.com' }
      its('first.fqdn_unicode') { should eq 'example.com' }
      its('first.name_servers') { should be_nil }
      its('first.services') { should be_nil }
      its('first.status') { should eq [] }
      its('first.tld') { should eq 'com' }
      its('first.can_tld_lock') { should be_nil }
      its('first.auth_info') { should be_nil }
      its('first.sharing_uuid') { should be_nil }
      its('first.tags') { should match_array ['Tag'] }
      its('first.trustee_roles') { should be_nil }
      its('first.owner') { should eq 'Example Owner' }
      its('first.organisation_owner') { should eq 'Example Organisation' }
      its('first.domain_owner') { should eq 'Example Owner' }
      its('first.name_server') { should be :livedns }
      its('first.sharing_space') { should be_nil }
      its('first.dates.created_at') { should eq Time.new(2011, 2, 21, 10, 39, 0) }
      its('first.dates.registry_created_at') { should eq Time.new(2003, 3, 12, 12, 2, 11) }
      its('first.dates.registry_ends_at') { should eq Time.new(2020, 3, 12, 12, 2, 11) }
      its('first.dates.updated_at') { should eq Time.new(2019, 2, 6, 9, 49, 37) }
      its('first.auto_renew.dates') { should be_nil }
      its('first.auto_renew.duration') { should be_nil }
      its('first.auto_renew.enabled') { should eq false }
      its('first.auto_renew.org_id') { should be_nil }
      its('first.contacts?') { should be false }
    end

    it 'Keeps fetching until no more to get' do
      headers1 = { params: { page: 1, per_page: 1 } }
      headers2 = { params: { page: 2, per_page: 1 } }
      # https://github.com/rubocop-hq/rubocop/issues/7088
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/domains', headers1)
                                      .ordered
                                      .and_return([nil, YAML.load_file(body_fixture)])
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/domains', headers2)
                                      .ordered
                                      .and_return([nil, []])

      expect(described_class.list(per_page: 1).count).to eq 1
    end

    it 'Given a range as page number' do
      headers1 = { params: { page: 1, per_page: 1 } }
      headers2 = { params: { page: 2, per_page: 1 } }
      # https://github.com/rubocop-hq/rubocop/issues/7088
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/domains', headers1)
                                      .ordered
                                      .and_return([nil, YAML.load_file(body_fixture)])
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/domains', headers2)
                                      .ordered
                                      .and_return([nil, []])

      expect(described_class.list(page: (1..2), per_page: 1).count).to eq 1
    end

    describe 'Passes optional query params' do
      %i[fqdn page per_page sort_by tld].each do |param|
        it param.to_s do
          param = { param => 5 }
          headers = { params: { page: 1, per_page: 100 }.merge(param) }
          expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/domains', headers)
                                          .and_return([nil, []])
          expect(described_class.list(**param)).to eq []
        end
      end
    end
  end

  describe '.fetch' do
    subject { described_class.fetch 'example.com' }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain', 'get.yaml'))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/domains/example.com')
                                      .and_return([nil, YAML.load_file(body_fixture)])
    end

    its('uuid') { should eq 'domain-uuid' }
    its('fqdn') { should eq 'example.com' }
    its('fqdn_unicode') { should eq 'example.com' }
    its('status') { should eq [] }
    its('tld') { should eq 'com' }
    its('auth_info') { should be_nil }
    its('sharing_uuid') { should be_nil }
    its('tags') { should match_array ['Tag'] }
    its('trustee_roles') { should be_nil }
    its('owner') { should be_nil }
    its('organisation_owner') { should be_nil }
    its('domain_owner') { should be_nil }
    its('name_servers') { should match_array %w[192.168.0.1 192.168.0.2] }
    its('services') { should match_array %i[gandilivedns dnssec] }
    its('sharing_space') { should be_nil }
    its('dates.created_at') { should eq Time.new(2011, 2, 21, 10, 39, 0) }
    its('dates.registry_created_at') { should eq Time.new(2003, 3, 12, 12, 2, 11) }
    its('dates.registry_ends_at') { should eq Time.new(2020, 3, 12, 12, 2, 11) }
    its('dates.updated_at') { should eq Time.new(2019, 2, 6, 9, 49, 37) }
    its('auto_renew.dates') { should match_array [Time.new(2021, 1, 13, 9, 4, 18), Time.new(2021, 1, 29, 10, 4, 18)] }
    its('auto_renew.duration') { should eq 1 }
    its('auto_renew.enabled') { should eq true }
    its('auto_renew.org_id') { should eq 'org-uuid' }
    its('contacts?') { should be true }
    its('contacts.owner.country') { should eq 'GB' }
    its('contacts.owner.email') { should eq 'owner@example.com' }
    its('contacts.owner.family') { should eq 'Fam' }
    its('contacts.owner.given') { should eq 'Giv' }
    its('contacts.owner.address') { should eq 'Somestreet' }
    its('contacts.owner.type') { should be :company }
  end

  describe '.create' do
    let(:url) { 'https://api.gandi.net/v5/domain/domains' }

    describe 'Sets dry-run header' do
      let(:body) { '{"owner":{},"fqdn":"example.com"}' }

      it 'False by default' do
        returns = double described_class
        response = double RestClient::Response, headers: { location: 'https://api.gandi.net/v5/domains/example.com' }
        expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0).and_return([response, nil])
        expect(described_class).to receive(:fetch).with('example.com').and_return(returns)
        described_class.create 'example.com', owner: {}
      end

      it 'True' do
        expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 1).and_return([nil, nil])
        described_class.create 'example.com', owner: {}, dry_run: true
      end

      it 'False' do
        returns = double described_class
        response = double RestClient::Response, headers: { location: 'https://api.gandi.net/v5/domains/example.com' }
        expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0).and_return([response, nil])
        expect(described_class).to receive(:fetch).with('example.com').and_return(returns)
        described_class.create 'example.com', owner: {}, dry_run: false
      end

      it 'Dry run was successful' do
        returns = { 'status' => 'success' }
        expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 1)
                                         .and_return([nil, returns])
        expect(described_class.create('example.com', owner: {}, dry_run: true)).to be returns
      end

      it 'Dry run has errors' do
        returns = {
          'status' => 'error',
          'errors' => [{ 'description' => 'd', 'location' => 'l', 'name' => 'n' }]
        }
        expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 1)
                                         .and_return([nil, returns])
        expect(described_class.create('example.com', owner: {}, dry_run: true)).to be returns
      end
    end

    it 'Success' do
      returns = double described_class
      response = double RestClient::Response, headers: { location: 'https://api.gandi.net/v5/domains/example.com' }
      body = '{"owner":{},"fqdn":"example.com"}'
      expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0)
                                       .and_return([response, nil])
      expect(described_class).to receive(:fetch).with('example.com').and_return(returns)
      expect(described_class.create('example.com', owner: {})).to be returns
    end

    it 'Errors on missing owner' do
      expect { described_class.create 'example.com' }.to raise_error ArgumentError, 'missing keyword: owner'
    end

    it 'Given contact as hash' do
      returns = double described_class
      body = '{"owner":{"email":"owner@example.com"},"fqdn":"example.com"}'
      response = double RestClient::Response, headers: { location: 'https://api.gandi.net/v5/domains/example.com' }
      expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0).and_return([response, nil])
      expect(described_class).to receive(:fetch).with('example.com').and_return(returns)
      described_class.create 'example.com', owner: { email: 'owner@example.com' }
    end

    it 'Given contact as GandiV5::Domain::Contact' do
      returns = double described_class
      body = '{"owner":{"email":"owner@example.com"},"fqdn":"example.com"}'
      response = double RestClient::Response, headers: { location: 'https://api.gandi.net/v5/domains/example.com' }
      expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0).and_return([response, nil])
      expect(described_class).to receive(:fetch).with('example.com').and_return(returns)
      owner = double GandiV5::Domain::Contact, to_gandi: { 'email' => 'owner@example.com' }
      described_class.create 'example.com', owner: owner
    end
  end

  describe '#to_s' do
    it 'Has identical fqdn and fqdn_unicode' do
      domain = described_class.new fqdn: 'example.com', fqdn_unicode: 'example.com'
      expect(domain.to_s).to eq 'example.com'
    end

    it 'Has differing fqdn and fqdn_unicode' do
      domain = described_class.new fqdn: 'example.com', fqdn_unicode: 'unicode.example.com'
      expect(domain.to_s).to eq 'unicode.example.com (example.com)'
    end
  end

  describe '#refresh' do
    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain', 'get.yaml'))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/domains/example.com')
                                      .and_return([nil, YAML.load_file(body_fixture)])
      subject.refresh
    end

    its('uuid') { should eq 'domain-uuid' }
    its('fqdn') { should eq 'example.com' }
    its('fqdn_unicode') { should eq 'example.com' }
    its('status') { should eq [] }
    its('tld') { should eq 'com' }
    its('auth_info') { should be_nil }
    its('sharing_uuid') { should be_nil }
    its('tags') { should match_array ['Tag'] }
    its('trustee_roles') { should be_nil }
    its('owner') { should be_nil }
    its('organisation_owner') { should be_nil }
    its('domain_owner') { should be_nil }
    its('name_servers') { should match_array %w[192.168.0.1 192.168.0.2] }
    its('services') { should match_array %i[gandilivedns dnssec] }
    its('sharing_space') { should be_nil }
    its('dates.created_at') { should eq Time.new(2011, 2, 21, 10, 39, 0) }
    its('dates.registry_created_at') { should eq Time.new(2003, 3, 12, 12, 2, 11) }
    its('dates.registry_ends_at') { should eq Time.new(2020, 3, 12, 12, 2, 11) }
    its('dates.updated_at') { should eq Time.new(2019, 2, 6, 9, 49, 37) }
    its('auto_renew.dates') { should match_array [Time.new(2021, 1, 13, 9, 4, 18), Time.new(2021, 1, 29, 10, 4, 18)] }
    its('auto_renew.duration') { should eq 1 }
    its('auto_renew.enabled') { should eq true }
    its('auto_renew.org_id') { should eq 'org-uuid' }
    its('contacts.owner.country') { should eq 'GB' }
    its('contacts.owner.email') { should eq 'owner@example.com' }
    its('contacts.owner.family') { should eq 'Fam' }
    its('contacts.owner.given') { should eq 'Giv' }
    its('contacts.owner.address') { should eq 'Somestreet' }
    its('contacts.owner.type') { should be :company }
  end

  describe 'Domain contacts' do
    describe '#contacts' do
      it 'Already fetched' do
        domain = described_class.new fqdn: 'example.com', contacts: {}
        expect(domain).to_not receive(:fetch_contacts)
        expect(domain.contacts).to eq({})
      end

      it 'Not already fetched' do
        contacts = {}
        expect(subject).to receive(:fetch_contacts).and_return(contacts)
        expect(subject.contacts).to be contacts
      end
    end

    describe '#fetch_contacts' do
      subject { described_class.new(fqdn: 'example.com').fetch_contacts }

      before(:each) do
        body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain', 'fetch_contacts.yaml'))
        expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/domains/example.com/contacts')
                                        .and_return([nil, YAML.load_file(body_fixture)])
      end

      its('owner.country') { should eq 'GB' }
      its('owner.email') { should eq 'owner@example.com' }
      its('owner.family') { should eq 'Fam' }
      its('owner.given') { should eq 'Giv' }
      its('owner.address') { should eq 'Somestreet' }
      its('owner.type') { should be :company }
    end

    describe '#update_contacts' do
      let(:fetched_contacts) { { admin: double(GandiV5::Domain::Contact) } }

      before(:each) do
        url = 'https://api.gandi.net/v5/domain/domains/example.com/contacts'
        body = '{"admin":{"email":"admin@example.com"}}'
        expect(GandiV5).to receive(:patch).with(url, body)
                                          .and_return('message' => 'Confirmation message.')

        expect(subject).to receive(:fetch_contacts).and_return(fetched_contacts)
      end

      it 'Given a Hash' do
        new_contacts = { admin: { email: 'admin@example.com' } }
        expect(subject.update_contacts(**new_contacts)).to be fetched_contacts
      end

      it 'Given a GandiV5::Domain::Contact' do
        new_contacts = { admin: double(GandiV5::Domain::Contact, to_gandi: { 'email' => 'admin@example.com' }) }
        expect(subject.update_contacts(**new_contacts)).to be fetched_contacts
      end
    end
  end

  describe 'Domain renewal' do
    describe '#renewal_information' do
      let(:renewal_info) { double GandiV5::Domain::RenewalInformation }

      it 'Already fetched' do
        subject.instance_exec(renewal_info) { |renewal_info| @renewal_information = renewal_info }
        expect(subject).to_not receive(:fetch_renewal_information)
        expect(subject.renewal_information).to be renewal_info
      end

      it 'Not already fetched' do
        expect(subject).to receive(:fetch_renewal_information).and_return(renewal_info)
        expect(subject.renewal_information).to be renewal_info
      end
    end

    describe '#fetch_renewal_information' do
      subject { described_class.new(fqdn: 'example.com').fetch_renewal_information }

      before(:each) do
        body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain', 'renewal_info.yaml'))
        expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/domains/example.com/renew')
                                        .and_return([nil, YAML.load_file(body_fixture)])
      end

      its('begins_at') { should eq Time.new(2012, 1, 1, 0, 0, 0) }
      its('prohibited') { should be false }
      its('minimum') { should eq 1 }
      its('maximum') { should eq 2 }
      its('durations') { should match_array [1, 2] }
      its('contracts.count') { should eq 1 }
      its('contracts.first.id') { should eq 'uuid' }
      its('contracts.first.name') { should eq 'Name' }
    end

    it '#renew_for' do
      expect(GandiV5).to receive(:post).with('https://api.gandi.net/v5/domain/domains/example.com/renew', '{"duration":2}')
                                       .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.renew_for(2)).to eq 'Confirmation message.'
    end

    describe '#renewal_price' do
      it 'Default values' do
        price = double GandiV5::Domain::Availability::Product::Price
        arguments = { processes: [:renew], currency: 'GBP', period: 1 }
        expect(GandiV5::Domain::Availability).to receive(:fetch).with('example.com', **arguments).and_return(
          double(
            GandiV5::Domain::Availability,
            products: [
              double(
                GandiV5::Domain::Availability::Product,
                prices: [price]
              )
            ]
          )
        )
        expect(subject.renewal_price).to be price
      end

      it 'Passed currency' do
        price = double GandiV5::Domain::Availability::Product::Price
        arguments = { processes: [:renew], currency: 'EUR', period: 1 }
        expect(GandiV5::Domain::Availability).to receive(:fetch).with('example.com', **arguments).and_return(
          double(
            GandiV5::Domain::Availability,
            products: [
              double(
                GandiV5::Domain::Availability::Product,
                prices: [price]
              )
            ]
          )
        )
        expect(subject.renewal_price(currency: 'EUR')).to be price
      end

      it 'Passed period' do
        price = double GandiV5::Domain::Availability::Product::Price
        arguments = { processes: [:renew], currency: 'GBP', period: 2 }
        expect(GandiV5::Domain::Availability).to receive(:fetch).with('example.com', **arguments).and_return(
          double(
            GandiV5::Domain::Availability,
            products: [
              double(
                GandiV5::Domain::Availability::Product,
                prices: [price]
              )
            ]
          )
        )
        expect(subject.renewal_price(period: 2)).to be price
      end
    end
  end

  describe 'Domain restoration' do
    describe '#restore_information' do
      let(:restore_info) { double GandiV5::Domain::RestoreInformation }

      it 'Already fetched' do
        subject.instance_exec(restore_info) { |restore_info| @restore_information = restore_info }
        expect(subject).to_not receive(:fetch_restore_information)
        expect(subject.restore_information).to be restore_info
      end

      it 'Not already fetched' do
        expect(subject).to receive(:fetch_restore_information).and_return(restore_info)
        expect(subject.restore_information).to be restore_info
      end
    end

    describe '#fetch_restore_information' do
      subject { described_class.new(fqdn: 'example.com').fetch_restore_information }

      describe 'Information is available' do
        before(:each) do
          body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain', 'restore_info.yaml'))
          expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/domains/example.com/restore')
                                          .and_return([nil, YAML.load_file(body_fixture)])
        end

        its('restorable') { should be true }
        its('contracts.count') { should eq 1 }
        its('contracts.first.id') { should eq 'uuid' }
        its('contracts.first.name') { should eq 'Name' }
      end

      describe 'Information is unavailable' do
        before(:each) do
          expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/domains/example.com/restore')
                                          .and_raise(RestClient::NotFound)
        end

        its('restorable') { should be false }
        its('contracts') { should be_nil }
      end
    end

    it '#restore' do
      expect(GandiV5).to receive(:post).with('https://api.gandi.net/v5/domain/domains/example.com/restore', '{}')
                                       .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.restore).to eq 'Confirmation message.'
    end
  end
end
