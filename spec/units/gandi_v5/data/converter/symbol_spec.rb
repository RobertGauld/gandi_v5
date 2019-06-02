# frozen_string_literal: true

describe GandiV5::Data::Converter::Symbol do
  it '.from_gandi' do
    expect(described_class.from_gandi('value')).to eq :value
  end

  it '.to_gandi' do
    expect(described_class.to_gandi(:value)).to eq 'value'
  end

  it 'nil value' do
    expect(described_class.from_gandi(nil)).to be nil
    expect(described_class.to_gandi(nil)).to be nil
  end
end
