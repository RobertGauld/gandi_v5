# frozen_string_literal: true

describe GandiV5::Email::Mailbox::Responder do
  describe '#active?' do
    before(:each) { Timecop.travel Time.new(2000, 1, 2, 12, 0, 0) }
    let(:future) { Time.new 2000, 1, 3, 0, 0, 0, 0 }
    let(:past) { Time.new 2000, 1, 1, 0, 0, 0, 0 }

    describe 'Is enabled' do
      describe 'Starts at' do
        describe 'Missing' do
          describe 'Ends at' do
            it 'Missing' do
              responder = described_class.new enabled: true
              expect(responder.active?).to be true
            end

            it 'In the past' do
              responder = described_class.new enabled: true, ends_at: past
              expect(responder.active?).to be false
            end

            it 'In the future' do
              responder = described_class.new enabled: true, ends_at: future
              expect(responder.active?).to be true
            end
          end
        end

        describe 'In the past' do
          describe 'Ends at' do
            it 'Missing' do
              responder = described_class.new enabled: true, starts_at: past
              expect(responder.active?).to be true
            end

            it 'In the past' do
              responder = described_class.new enabled: true, starts_at: past, ends_at: past
              expect(responder.active?).to be false
            end

            it 'In the future' do
              responder = described_class.new enabled: true, starts_at: past, ends_at: future
              expect(responder.active?).to be true
            end
          end
        end

        describe 'In the future' do
          describe 'Ends at' do
            it 'Missing' do
              responder = described_class.new enabled: true, starts_at: future
              expect(responder.active?).to be false
            end

            it 'In the past' do
              responder = described_class.new enabled: true, starts_at: future, ends_at: past
              expect(responder.active?).to be false
            end

            it 'In the future' do
              responder = described_class.new enabled: true, starts_at: future, ends_at: future
              expect(responder.active?).to be false
            end
          end
        end
      end
    end

    describe 'Is disabled' do
      describe 'Starts at' do
        describe 'Missing' do
          describe 'Ends at' do
            it 'Missing' do
              responder = described_class.new enabled: false
              expect(responder.active?).to be false
            end

            it 'In the past' do
              responder = described_class.new enabled: false, ends_at: past
              expect(responder.active?).to be false
            end

            it 'In the future' do
              responder = described_class.new enabled: false, ends_at: future
              expect(responder.active?).to be false
            end
          end
        end

        describe 'In the past' do
          describe 'Ends at' do
            it 'Missing' do
              responder = described_class.new enabled: false, starts_at: past
              expect(responder.active?).to be false
            end

            it 'In the past' do
              responder = described_class.new enabled: false, starts_at: past, ends_at: past
              expect(responder.active?).to be false
            end

            it 'In the future' do
              responder = described_class.new enabled: false, starts_at: past, ends_at: future
              expect(responder.active?).to be false
            end
          end
        end

        describe 'In the future' do
          describe 'Ends at' do
            it 'Missing' do
              responder = described_class.new enabled: false, starts_at: future
              expect(responder.active?).to be false
            end

            it 'In the past' do
              responder = described_class.new enabled: false, starts_at: future, ends_at: past
              expect(responder.active?).to be false
            end

            it 'In the future' do
              responder = described_class.new enabled: false, starts_at: future, ends_at: future
              expect(responder.active?).to be false
            end
          end
        end
      end
    end
  end
end
