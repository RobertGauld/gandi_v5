# frozen_string_literal: true

describe GandiV5::Domain::Availability do
  describe '.fetch' do
    let(:body_fixture) do
      File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Domain_Availability', 'fetch.yml'))
    end

    describe 'With default values' do
      subject { described_class.fetch 'example.com' }

      before(:each) do
        if RUBY_VERSION >= '3.1.0'
          expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/check', params: { name: 'example.com' })
                                          .and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
        else
          expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/domain/check', params: { name: 'example.com' })
                                          .and_return([nil, YAML.load_file(body_fixture)])
        end
      end

      its('currency') { should eq 'GBP' }
      its('grid') { should eq 'A' }
      its('products.size') { should eq 1 }
      its('products.first.status') { should eq :unavailable }
      its('products.first.name') { should eq 'example.com' }
      its('products.first.process') { should eq :create }
      its('products.first.taxes.size') { should eq 1 }
      its('products.first.taxes.first.type') { should eq 'service' }
      its('products.first.taxes.first.rate') { should eq 0 }
      its('products.first.taxes.first.name') { should eq 'vat' }
      its('taxes.size') { should eq 1 }
      its('taxes.first.type') { should eq 'service' }
      its('taxes.first.rate') { should eq 0 }
      its('taxes.first.name') { should eq 'vat' }
    end

    describe 'Passes optional query params' do
      %i[country currency duration_unit extension grid lang max_duration period processes sharing_uuid].each do |param|
        it param.to_s do
          url = 'https://api.gandi.net/v5/domain/check'
          expect(GandiV5).to receive(:get).with(url, params: { name: 'example.com', param => 5 }).and_return([nil, {}])
          described_class.fetch('example.com', param => 5)
        end
      end
    end
  end
end
