# Gandi V5 API Gem Changelog

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
* Enhancements to GandiV5::LiveDNS::Zone::Snapshot
  * Add .list
  * Add .fetch
  * Add #zone and #fetch_zone
* Add support for ruby 2.6.3

## Version 0.1.0

* Initial release.
