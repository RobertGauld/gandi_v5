# frozen_string_literal: true

describe GandiV5::Domain::TransferIn::Availability do
  describe '.fetch' do
    let(:body_fixture) do
      File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain_TransferIn_Availability', 'fetch.yml'))
    end

    describe 'Without auth_code' do
      subject { described_class.fetch 'example.com' }

      before(:each) do
        url = 'https://api.gandi.net/v5/domain/transferin/example.com/available'
        if RUBY_VERSION >= '3.1.0'
          expect(GandiV5).to receive(:post).with(url, {})
                                           .and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
        else
          expect(GandiV5).to receive(:post).with(url, {})
                                           .and_return([nil, YAML.load_file(body_fixture)])
        end
      end

      its('available') { should be true }
      its('fqdn') { should eq 'example.com' }
      its('fqdn_unicode') { should eq 'EXAMPLE.COM' }
      its('corporate') { should be false }
      its('internal') { should be false }
      its('durations') { should eq [1, 2, 3] }
      its('minimum_duration') { should eq 1 }
      its('maximum_duration') { should eq 3 }
      its('message') { should eq 'This is a message' }
    end

    describe 'With auth_code' do
      subject { described_class.fetch 'example.com', 'auth-code' }

      before(:each) do
        url = 'https://api.gandi.net/v5/domain/transferin/example.com/available'
        if RUBY_VERSION >= '3.1.0'
          expect(GandiV5).to receive(:post).with(url, { 'authinfo' => 'auth-code' })
                                           .and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
        else
          expect(GandiV5).to receive(:post).with(url, { 'authinfo' => 'auth-code' })
                                           .and_return([nil, YAML.load_file(body_fixture)])
        end
      end

      its('available') { should be true }
      its('fqdn') { should eq 'example.com' }
      its('fqdn_unicode') { should eq 'EXAMPLE.COM' }
      its('corporate') { should be false }
      its('internal') { should be false }
      its('durations') { should eq [1, 2, 3] }
      its('minimum_duration') { should eq 1 }
      its('maximum_duration') { should eq 3 }
      its('message') { should eq 'This is a message' }
    end
  end
end
