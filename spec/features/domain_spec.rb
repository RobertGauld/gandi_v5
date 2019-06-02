# frozen_string_literal: true

describe 'Domain features' do
  it 'List domains', :vcr do
    list = GandiV5::Domain.list

    expect(list.count).to eq 1
    expect(list.first.fqdn).to eq 'example.net'
    expect(list.first.fqdn_unicode).to eq 'example.net'
    expect(list.first.name_servers).to be nil
    expect(list.first.services).to be nil
    expect(list.first.sharing_space).to be nil
    expect(list.first.status).to match_array [:clientTransferProhibited]
    expect(list.first.tld).to eq 'net'
    expect(list.first.dates.registry_created_at).to eq Time.new(2019, 2, 13, 10, 4, 18)
    expect(list.first.dates.updated_at).to eq Time.new(2019, 2, 25, 16, 20, 49)
    expect(list.first.dates.authinfo_expires_at).to be nil
    expect(list.first.dates.created_at).to eq Time.new(2019, 2, 13, 11, 4, 18)
    expect(list.first.dates.deletes_at).to be nil
    expect(list.first.dates.hold_begins_at).to be nil
    expect(list.first.dates.hold_ends_at).to be nil
    expect(list.first.dates.pending_delete_ends_at).to be nil
    expect(list.first.dates.registry_ends_at).to eq Time.new(2021, 2, 13, 10, 4, 18)
    expect(list.first.dates.renew_begins_at).to be nil
    expect(list.first.dates.restore_ends_at).to be nil
    expect(list.first.can_tld_lock).to be nil
    expect(list.first.auto_renew.dates).to be nil
    expect(list.first.auto_renew.duration).to be nil
    expect(list.first.auto_renew.enabled).to be false
    expect(list.first.auto_renew.org_id).to be nil
    expect(list.first.auth_info).to be nil
    expect(list.first.uuid).to eq 'ba1167be-2f76-11e9-9dfb-00163ec4cb00'
    expect(list.first.sharing_uuid).to be nil
    expect(list.first.tags).to match_array []
    expect(list.first.trustee_roles).to be nil
    expect(list.first.owner).to eq 'alice_doe'
    expect(list.first.organisation_owner).to eq 'alice_doe'
    expect(list.first.domain_owner).to eq 'Alice Doe'
    expect(list.first.name_server).to be :livedns
  end

  it 'Renew domain', :vcr do
    expect(GandiV5::Domain.fetch('example.net').renew_for(2)).to eq 'Domain renewed.'
  end
end
