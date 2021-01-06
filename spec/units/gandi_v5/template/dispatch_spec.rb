# frozen_string_literal: true

describe GandiV5::Template::Dispatch do
  subject do
    described_class.new uuid: 'dispatch-uuid'
  end

  describe '.fetch' do
    subject { described_class.fetch('dispatch-uuid') }

    before :each do
      expect(GandiV5).to receive(:get).with(url).and_return([nil, YAML.load_file(body_fixture)])
    end

    let(:url) { 'https://api.gandi.net/v5/template/dispatch/dispatch-uuid' }
    let(:body_fixture) do
      File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Template_Dispatch', 'fetch.yml'))
    end

    its('attempt') { should eq 1 }
    its('created_at') { should eq Time.new(2020, 11, 29, 14, 57, 14) }
    its('uuid') { should eq 'dispatch-uuid' }
    its('created_by') { should eq 'sharing-uuid' }
    its('state') { should be :running }
    its('state_message') { should eq 'state message' }
    its('updated_at') { should eq Time.new(2020, 11, 29, 14, 57, 15) }
    its('template_uuid') { should eq 'template-uuid' }
    its('template_name') { should eq 'template' }
    its('target_uuid') { should eq 'target-uuid' }
    its('task_history') do
      should eq(
        [
          {
            at: Time.new(2020, 11, 29, 16, 57, 47),
            what: :name_servers,
            status: :done,
            message: ''
          }
        ]
      )
    end
    its('task_statuses') do
      should eq(
        {
          dns_records: :pending,
          mailboxes: :running,
          name_servers: :done,
          web_redirects: :error
        }
      )
    end

    its('payload.dns_records.count') { should eq 1 }
    its('payload.dns_records.first.name') { should eq 'record-name' }
    its('payload.dns_records.first.type') { should eq 'TXT' }
    its('payload.dns_records.first.values') { should eq ['record-value'] }
    its('payload.dns_records.first.ttl') { should eq 600 }

    its('payload.mailboxes') { should eq ['user-name'] }

    its('payload.name_servers') { should eq ['1.1.1.1'] }

    its('payload.web_redirects.count') { should eq 1 }
    its('payload.web_redirects.first.type') { should eq :http301 }
    its('payload.web_redirects.first.target_url') { should eq 'https://example.com/here' }
    its('payload.web_redirects.first.source_host') { should eq 'here.example.com' }
    its('payload.web_redirects.first.override') { should be true }
    its('payload.web_redirects.first.target_protocol') { should eq :https }
  end
end
