# frozen_string_literal: true

describe 'Mailbox features' do
  it 'List mailboxes', :vcr do
    list = GandiV5::Email::Mailbox.list 'example.net'

    expect(list.count).to eq 1
    expect(list.first.login).to eq 'alice'
    expect(list.first.fqdn).to eq 'example.net'
    expect(list.first.address).to eq 'alice@example.net'
    expect(list.first.uuid).to eq '066743e5-96e4-4a1d-9195-8b8a700a8a79'
    expect(list.first.type).to be :standard
    expect(list.first.quota_used).to eq 1_200
    expect(list.first.aliases).to be nil
    expect(list.first.fallback_email).to be nil
    expect(list.first.responder).to be nil
  end
end
