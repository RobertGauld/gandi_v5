# Gandi V5 API Gem Changelog

## Version 0.1.1

* Enhancements to GandiV5::Domain
  * .create now returns created domain (except in dry-run mode)
* Enhancements to GandiV5::Email::Mailbox
  * .create now returns created mailbox
  * .create now checks for available slots and a valid type has been passed
* Enhancements to GandiV5::Email::Mailbox::Responder
  * Add #enable(message:, ends_at:, starts_at: Time.now) to enable the auto responder in Gandi
  * Add #disable to disable the auto responder in Gandi
* Enhancements to GandiV5::Email::Slot
  * .create now returns created slot
  * #delete now checks for inactiveness and refundableness
* Add support for ruby 2.6.3

## Version 0.1.0

* Initial release.
