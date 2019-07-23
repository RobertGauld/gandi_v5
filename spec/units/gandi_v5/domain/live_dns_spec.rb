# frozen_string_literal: true

describe GandiV5::Domain::LiveDNS do
  describe '#classic?' do
    it 'Is using classic DNS' do
      expect(described_class.new(current: :classic).classic?).to be true
    end

    it 'Is using LiveDNS' do
      expect(described_class.new(current: :livedns).classic?).to be false
    end

    it 'Is using custom DNS' do
      expect(described_class.new(current: :custom).classic?).to be false
    end
  end

  describe '#livedns?' do
    it 'Is using classic DNS' do
      expect(described_class.new(current: :classic).livedns?).to be false
    end

    it 'Is using LiveDNS' do
      expect(described_class.new(current: :livedns).livedns?).to be true
    end

    it 'Is using custom DNS' do
      expect(described_class.new(current: :custom).livedns?).to be false
    end
  end

  describe '#custom?' do
    it 'Is using classic DNS' do
      expect(described_class.new(current: :classic).custom?).to be false
    end

    it 'Is using LiveDNS' do
      expect(described_class.new(current: :livedns).custom?).to be false
    end

    it 'Is using custom DNS' do
      expect(described_class.new(current: :custom).custom?).to be true
    end
  end
end
