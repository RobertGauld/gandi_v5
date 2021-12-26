# frozen_string_literal: true

describe GandiV5::Domain::TLD do
  it '.list' do
    body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain_TLD', 'list.yml'))
    if RUBY_VERSION >= '3.1.0'
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/tlds')
                                      .and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
    else
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/tlds')
                                      .and_return([nil, YAML.load_file(body_fixture)])
    end
    expect(described_class.list.map(&:name)).to match_array %w[a b c]
  end

  describe '.fetch' do
    subject { described_class.fetch 'name' }

    before(:each) do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain_TLD', 'fetch.yml'))
      if RUBY_VERSION >= '3.1.0'
        expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/tlds/name')
                                        .and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
      else
        expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/tlds/name')
                                        .and_return([nil, YAML.load_file(body_fixture)])
      end
    end

    its('category') { should eq :ccTLD }
    its('name') { should eq 'eu' }
    its('lock') { should be false }
    its('change_owner') { should be true }
    its('authinfo_for_transfer') { should be true }
    its('full_tld') { should eq 'eu' }
    its('corporate') { should be false }
    its('ext_trade') { should be true }
  end
end
