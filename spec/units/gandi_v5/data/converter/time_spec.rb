# frozen_string_literal: true

describe GandiV5::Data::Converter::Time do
  it '.from_gandi' do
    expect(described_class.from_gandi('2019-02-13T11:04:18Z')).to eq Time.new(2019, 2, 13, 11, 4, 18, 0)
  end

  it '.to_gandi' do
    expect(described_class.to_gandi(Time.new(2019, 2, 13, 11, 4, 18, 0))).to eq '2019-02-13T11:04:18Z'
  end

  it 'nil value' do
    expect(described_class.from_gandi(nil)).to be nil
    expect(described_class.to_gandi(nil)).to be nil
  end
end
