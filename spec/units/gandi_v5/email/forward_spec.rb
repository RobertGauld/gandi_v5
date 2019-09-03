# frozen_string_literal: true

describe GandiV5::Email::Forward do
  subject { described_class.new source: 'alice', destinations: ['bob@example.com'], fqdn: 'example.com' }

  describe '#update' do
    it 'ʘ‿ʘ' do
      expect(GandiV5).to receive(:put).with(
        'https://api.gandi.net/v5/email/forwards/example.com/alice',
        '{"destinations":["bob@example.com","charlie@example.com"]}'
      )
                                      .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject.update('bob@example.com', 'charlie@example.com')).to eq 'Confirmation message.'
      expect(subject.destinations).to match_array ['bob@example.com', 'charlie@example.com']
    end

    it 'Empty destinations' do
      expect { subject.update }.to raise_error ArgumentError, 'destinations can\'t be empty'
    end
  end

  it '#delete' do
    expect(GandiV5).to receive(:delete).with(
      'https://api.gandi.net/v5/email/forwards/example.com/alice'
    )
                                       .and_return([nil, { 'message' => 'Confirmation message.' }])
    expect(subject.delete).to eq 'Confirmation message.'
  end

  describe '#to_s' do
    it 'With one destination' do
      expect(subject.to_s).to eq 'alice@example.com -> bob@example.com'
    end

    it 'With many destinations' do
      subject.instance_exec { @destinations = ['bob@example.com', 'charlie@example.com'] }
      expect(subject.to_s).to eq 'alice@example.com -> bob@example.com, charlie@example.com'
    end
  end

  describe '.create' do
    it 'ʘ‿ʘ' do
      response = double(
        RestClient::Response,
        headers: { location: 'https://api.gandi.net/v5/email/forwards/example.com/alice' }
      )
      expect(GandiV5).to receive(:post).with(
        'https://api.gandi.net/v5/email/forwards/example.com',
        '{"source":"alice","destinations":["bob@example.com"]}'
      )
                                       .and_return([response, { 'message' => 'Confirmation message.' }])

      forward = described_class.new fqdn: 'example.com', source: 'alice', destinations: ['bob@example.com']
      expect(described_class.create('example.com', 'alice', 'bob@example.com').to_h).to eq forward.to_h
    end

    it 'Empty destinations' do
      expect { described_class.create('example.com', 'alice') }.to raise_error ArgumentError, 'destinations can\'t be empty'
    end
  end

  describe '.list' do
    let(:body_fixture) do
      File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Email_Forward', 'list.yml'))
    end

    describe 'With default values' do
      subject { described_class.list 'example.com' }

      before :each do
        headers = { params: { page: 1 } }
        expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/forwards/example.com', headers)
                                        .and_return([nil, YAML.load_file(body_fixture)])
      end

      its('count') { should eq 1 }
      its('first.source') { should eq 'alice' }
      its('first.destinations') { should match_array ['bob@example.com', 'charlie@example.com'] }
      its('first.fqdn') { should eq 'example.com' }
    end

    it 'Keeps fetching until no more to get' do
      headers1 = { params: { page: 1, per_page: 1 } }
      headers2 = { params: { page: 2, per_page: 1 } }
      # https://github.com/rubocop-hq/rubocop/issues/7088
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/forwards/example.com', headers1)
                                      .ordered
                                      .and_return([nil, YAML.load_file(body_fixture)])
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/forwards/example.com', headers2)
                                      .ordered
                                      .and_return([nil, []])

      expect(described_class.list('example.com', per_page: 1).count).to eq 1
    end

    it 'Given a range as page number' do
      headers1 = { params: { page: 1, per_page: 1 } }
      headers2 = { params: { page: 2, per_page: 1 } }
      # https://github.com/rubocop-hq/rubocop/issues/7088
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/forwards/example.com', headers1)
                                      .ordered
                                      .and_return([nil, YAML.load_file(body_fixture)])
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/forwards/example.com', headers2)
                                      .ordered
                                      .and_return([nil, []])

      expect(described_class.list('example.com', page: (1..2), per_page: 1).count).to eq 1
    end

    describe 'Passes optional query params' do
      %i[source sort_by].each do |param|
        it param.to_s do
          headers = { params: { page: 1 }.merge(param => 'value') }
          expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/forwards/example.com', headers)
                                          .and_return([nil, []])
          expect(described_class.list('example.com', param => 'value')).to eq []
        end
      end
    end
  end
end
