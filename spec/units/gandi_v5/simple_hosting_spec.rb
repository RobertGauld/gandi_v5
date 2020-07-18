# frozen_string_literal: true

describe GandiV5::SimpleHosting do
  it '.instances' do
    returns = double Array
    expect(GandiV5::SimpleHosting::Instance).to receive(:list).and_return(returns)
    expect(described_class.instances).to be returns
  end
end
