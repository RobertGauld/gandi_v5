# frozen_string_literal: true

describe GandiV5::Domain::RenewalInformation do
  describe '#renewable?' do
    before(:each) { Timecop.travel Time.new(2000, 1, 2, 12, 0, 0) }
    let(:future) { Time.new 2000, 1, 3, 0, 0, 0, 0 }
    let(:past) { Time.new 2000, 1, 1, 0, 0, 0, 0 }

    describe 'Is prohibited' do
      describe 'Begins in the future' do
        it 'Ends in the future' do
          info = described_class.new prohibited: true, begins_at: future, ends_at: future
          expect(info.renewable?).to be false
        end

        it 'Ends in the past' do
          info = described_class.new prohibited: true, begins_at: future, ends_at: past
          expect(info.renewable?).to be false
        end

        it 'No end set' do
          info = described_class.new prohibited: true, begins_at: future
          expect(info.renewable?).to be false
        end
      end

      describe 'Begins in the past' do
        it 'Ends in the future' do
          info = described_class.new prohibited: true, begins_at: past, ends_at: future
          expect(info.renewable?).to be false
        end

        it 'Ends in the past' do
          info = described_class.new prohibited: true, begins_at: past, ends_at: past
          expect(info.renewable?).to be false
        end

        it 'No end set' do
          info = described_class.new prohibited: true, begins_at: past
          expect(info.renewable?).to be false
        end
      end
    end

    describe 'Is not prohibited' do
      describe 'Begins in the future' do
        it 'Ends in the future' do
          info = described_class.new prohibited: false, begins_at: future, ends_at: future
          expect(info.renewable?).to be false
        end

        it 'Ends in the past' do
          info = described_class.new prohibited: false, begins_at: future, ends_at: past
          expect(info.renewable?).to be false
        end

        it 'No end set' do
          info = described_class.new prohibited: false, begins_at: future
          expect(info.renewable?).to be false
        end
      end

      describe 'Begins in the past' do
        it 'Ends in the future' do
          info = described_class.new prohibited: false, begins_at: past, ends_at: future
          expect(info.renewable?).to be true
        end

        it 'Ends in the past' do
          info = described_class.new prohibited: false, begins_at: past, ends_at: past
          expect(info.renewable?).to be false
        end

        it 'No end set' do
          info = described_class.new prohibited: false, begins_at: past
          expect(info.renewable?).to be true
        end
      end
    end
  end
end
