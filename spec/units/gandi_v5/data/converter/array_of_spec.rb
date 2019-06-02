# frozen_string_literal: true

describe GandiV5::Data::Converter::ArrayOf do
  subject { described_class.new GandiV5::Data::Converter::Symbol }

  it '#from_gandi' do
    expect(subject.from_gandi(['value'])).to match_array [:value]
  end

  it '#to_gandi' do
    expect(subject.to_gandi([:value])).to match_array ['value']
  end

  it 'nil value' do
    expect(subject.from_gandi(nil)).to be nil
    expect(subject.to_gandi(nil)).to be nil
  end
end
