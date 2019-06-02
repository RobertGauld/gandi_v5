# frozen_string_literal: true

describe GandiV5::Data::Converter do
  let(:proc) { double Proc }

  describe '#to_gandi' do
    it 'Has a to_gandi proc' do
      expect(proc).to receive(:call).with(:value).and_return(:return)
      subject = described_class.new to_gandi: proc
      expect(subject.to_gandi(:value)).to be :return
    end

    it 'Hasn\'t a to_gandi proc' do
      subject = described_class.new
      expect(subject.to_gandi(:value)).to be :value
    end
  end

  describe '#from_gandi' do
    it 'Has a from_gandi proc' do
      expect(proc).to receive(:call).with(:value).and_return(:return)
      subject = described_class.new from_gandi: proc
      expect(subject.from_gandi(:value)).to be :return
    end

    it 'Hasn\'t a from_gandi proc' do
      subject = described_class.new
      expect(subject.from_gandi(:value)).to be :value
    end
  end
end
