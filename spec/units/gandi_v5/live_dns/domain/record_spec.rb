# frozen_string_literal: true

describe GandiV5::LiveDNS::Domain::Record do
  subject do
    described_class.new type: 'A', ttl: 900, name: 'www', values: %w[192.168.0.1 192.168.0.2]
  end

  it '#to_s' do
    expect(subject.to_s).to eq "www\t900\tIN\tA\t192.168.0.1\n" \
                               "www\t900\tIN\tA\t192.168.0.2"
  end

  describe 'Record type helpers' do
    it '#a?' do
      expect(subject.a?).to be true
    end

    it '#aaaa?' do
      expect(subject.aaaa?).to be false
    end
  end

  describe 'TTL helpers' do
    describe 'second?' do
      it 'Default of 1' do
        expect(subject.second?).to be false
      end

      it 'Passed value' do
        expect(subject.seconds?(3)).to be false
      end
    end

    describe 'minute?' do
      it 'Default of 1' do
        expect(subject.minute?).to be false
      end

      it 'Passed value' do
        expect(subject.minutes?(3)).to be false
      end
    end

    describe 'hour?' do
      it 'Default of 1' do
        expect(subject.hour?).to be false
      end

      it 'Passed value' do
        expect(subject.hours?(3)).to be false
      end
    end

    describe 'day?' do
      it 'Default of 1' do
        expect(subject.day?).to be false
      end

      it 'Passed value' do
        expect(subject.days?(3)).to be false
      end
    end

    describe 'week?' do
      it 'Default of 1' do
        expect(subject.week?).to be false
      end

      it 'Passed value' do
        expect(subject.weeks?(3)).to be false
      end
    end
  end
end
