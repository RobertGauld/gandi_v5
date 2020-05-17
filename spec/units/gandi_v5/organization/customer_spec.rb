# frozen_string_literal: true

describe GandiV5::Organization::Customer do
  let(:body_fixtures) { File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Organization_Customer')) }

  describe '.create' do
    let(:url) { 'https://api.gandi.net/v5/organization/organizations/uuid/customers' }
    let(:attrs) do
      {
        city: 'Ci',
        country: 'Co',
        email: 'a@e',
        firstname: 'f',
        lastname: 'l',
        phone: '0',
        streetaddr: 'sa',
        type: :individual
      }
    end

    it 'Success' do
      response = double RestClient::Response, headers: { location: '' }
      expect(GandiV5).to receive(:post).with(url, attrs.to_json).and_return([response, nil])
      expect(described_class.create('uuid', **attrs)).to be nil
    end

    describe 'Checks for required attributes' do
      %i[city country email firstname lastname phone streetaddr type].each do |attr|
        it attr do
          attrs.delete attr
          expect { described_class.new('org_uuid', **attrs) }.to raise_exception ArgumentError
        end
      end
    end

    it 'Invalid type' do
      attrs[:type] = :invalid
      expect { described_class.new('org_uuid', **attrs) }.to raise_exception ArgumentError
    end
  end

  describe '.list' do
    describe 'With default values' do
      subject { described_class.list('uuid') }

      before :each do
        url = 'https://api.gandi.net/v5/organization/organizations/uuid/customers'
        expect(GandiV5).to receive(:get).with(url, params: {})
                                        .and_return([nil, YAML.load_file(File.join(body_fixtures, 'list.yml'))])
      end

      its('count') { should eq 1 }
      its('first.uuid') { should eq 'customer-uuid' }
      its('first.name') { should eq 'FirstLast' }
      its('first.first_name') { should eq 'First' }
      its('first.last_name') { should eq 'Last' }
      its('first.email') { should eq 'first.last@example.com' }
      its('first.type') { should eq :individual }
      its('first.org_name') { should eq 'Org' }
    end

    describe 'Passes optional query params' do
      let(:url) { 'https://api.gandi.net/v5/organization/organizations/org_uuid/customers' }

      it 'name' do
        expect(GandiV5).to receive(:get).with(url, params: { '~name' => '5' })
                                        .and_return([nil, []])
        expect(described_class.list('org_uuid', name: '5')).to eq []
      end

      %i[permission sort_by].each do |param|
        it param.to_s do
          headers = { param => 5 }
          expect(GandiV5).to receive(:get).with(url, params: headers)
                                          .and_return([nil, []])
          expect(described_class.list('org_uuid', **headers)).to eq []
        end
      end
    end
  end
end
