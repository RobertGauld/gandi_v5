# frozen_string_literal: true

describe GandiV5::Organization do
  let(:body_fixtures) { File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Organization')) }

  describe '.list' do
    describe 'With default values' do
      subject { described_class.list }

      before :each do
        if RUBY_VERSION >= '3.1.0'
          expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/organization/organizations', params: {})
                                          .and_return(
                                            [
                                              nil,
                                              YAML.load_file(File.join(body_fixtures, 'list.yml'), permitted_classes: [Time])
                                            ]
                                          )
        else
          expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/organization/organizations', params: {})
                                          .and_return(
                                            [
                                              nil,
                                              YAML.load_file(File.join(body_fixtures, 'list.yml'))
                                            ]
                                          )
        end
      end

      its('count') { should eq 1 }
      its('first.uuid') { should eq 'organization-uuid' }
      its('first.name') { should eq 'FirstLast' }
      its('first.first_name') { should eq 'First' }
      its('first.last_name') { should eq 'Last' }
    end

    describe 'Passes optional query params' do
      it 'name' do
        expect(GandiV5).to receive(:get).with(
          'https://api.gandi.net/v5/organization/organizations',
          params: { '~name' => '5' }
        )
                                        .and_return([nil, []])
        expect(described_class.list(name: '5')).to eq []
      end

      %i[type permission sort_by].each do |param|
        it param.to_s do
          headers = { param => 5 }
          expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/organization/organizations', params: headers)
                                          .and_return([nil, []])
          expect(described_class.list(**headers)).to eq []
        end
      end
    end
  end

  describe '.fetch' do
    subject { described_class.fetch }
    before :each do
      if RUBY_VERSION >= '3.1.0'
        expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/organization/user-info')
                                        .and_return(
                                          [
                                            nil,
                                            YAML.load_file(File.join(body_fixtures, 'fetch.yml'), permitted_classes: [Time])
                                          ]
                                        )
      else
        expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/organization/user-info')
                                        .and_return(
                                          [
                                            nil,
                                            YAML.load_file(File.join(body_fixtures, 'fetch.yml'))
                                          ]
                                        )
      end
    end

    its('uuid') { should eq 'organization-uuid' }
    its('username') { should eq 'UserName' }
    its('name') { should eq 'FirstLast' }
    its('first_name') { should eq 'First' }
    its('last_name') { should eq 'Last' }
    its('lang') { should eq 'en' }
    its('street_address') { should eq 'Street Address' }
    its('city') { should eq 'City' }
    its('zip') { should eq 'Post Code' }
    its('country') { should eq 'GB' }
    its('email') { should eq 'username@example.com' }
    its('phone') { should eq '+12.34567890' }
    its('security_email') { should eq 'security@example.com' }
    its('security_phone') { should eq '+23.45678901' }
    its('security_email_validated') { should eq true }
    its('security_email_validation_deadline') { should eq Time.new(2017, 11, 22, 17, 13, 33) }
  end

  it '#customers' do
    subject = described_class.new uuid: 'org_uuid'
    returns = double Array
    expect(GandiV5::Organization::Customer).to receive(:list).with('org_uuid', param: :value).and_return(returns)
    expect(subject.customers('org_uuid', param: :value)).to be returns
  end

  it '#create_customer' do
    subject = described_class.new uuid: 'org_uuid'
    returns = double Object
    expect(GandiV5::Organization::Customer).to receive(:create).with('org_uuid', param: :value).and_return(returns)
    expect(subject.create_customer('org_uuid', param: :value)).to be returns
  end
end
