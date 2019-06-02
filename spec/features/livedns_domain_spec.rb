# frozen_string_literal: true

describe 'LiveDNS Domain features' do
  it 'List domains', :vcr do
    list = GandiV5::LiveDNS::Domain.list
    expect(list.map(&:fqdn)).to match_array %w[example.com example.net]
  end
end
