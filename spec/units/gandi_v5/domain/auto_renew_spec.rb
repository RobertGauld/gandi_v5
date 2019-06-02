# frozen_string_literal: true

describe GandiV5::Domain::AutoRenew do
  before(:each) { subject.domain = double GandiV5::Domain, fqdn: 'example.com' }
  let(:url) { 'https://api.gandi.net/v5/domain/domains/example.com/autorenew' }

  it '#disable' do
    expect(GandiV5).to receive(:patch).with(url, '{"enabled":false}')
                                      .and_return('message' => 'Confirmation message.')
    expect(subject.disable).to eq 'Confirmation message.'
    expect(subject.enabled).to be false
  end

  describe '#enable' do
    it 'Success' do
      expect(GandiV5).to receive(:patch).with(url, '{"enabled":true,"duration":1,"org_id":"org-uuid"}')
                                        .and_return('message' => 'Confirmation message.')
      expect(subject.enable(org_id: 'org-uuid', duration: 1)).to eq 'Confirmation message.'
      expect(subject.enabled).to be true
    end

    it 'Duration too low' do
      expect(GandiV5).to_not receive(:patch)
      expect { subject.enable(org_id: 'org-uuid', duration: 0) }.to raise_error ArgumentError,
                                                                                'duration can not be less than 1'
      expect(subject.enabled).to be nil
    end

    it 'Duration too high' do
      expect(GandiV5).to_not receive(:patch)
      expect { subject.enable(org_id: 'org-uuid', duration: 10) }.to raise_error ArgumentError,
                                                                                 'duration can not be more than 9'
      expect(subject.enabled).to be nil
    end

    describe 'Missing duration' do
      it 'Uses #duration if present' do
        expect(GandiV5).to receive(:patch).with(url, '{"enabled":true,"duration":5,"org_id":"org-uuid"}')
                                          .and_return('message' => 'Confirmation message.')
        expect(subject).to receive(:duration).and_return(5)
        expect(subject.enable(org_id: 'org-uuid')).to eq 'Confirmation message.'
        expect(subject.enabled).to be true
      end

      it 'Uses 1 if #duration not present' do
        expect(GandiV5).to receive(:patch).with(url, '{"enabled":true,"duration":1,"org_id":"org-uuid"}')
                                          .and_return('message' => 'Confirmation message.')
        expect(subject.enable(org_id: 'org-uuid')).to eq 'Confirmation message.'
        expect(subject.enabled).to be true
      end
    end

    describe 'Missing org_id' do
      it 'Uses #org_id if present' do
        expect(GandiV5).to receive(:patch).with(url, '{"enabled":true,"duration":1,"org_id":"org-uuid"}')
                                          .and_return('message' => 'Confirmation message.')
        expect(subject).to receive(:org_id).and_return('org-uuid')
        expect(subject.enable).to eq 'Confirmation message.'
        expect(subject.enabled).to be true
      end

      it 'Errors if #org_id not present' do
        expect(GandiV5).to_not receive(:patch)
        expect { subject.enable }.to raise_error ArgumentError,
                                                 'org_id is required'
        expect(subject.enabled).to be nil
      end
    end
  end
end
