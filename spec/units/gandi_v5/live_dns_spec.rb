# frozen_string_literal: true

describe GandiV5::LiveDNS do
  it '.domain' do
    returns = double GandiV5::LiveDNS::Domain
    expect(GandiV5::LiveDNS::Domain).to receive(:fetch).with('example.com').and_return(returns)
    expect(described_class.domain('example.com')).to be returns
  end

  it '.domains' do
    returns = double Array
    expect(GandiV5::LiveDNS::Domain).to receive(:list).and_return(returns)
    expect(described_class.domains).to be returns
  end

  it '.zone' do
    returns = double GandiV5::LiveDNS::Zone
    expect(GandiV5::LiveDNS::Zone).to receive(:fetch).with('zone-uuid').and_return(returns)
    expect(described_class.zone('zone-uuid')).to be returns
  end

  it '.zones' do
    returns = double Array
    expect(GandiV5::LiveDNS::Zone).to receive(:list).and_return(returns)
    expect(described_class.zones).to be returns
  end

  describe '.require_valid_record_type' do
    it 'Does nothing for valid type' do
      expect { described_class.require_valid_record_type 'A' }.to_not raise_error
    end

    it 'Errors on invalid type' do
      expect { described_class.require_valid_record_type 'invalid' }.to raise_error(
        ArgumentError,
        'type must be one of A, AAAA, CNAME, MX, NS, TXT, ALIAS, WKS, ' \
        'SRV, LOC, SPF, CAA, DS, SSHFP, PTR, KEY, DNAME, TLSA, OPENPGPKEY, CDS'
      )
    end
  end
end
