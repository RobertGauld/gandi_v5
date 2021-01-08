# Gandi V5 API Gem Changelog

* GandiV5::Domain
  * Add \#transfer_lock(lock = true) and \#transfer_unlock
  * Add template_id argument to .create
  * Add \#web_redirections -> GandiV5::Domain::WebRedirection.list
  * Add \#new_web_redirection -> GandiV5::Domain::WebRedirection.create
* GandiV5::Domain::TransferIn
  * Add template_id argument to .create
* GandiV5::Domain::WebRedirection
* GandiV5::SimpleHosting::Instance::VirtualHost: (I don't use simple hosting myself so it's possible I've misread the docs and a bug is waiting to be found, please add an issue if I have)
  * Add .create (aliased as GandiV5::SimpleHosting::Instance#create_virtual_host)
  * Add \#delete
  * Add \#update
* GandiV5::Template
* GandiV5::Template::Dispatch
* Add testing against truffleruby-20.3.0

## Version 0.9.1

* Add testing against ruby 2.7.2 and 3.0.0

## Version 0.9.0

* Add transferring a domain to Gandi (I don't have any domains outside Gandi to test this myself so it's possible I've misread the docs and a bug is waiting to be found, please add an issue if I have):
  * GandiV5::Domain::TransferIn:
    * .create(fqdn, \*\*options)
    * .fetch(fqdn)
    * .relaunch(fqdn)
    * .resend_foa_emails(fqdn, email_address)
    * \#relaunch
    * \#resend_foa_emails(email_address)
  * GandiV5::Domain::TransferIn::Availabillity:
    * .fetch(fqdn, auth_code = nil)
* Documentation improvements

## Version 0.8.0

* Domain:
  * .list - add resellee_id filter
* Added simple hosting: (I don't use simple hosting myself so it's possible I've misread the docs and a bug is waiting to be found, please add an issue if I have)
  * SimpleHosting::Instance
  * SimpleHosting::Instance::VirtualHost
  * SimpleHosting::Instance::Application
  * SimpleHosting::Instance::Database
  * SimpleHosting::Instance::Language
  * SimpleHosting::Instance::Upgrade
* GandiV5::Domain::SharingSpace moved to GandiV5::SharingSpace

## Version 0.7.0

* LiveDNS:
  * Rename LiveDNS::RecordSet to LiveDNS::Domain::Record
  * Domains:
    * .list now returns an array of strings
    * Can no longer change the zone used by a domain
    * Added automatic_snapshots attribute for whether snapshots are automatically created when a modification is made to this domain's records
    * \#replace_records and \#replace_records_for merged into \#replace_records
      * If replacing with a zone file use the new #replace_zone_lines
    * Added:
      * .create
      * .record_types
      * .generic_name_servers(fqdn)
      * \#name_servers and #fetch_name_servers
      * \#tsig_keys, #fetch_tsig_keys, \#add_tsig_key, \#remove_tsig_key
      * \#axfr_clients, #fetch_axfr_clients, #add_axfr_client, \#remove_axfr_client
      * ::DnssecKeys, #dnssec_keys, #fetch_dnssec_keys
  * Snapshots:
    * Moved to live under LiveDNS::Domain not LiveDNS::Zone
    * Are now accessed via the fully qualified domain name NOT the zone's UUID
    * Ability to access the zone from a snapshot is removed
    * Taking a snapshot now allows for named snapshots
    * Added automatic attribute for when a snapshot was taken due to a zone change
    * .list now returns an array of snapshots (records are fetched in a seperate request when first needed)
  * Zone removed.

## Version 0.6.0

* GandiV5::Email::Slot.create now supports sharing_id
* GandiV5::Email::Slot.create's type argument is now named not positional
* Add reseller information to GandiV5::Domain

## Version 0.5.0

* Add support for truffleruby 20.1.0
* Fix issue with rails in production

## Version 0.4.0

* Fix exception when delete returns no content-type
* Add support for ruby 2.7.0
* Add up/downgrading mailbox offer
* Add dry run option to creating a mailbox
* Add sharing_id & dry run option for renewing domain
* Add listing customers under a reseller organization (GandiV5::Organization::Customer.list and GandiV5::Organization#customers)
* Add creating customer under a reseller organization (GandiV5::Organization::Customer.create and GandiV5::Organization#create_customer)

## Version 0.3.0

* Additions to GandiV5::Domain
  * Glue record management
  * LiveDNS management
  * Name server management
* Update GandiV5::Domain.create to allow purchasing as a reseller and billing to a different organization
* Add forwarding address management to GandiV5::Email::Forwarding
* Add GandiV5::Organization.list
* Uses Zeitwerk for auto loading
* Add aliasing methods:
  * GandiV5::Domain.mailboxes -> GandiV5::Email::Mailbox.list
  * GandiV5::Domain.mailbox_slots -> GandiV5::Email::Slot.list
  * GandiV5::Domain.email_forwards -> GandiV5::Email::Forward.list

## Version 0.2.0

* Enhancements to GandiV5::Domain
  * .availability(fqdn, \*\*options) moved to GandiV5::Domain::Availability.fetch(fqdn, \*\*options)
  * .create now returns created domain (except in dry-run mode)
  * .tlds moved to GandiV5::Domain::TLD.list
  * .tld(name) moved to GandiV5::Domain::TLD.fetch(name)
  * \#renewal_price(currency: 'GBP', period: 1) added
* Enhancements to GandiV5::Email::Mailbox
  * .create now returns created mailbox
  * .create now checks for available slots and a valid type has been passed
* Enhancements to GandiV5::Email::Mailbox::Responder
  * Add #enable(message:, ends_at:, starts_at: Time.now) to enable the auto responder in Gandi
  * Add #disable to disable the auto responder in Gandi
* Enhancements to GandiV5::Email::Slot
  * .create now returns created slot
  * \#delete now checks for inactiveness and refundableness
* Enhancements to GandiV5::LiveDNS::Domain
  * Add #zone and #fetch_zone
  * Remove #replace_\*_records_for methods
  * Changes to #replace_records_for to allow calling with name, type, ttl and values. When calling with name and fecords records MUST be passed as an array.
* Enhancements to GandiV5::LiveDNS::Zone
  * .create now returns created zone
  * Remove #replace_\*_records_for methods
  * Changes to #replace_records_for to allow calling with name, type, ttl and values. When calling with name and fecords records MUST be passed as an array.
* Enhancements to GandiV5::LiveDNS::Zone::Snapshot
  * Add .list
  * Add .fetch
  * Add #zone and #fetch_zone
* Add support for ruby 2.6.3
* Add aliasing methods:
  * GandiV5.domains -> GandiV5::Domain.list
  * GandiV5.domain -> GandiV5::Domain.fetch
  * GandiV5.mailboxes -> GandiV5::Email::Mailbox.list
  * GandiV5.mailbox_slots -> GandiV5::Email::Slot.list
  * GandiV5::LiveDNS.domains -> GandiV5::LiveDNS::Domain.list
  * GandiV5::LiveDNS.domain -> GandiV5::LiveDNS::Domain.fetch
  * GandiV5::LiveDNS.zones -> GandiV5::LiveDNS::Zone.list
  * GandiV5::LiveDNS.zone -> GandiV5::LiveDNS::Zone.fetch

## Version 0.1.0

* Initial release.
