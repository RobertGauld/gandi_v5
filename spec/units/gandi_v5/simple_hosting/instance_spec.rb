# frozen_string_literal: true

describe GandiV5::SimpleHosting::Instance do
  let :body_list do
    YAML.load_file(
      File.expand_path(
        File.join('spec', 'fixtures', 'bodies', 'GandiV5_SimpleHosting_Instance', 'list.yml')
      )
    )
  end
  let :body_fetch do
    YAML.load_file(
      File.expand_path(
        File.join('spec', 'fixtures', 'bodies', 'GandiV5_SimpleHosting_Instance', 'fetch.yml')
      )
    )
  end

  subject do
    described_class.new uuid: 'instance-uuid'
  end

  describe 'Actions' do
    let(:url) { 'https://api.gandi.net/v5/simplehosting/instances/instance-uuid/action' }

    %i[restart console reset_database_password].each do |action|
      it ".#{action}" do
        expect(GandiV5).to receive(:post).with(url, "{\"action\":\"#{action}\"}")
                                         .and_return([nil, 'Confirmation message'])
        expect(subject.send(action)).to eq 'Confirmation message'
      end
    end
  end

  it '#refresh' do
    expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/simplehosting/instances/instance-uuid')
                                    .and_return([nil, body_fetch])
    subject.refresh
    expect(subject.access_information).to_not be nil
  end

  describe 'Helper methods' do
    describe 'Status' do
      context 'waiting_bill' do
        subject { described_class.new status: :waiting_bill }
        its('waiting_bill?') { should be true }
        its('being_created?') { should be false }
        its('active?') { should be false }
        its('paused?') { should be false }
        its('locked?') { should be false }
        its('being_deleted?') { should be false }
      end
      context 'being_created' do
        subject { described_class.new status: :being_created }
        its('waiting_bill?') { should be false }
        its('being_created?') { should be true }
        its('active?') { should be false }
        its('paused?') { should be false }
        its('locked?') { should be false }
        its('being_deleted?') { should be false }
      end
      context 'active' do
        subject { described_class.new status: :active }
        its('waiting_bill?') { should be false }
        its('being_created?') { should be false }
        its('active?') { should be true }
        its('paused?') { should be false }
        its('locked?') { should be false }
        its('being_deleted?') { should be false }
      end
      context 'paused' do
        subject { described_class.new status: :paused }
        its('waiting_bill?') { should be false }
        its('being_created?') { should be false }
        its('active?') { should be false }
        its('paused?') { should be true }
        its('locked?') { should be false }
        its('being_deleted?') { should be false }
      end
      context 'locked' do
        subject { described_class.new status: :locked }
        its('waiting_bill?') { should be false }
        its('being_created?') { should be false }
        its('active?') { should be false }
        its('paused?') { should be false }
        its('locked?') { should be true }
        its('being_deleted?') { should be false }
      end
      context 'being_deleted' do
        subject { described_class.new status: :being_deleted }
        its('waiting_bill?') { should be false }
        its('being_created?') { should be false }
        its('active?') { should be false }
        its('paused?') { should be false }
        its('locked?') { should be false }
        its('being_deleted?') { should be true }
      end
    end
  end

  describe '.list' do
    subject { described_class.list }
    let(:url) { 'https://api.gandi.net/v5/simplehosting/instances' }

    describe 'With default parameters' do
      before :each do
        expect(GandiV5).to receive(:paginated_get).with(url, (1..), 100, params: {})
                                                  .and_yield(body_list)
      end

      its('count') { should eq 1 }
      its('first.created_at') { should eq Time.new(2020, 1, 2, 12, 34, 56) }
      its('first.database.name') { should eq 'database name' }
      its('first.database.status') { should eq 'database status' }
      its('first.database.version') { should eq 'database version' }
      its('first.data_center') { should eq 'FR-SD5' }
      its('first.expire_at') { should eq Time.new(2021, 1, 2, 12, 34, 56) }
      its('first.uuid') { should eq 'instance-uuid' }
      its('first.language.name') { should eq 'ruby' }
      its('first.language.single_application') { should be true }
      its('first.language.status') { should eq 'great' }
      its('first.language.version') { should eq '2.7' }
      its('first.name') { should eq 'instance name' }
      its('first.sharing_space.uuid') { should eq 'sharing-space-uuid' }
      its('first.sharing_space.name') { should eq 'sharing space name' }
      its('first.size') { should eq 's+' }
      its('first.snapshot_enabled') { should be true }
      its('first.status') { should eq 'active' }
      its('first.storage') { should eq({ base: '20 GB', additional: '10 GB', total: '30 GB' }) }
      its('first.auto_renew') { should eq '1 m' }
    end

    describe 'Passes optional query params' do
      %i[sharing_id name fqdn size status sort_by].each do |param|
        it param do
          expect(GandiV5).to receive(:paginated_get).with(url, (1..), 100, params: { param => 'value' })
                                                    .and_return([nil, []])
          described_class.list(param => 'value')
        end
      end
    end
  end

  describe '.fetch' do
    subject { described_class.fetch 'instance-uuid' }

    before :each do
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/simplehosting/instances/instance-uuid')
                                      .and_return([nil, body_fetch])
    end

    its('access_information') { should be_a Hash }
    its('created_at') { should eq Time.new(2020, 1, 2, 12, 34, 56, 0) }
    its('database.name') { should eq 'database name' }
    its('database.status') { should eq 'database status' }
    its('database.version') { should eq 'database version' }
    its('data_center') { should eq 'FR-SD5' }
    its('expire_at') { should eq Time.new(2021, 1, 2, 12, 34, 56, 0) }
    its('uuid') { should eq 'instance-uuid' }
    its('is_trial') { should be false }
    its('language.name') { should eq 'ruby' }
    its('language.single_application') { should be true }
    its('language.status') { should eq 'great' }
    its('language.version') { should eq '2.7' }
    its('name') { should eq 'instance name' }
    its('sharing_space.uuid') { should eq 'sharing-space-uuid' }
    its('sharing_space.name') { should eq 'sharing space name' }
    its('size') { should eq 's+' }
    its('snapshot_enabled') { should be true }
    its('status') { should eq 'active' }
    its('storage') { should eq({ base: '20 GB', additional: '10 GB', total: '30 GB' }) }
    its('virtual_hosts.first.fqdn') { should eq 'vhost1.example.com' }
    its('auto_renew') { should eq '1 m' }
    its('compatible_applications.first.name') { should eq 'compatable name' }
    its('compatible_applications.first.parameters') { should be_a Hash }
    its('password_updated_at') { should eq Time.new(2020, 6, 2, 12, 34, 56, 0) }
    its('upgrade_to.first.name') { should eq 'upgrade to name' }
    its('upgrade_to.first.status') { should eq 'upgrade to status' }
    its('upgrade_to.first.type') { should eq 'database' }
    its('upgrade_to.first.version') { should eq 'upgrade to version' }
  end
end
