# frozen_string_literal: true

describe GandiV5::Organization do
  let(:body_fixtures) { File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Organization')) }

  describe '.fetch' do
    subject { described_class.fetch }
    before :each do
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/organization/user-info')
                                      .and_return(YAML.load_file(File.join(body_fixtures, 'get.yaml')))
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
end
