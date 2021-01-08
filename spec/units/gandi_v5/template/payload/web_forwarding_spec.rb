# frozen_string_literal: true

describe GandiV5::Template::Payload::WebForwarding do
  describe 'helper methods' do
    context 'an HTTP 301 redirect' do
      subject { described_class.new type: :http301 }
      it('#permanent?') { expect(subject.permanent?).to be true }
      it('#http301?') { expect(subject.http301?).to be true }
      it('#temporary?') { expect(subject.temporary?).to be false }
      it('#http302?') { expect(subject.http302?).to be false }
      it('#found?') { expect(subject.found?).to be false }
    end

    context 'an HTTP 302 redirect' do
      subject { described_class.new type: :http302 }
      it('#permanent?') { expect(subject.permanent?).to be false }
      it('#http301?') { expect(subject.http301?).to be false }
      it('#temporary?') { expect(subject.temporary?).to be true }
      it('#http302?') { expect(subject.http302?).to be true }
      it('#found?') { expect(subject.found?).to be true }
    end

    context 'an http endpoint' do
      subject { described_class.new protocol: :http }
      it('#http?') { expect(subject.http?).to be true }
      it('#https?') { expect(subject.https?).to be false }
      it('#https_only?') { expect(subject.https_only?).to be false }
    end

    context 'an https endpoint' do
      subject { described_class.new protocol: :https }
      it('#http?') { expect(subject.http?).to be true }
      it('#https?') { expect(subject.https?).to be true }
      it('#https_only?') { expect(subject.https_only?).to be false }
    end

    context 'an https_only endpoint' do
      subject { described_class.new protocol: :https_only }
      it('#http?') { expect(subject.http?).to be false }
      it('#https?') { expect(subject.https?).to be true }
      it('#https_only?') { expect(subject.https_only?).to be true }
    end
  end
end
