# frozen_string_literal: true

describe GandiV5::Domain do
  subject { described_class.new fqdn: 'example.com' }

  describe '.list' do
    let(:body_fixture) { File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain', 'list.yml')) }
    let(:url) { 'https://api.gandi.net/v5/domain/domains' }

    describe 'With default values' do
      subject { described_class.list }

      before :each do
        expect(GandiV5).to receive(:paginated_get).with(url, (1..), 100, params: {})
                                                  .and_yield(YAML.load_file(body_fixture))
      end

      its('count') { should eq 1 }
      its('first.uuid') { should eq 'domain-uuid' }
      its('first.fqdn') { should eq 'example.com' }
      its('first.fqdn_unicode') { should eq 'example.com' }
      its('first.name_servers') { should eq [] }
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

    describe 'Passes optional query params' do
      %i[fqdn sort_by tld resellee_id].each do |param|
        it param.to_s do
          expect(GandiV5).to receive(:paginated_get).with(url, (1..), 100, params: { param => 5 })
          expect(described_class.list(param => 5)).to eq []
        end
      end
    end
  end

  describe '.fetch' do
    subject { described_class.fetch 'example.com' }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain', 'fetch.yml'))
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
    its('sharing_space.uuid') { should eq 'SHARING-UUID' }
    its('sharing_space.name') { should eq 'User' }
    its('sharing_space.type') { should eq 'user' }
    its('sharing_space.reseller') { should be true }
    its('sharing_space.reseller_details.uuid') { should eq 'RESELLER-UUID' }
    its('sharing_space.reseller_details.name') { should eq 'Reseller' }
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
    let(:returns) { double described_class }
    let(:response) { double RestClient::Response, headers: { location: 'https://api.gandi.net/v5/domains/example.com' } }

    describe 'Sets dry-run header' do
      let(:body) { '{"owner":{},"fqdn":"example.com"}' }

      it 'False by default' do
        expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0).and_return([response, nil])
        expect(described_class).to receive(:fetch).with('example.com').and_return(returns)
        described_class.create 'example.com', owner: {}
      end

      it 'True' do
        expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 1).and_return([nil, nil])
        described_class.create 'example.com', owner: {}, dry_run: true
      end

      it 'False' do
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

    describe 'Sets sharing_id' do
      it 'Absent by default' do
        expect(GandiV5).to receive(:post).with(url, any_args).and_return([response, nil])
        expect(described_class).to receive(:fetch).with('example.com').and_return(returns)
        described_class.create('example.com', owner: {})
      end

      it 'Paying as another organization' do
        expect(GandiV5).to receive(:post).with("#{url}?sharing_id=organization_id", any_args).and_return([response, nil])
        expect(described_class).to receive(:fetch).with('example.com').and_return(returns)
        described_class.create('example.com', sharing_id: 'organization_id', owner: {})
      end

      it 'Buy as a reseller' do
        expect(GandiV5).to receive(:post).with("#{url}?sharing_id=reseller_id", any_args).and_return([response, nil])
        expect(described_class).to receive(:fetch).with('example.com').and_return(returns)
        described_class.create('example.com', sharing_id: 'reseller_id', owner: {})
      end
    end

    it 'Success' do
      body = '{"owner":{},"fqdn":"example.com"}'
      expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0).and_return([response, nil])
      expect(described_class).to receive(:fetch).with('example.com').and_return(returns)
      expect(described_class.create('example.com', owner: {})).to be returns
    end

    it 'Errors on missing owner' do
      expect { described_class.create 'example.com' }.to raise_error ArgumentError, 'missing keyword: owner'
    end

    it 'Given contact as hash' do
      body = '{"owner":{"email":"owner@example.com"},"fqdn":"example.com"}'
      expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0).and_return([response, nil])
      expect(described_class).to receive(:fetch).with('example.com').and_return(returns)
      described_class.create 'example.com', owner: { email: 'owner@example.com' }
    end

    it 'Given contact as GandiV5::Domain::Contact' do
      body = '{"owner":{"email":"owner@example.com"},"fqdn":"example.com"}'
      expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0).and_return([response, nil])
      expect(described_class).to receive(:fetch).with('example.com').and_return(returns)
      owner = double GandiV5::Domain::Contact, to_gandi: { 'email' => 'owner@example.com' }
      described_class.create 'example.com', owner: owner
    end
  end

  it '.mailboxes' do
    returns = double Array
    expect(GandiV5::Email::Mailbox).to receive(:list).with(param: :value, fqdn: 'example.com').and_return(returns)
    expect(subject.mailboxes(param: :value)).to be returns
  end

  it '.mailbox_slots' do
    returns = double Array
    expect(GandiV5::Email::Slot).to receive(:list).with(param: :value, fqdn: 'example.com').and_return(returns)
    expect(subject.mailbox_slots(param: :value)).to be returns
  end

  it '.email_forwards' do
    returns = double Array
    expect(GandiV5::Email::Forward).to receive(:list).with(param: :value, fqdn: 'example.com').and_return(returns)
    expect(subject.email_forwards(param: :value)).to be returns
  end

  it '.webredirections' do
    returns = double Array
    expect(GandiV5::Domain::WebRedirection).to receive(:list).with('example.com', param: :value).and_return(returns)
    expect(subject.web_redirections(param: :value)).to be returns
  end

  it '.webredirection' do
    returns = double Array
    expect(GandiV5::Domain::WebRedirection).to receive(:fetch).with('example.com', 'host').and_return(returns)
    expect(subject.web_redirection('host')).to be returns
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
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain', 'fetch.yml'))
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
    its('sharing_space') { should_not be_nil }
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
        body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain', 'fetch_contacts.yml'))
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
        body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain', 'fetch_renewal_info.yml'))
        expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/domains/example.com/renew')
                                        .and_return([nil, YAML.load_file(body_fixture)])
      end

      its('begins_at') { should eq Time.new(2012, 1, 1, 0, 0, 0) }
      its('prohibited') { should be false }
      its('minimum') { should eq 1 }
      its('maximum') { should eq 2 }
      its('durations') { should match_array [1, 2] }
    end

    describe '#renew_for' do
      it 'Defaults to 1 year and current user' do
        expect(GandiV5).to receive(:post).with(
          'https://api.gandi.net/v5/domain/domains/example.com/renew',
          '{"duration":1}',
          'Dry-Run': 0
        )
                                         .and_return([nil, { 'message' => 'Confirmation message.' }])
        expect(subject.renew_for).to eq 'Confirmation message.'
      end

      it 'With provided duration' do
        expect(GandiV5).to receive(:post).with(
          'https://api.gandi.net/v5/domain/domains/example.com/renew',
          '{"duration":2}',
          'Dry-Run': 0
        )
                                         .and_return([nil, { 'message' => 'Confirmation message.' }])
        expect(subject.renew_for(2)).to eq 'Confirmation message.'
      end

      it 'With provided sharing_id' do
        expect(GandiV5).to receive(:post).with(
          'https://api.gandi.net/v5/domain/domains/example.com/renew?sharing_id=def',
          '{"duration":1}',
          'Dry-Run': 0
        )
                                         .and_return([nil, { 'message' => 'Confirmation message.' }])
        expect(subject.renew_for(sharing_id: 'def')).to eq 'Confirmation message.'
      end

      it 'Does a dry run' do
        expect(GandiV5).to receive(:post).with(
          'https://api.gandi.net/v5/domain/domains/example.com/renew',
          '{"duration":1}',
          'Dry-Run': 1
        )
                                         .and_return([nil, { 'status' => 'success' }])
        expect(subject.renew_for(dry_run: true)).to eq('status' => 'success')
      end
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
          body_fixture = File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain', 'fetch_restore_info.yml')
          body_fixture = File.expand_path(body_fixture)
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

  describe '#transfer_lock' do
    it 'Passing nothing' do
      expect(GandiV5).to receive(:patch).with(
        'https://api.gandi.net/v5/domain/domains/example.com/status',
        '{"clientTransferProhibited":true}'
      ).and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.transfer_lock).to eq 'Confirmation message.'
      expect(subject.status).to eq 'clientTransferProhibited'
    end

    it 'Passing true' do
      expect(GandiV5).to receive(:patch).with(
        'https://api.gandi.net/v5/domain/domains/example.com/status',
        '{"clientTransferProhibited":true}'
      ).and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.transfer_lock(true)).to eq 'Confirmation message.'
      expect(subject.status).to eq 'clientTransferProhibited'
    end

    it 'Passing false' do
      expect(GandiV5).to receive(:patch).with(
        'https://api.gandi.net/v5/domain/domains/example.com/status',
        '{"clientTransferProhibited":false}'
      ).and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.transfer_lock(false)).to eq 'Confirmation message.'
      expect(subject.status).to be nil
    end
  end

  it '#transfer_unlock' do
    expect(GandiV5).to receive(:patch).with(
      'https://api.gandi.net/v5/domain/domains/example.com/status',
      '{"clientTransferProhibited":false}'
    ).and_return([nil, { 'message' => 'Confirmation message.' }])
    expect(subject.transfer_unlock).to eq 'Confirmation message.'
    expect(subject.status).to be nil
  end

  describe '#glue_records' do
    let(:glue_records) { double Hash }

    it 'Already fetched' do
      subject.instance_exec(glue_records) { |glue_records| @glue_records = glue_records }
      expect(subject).to_not receive(:fetch_glue_records)
      expect(subject.glue_records).to be glue_records
    end

    it 'Not already fetched' do
      expect(subject).to receive(:fetch_glue_records).and_return(glue_records)
      expect(subject.glue_records).to be glue_records
    end
  end

  it '#fetch_glue_records' do
    body_fixture = File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain', 'fetch_glue_records.yml')
    body_fixture = File.expand_path(body_fixture)
    expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/domains/example.com/hosts')
                                    .and_return([nil, YAML.load_file(body_fixture)])
    expect(subject.fetch_glue_records).to eq(
      'ns1' => ['1.2.3.4']
    )
  end

  describe '#add_glue_record' do
    before(:each) { described_class.instance_exec { @glue_records = {} } }

    it 'Make API request' do
      expect(GandiV5).to receive(:post).with(
        'https://api.gandi.net/v5/domain/domains/example.com/hosts',
        '{"name":"ns1","ips":["1.2.3.4"]}'
      )
                                       .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.add_glue_record('ns1', '1.2.3.4')).to eq 'Confirmation message.'
    end

    it 'Updates glue records' do
      expect(GandiV5).to receive(:post).and_return([nil, { 'message' => 'Confirmation message.' }])
      subject.add_glue_record 'ns1', '1.2.3.4'
      expect(subject.glue_records).to eq('ns1' => ['1.2.3.4'])
    end
  end

  describe '#glue_record' do
    before(:each) { subject.instance_exec { @glue_records = { 'ns1' => ['1.2.3.4'] } } }

    it 'Already fetched' do
      expect(subject).to_not receive(:fetch_glue_records)
      expect(subject.glue_record('ns1')).to eq('ns1' => ['1.2.3.4'])
    end

    it 'Not already fetched' do
      expect(subject).to receive(:fetch_glue_records).and_return('ns2' => ['2.3.4.5'])
      expect(subject.glue_record('ns2')).to eq('ns2' => ['2.3.4.5'])
    end

    it 'Not present' do
      expect(subject).to receive(:fetch_glue_records).and_return({})
      expect(subject.glue_record('ns3')).to be nil
    end
  end

  describe '#update_glue_record' do
    it 'Make API request' do
      expect(GandiV5).to receive(:put).with(
        'https://api.gandi.net/v5/domain/domains/example.com/hosts/name',
        '{"ips":["1.2.3.4"]}'
      )
                                      .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.update_glue_record('name', '1.2.3.4')).to eq 'Confirmation message.'
    end

    it 'Update name_servers' do
      expect(GandiV5).to receive(:put).and_return([nil, { 'message' => 'Confirmation message.' }])
      subject.update_glue_record 'name', '1.2.3.4'
      expect(subject.glue_records).to eq('name' => ['1.2.3.4'])
    end
  end

  describe '#delete_glue_record' do
    before(:each) { subject.instance_exec { @glue_records = { 'ns1' => ['1.2.3.4'], 'ns2' => [] } } }

    it 'Make API request' do
      expect(GandiV5).to receive(:delete).with(
        'https://api.gandi.net/v5/domain/domains/example.com/hosts/ns2'
      )
                                         .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.delete_glue_record('ns2')).to eq 'Confirmation message.'
    end

    it 'Update name_servers' do
      expect(GandiV5).to receive(:delete).and_return([nil, { 'message' => 'Confirmation message.' }])
      subject.delete_glue_record 'ns2'
      expect(subject.glue_records).to eq('ns1' => ['1.2.3.4'])
    end
  end

  describe '#livedns' do
    let(:live_dns) { double GandiV5::Domain::LiveDNS }

    it 'Already fetched' do
      subject.instance_exec(live_dns) { |live_dns| @livedns = live_dns }
      expect(subject).to_not receive(:fetch_livedns)
      expect(subject.livedns).to be live_dns
    end

    it 'Not already fetched' do
      expect(subject).to receive(:fetch_livedns).and_return(live_dns)
      expect(subject.livedns).to be live_dns
    end
  end

  describe '#fetch_livedns' do
    before(:each) do
      body_fixture = File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain', 'fetch_livedns.yml')
      body_fixture = File.expand_path(body_fixture)
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/domains/example.com/livedns')
                                      .and_return([nil, YAML.load_file(body_fixture)])
    end

    describe 'Returned live_dns' do
      subject { described_class.new(fqdn: 'example.com').fetch_livedns }

      its('current') { should be :livedns }
      its('name_servers') { should match_array ['1.2.3.4'] }
      its('dnssec_available') { should be true }
      its('livednssec_available') { should be true }
    end

    it 'Updates name_server' do
      expect(subject.name_server).to be nil
      subject.fetch_livedns
      expect(subject.name_server).to be :livedns
    end

    it 'Updates name_servers' do
      subject.instance_exec { @name_servers = [] }
      subject.fetch_livedns
      expect(subject.name_servers).to match_array ['1.2.3.4']
    end
  end

  it '#enable_livedns' do
    expect(GandiV5).to receive(:post).with('https://api.gandi.net/v5/domain/domains/example.com/livedns')
                                     .and_return([nil, { 'message' => 'Confirmation message.' }])
    expect(subject.enable_livedns).to eq 'Confirmation message.'
  end

  describe '#name_servers' do
    let(:nameservers) { double Array }

    it 'Already fetched' do
      subject.instance_exec(nameservers) { |nameservers| @name_servers = nameservers }
      expect(subject).to_not receive(:fetch_name_servers)
      expect(subject.name_servers).to be nameservers
    end

    it 'Not already fetched' do
      expect(subject).to receive(:fetch_name_servers).and_return(nameservers)
      expect(subject.name_servers).to be nameservers
    end
  end

  it '#fetch_name_servers' do
    body_fixture = File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain', 'fetch_name_servers.yml')
    body_fixture = File.expand_path(body_fixture)
    expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/domains/example.com/nameservers')
                                    .and_return([nil, YAML.load_file(body_fixture)])
    expect(subject.fetch_name_servers).to match_array ['1.2.3.4']
  end

  describe '#update_name_servers' do
    subject { described_class.new fqdn: 'example.com', name_servers: [] }
    let(:new_name_servers) { ['a.examle.com', 'b.example.net'] }

    it 'Make API request' do
      expect(GandiV5).to receive(:put).with(
        'https://api.gandi.net/v5/domain/domains/example.com/nameservers',
        '{"nameservers":["a.examle.com","b.example.net"]}'
      )
                                      .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.update_name_servers(new_name_servers)).to eq 'Confirmation message.'
    end

    it 'Update name_servers' do
      expect(GandiV5).to receive(:put).and_return([nil, { 'message' => 'Confirmation message.' }])
      subject.update_name_servers new_name_servers
      expect(subject.name_servers).to be new_name_servers
    end
  end
end
