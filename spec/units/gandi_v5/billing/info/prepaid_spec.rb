# frozen_string_literal: true

describe GandiV5::Billing::Info::Prepaid do
  describe '#warning?' do
    it 'No warning theshold set' do
      prepaid_info = described_class.new amount: 10, warning_threshold: nil
      expect(prepaid_info.warning?).to be nil
    end

    it 'More than warning theshold' do
      prepaid_info = described_class.new amount: 10, warning_threshold: 5
      expect(prepaid_info.warning?).to be false
    end

    it 'Less than warning theshold' do
      prepaid_info = described_class.new amount: 10, warning_threshold: 20
      expect(prepaid_info.warning?).to be true
    end
  end
end
