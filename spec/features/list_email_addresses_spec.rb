# frozen_string_literal: true

describe 'Examples', :vcr do
  it 'List email addresses' do
    expect($stdout).to receive(:puts).with("alias@example.com\talias for user@example.com").ordered
    expect($stdout).to receive(:puts).with("forward@example.com\tforwards to user@example.com").ordered
    expect($stdout).to receive(:puts).with("user@example.com\tstandard mailbox (0% of 3GB used)").ordered

    # For each domain:
    #   1. Create an empty hash to store address => description
    #   2. Get the mailboxes and add them to the hash
    #   3. Get the forwards and add them to the hash
    #   4. Sort the hash by email address
    #   5. Print the list
    GandiV5::Domain.list.each do |domain|
      emails = {}

      mailboxes = GandiV5::Email::Mailbox.list(domain.fqdn)
      mailboxes.each do |mailbox|
        mailbox.refresh
        emails["#{mailbox.login}@#{domain.fqdn}"] = "#{mailbox.type} mailbox " \
                                             "(#{mailbox.quota_usage.to_i}% " \
                                             "of #{(mailbox.quota / 1024**3).round}GB used)"
        mailbox.aliases.each do |alias_name|
          emails["#{alias_name}@#{domain.fqdn}"] = "alias for #{mailbox.login}@#{domain.fqdn}"
        end
      end

      forwards = GandiV5::Email::Forward.list(domain.fqdn)
      forwards.each do |forward|
        emails["#{forward.source}@#{domain.fqdn}"] = "forwards to #{forward.destinations.join(', ')}"
      end

      emails.sort.each do |address, text|
        puts "#{address}\t#{text}"
      end
    end
  end
end
