# Gandi V5 API Gem Changelog

## Version 0.6.0

* 

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
  * .availability(fqdn, **options) moved to GandiV5::Domain::Availability.fetch(fqdn, **options)
  * .create now returns created domain (except in dry-run mode)
  * .tlds moved to GandiV5::Domain::TLD.list
  * .tld(name) moved to GandiV5::Domain::TLD.fetch(name)
  * #renewal_price(currency: 'GBP', period: 1) added
* Enhancements to GandiV5::Email::Mailbox
  * .create now returns created mailbox
  * .create now checks for available slots and a valid type has been passed
* Enhancements to GandiV5::Email::Mailbox::Responder
  * Add #enable(message:, ends_at:, starts_at: Time.now) to enable the auto responder in Gandi
  * Add #disable to disable the auto responder in Gandi
* Enhancements to GandiV5::Email::Slot
  * .create now returns created slot
  * #delete now checks for inactiveness and refundableness
* Enhancements to GandiV5::LiveDNS::Domain
  * Add #zone and #fetch_zone
  * Remove #replace_*_records_for methods
  * Changes to #replace_records_for to allow calling with name, type, ttl and values. When calling with name and fecords records MUST be passed as an array.
* Enhancements to GandiV5::LiveDNS::Zone
  * .create now returns created zone
  * Remove #replace_*_records_for methods
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
