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

  describe '#enable' do
    let(:mailbox) { double GandiV5::Email::Mailbox }
    let(:update) do
      {
        starts_at: '2019-01-01T00:00:00Z',
        ends_at: '2020-01-01T00:00:00Z',
        message: 'Auto response message.',
        enabled: true
      }
    end

    it 'Uses now as default starts_at' do
      starts_at = Time.new(2019, 1, 1, 0, 0, 0, 0)
      Timecop.freeze(starts_at) do
        ends_at = Time.new(2020, 1, 1, 0, 0, 0, 0)
        subject = described_class.new mailbox: mailbox
        expect(mailbox).to receive(:update).with(responder: update)

        subject.enable message: 'Auto response message.', ends_at: ends_at
        expect(subject.enabled).to be true
        expect(subject.message).to eq 'Auto response message.'
        expect(subject.starts_at).to eq starts_at
        expect(subject.ends_at).to eq ends_at
      end
    end

    it 'Uses passed starts_at' do
      starts_at = Time.new(2019, 1, 1, 0, 0, 0, 0)
      ends_at = Time.new(2020, 1, 1, 0, 0, 0, 0)
      subject = described_class.new mailbox: mailbox
      expect(mailbox).to receive(:update).with(responder: update)

      subject.enable message: 'Auto response message.', starts_at: starts_at, ends_at: ends_at
      expect(subject.enabled).to be true
      expect(subject.message).to eq 'Auto response message.'
      expect(subject.starts_at).to eq starts_at
      expect(subject.ends_at).to eq ends_at
    end
  end

  it '#disable' do
    mailbox = double GandiV5::Email::Mailbox
    subject = described_class.new mailbox: mailbox
    expect(mailbox).to receive(:update).with(responder: { enabled: false })

    subject.disable
    expect(subject.enabled).to be false
    expect(subject.message).to be nil
    expect(subject.starts_at).to be nil
    expect(subject.ends_at).to be nil
  end
end
