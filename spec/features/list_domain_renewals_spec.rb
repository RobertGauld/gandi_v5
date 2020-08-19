# frozen_string_literal: true

describe 'Examples', :vcr do
  it 'List domain renewals' do
    expect(STDOUT).to receive(:puts).with("2021-03-12\t£8.87\texample.com")

    # For each domain (sorted by assending renewal date) print <date>\t<cost>\t<fqdn>
    GandiV5::Domain.list.each do |domain|
      puts [
        domain.dates.registry_ends_at.to_date,
        "£#{domain.renewal_price.price_after_taxes}",
        domain.fqdn
      ].join("\t")
    end
  end
end
