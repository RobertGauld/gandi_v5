# To Do List

* Version 0.1.1
  * Domain:
    * [ ] .restore_information - test when I have a restorable domain
    * [ ] .create - return created domain (unless a dry run)
    * [ ] .availability - return a new Availability object
    * [ ] .tld - return a new TLD object
    * [ ] .tlds - return an array of new TLD object
    * [ ] Add method
          renewal_price(currency: 'GBP', period: 1, sharing_id: self.sharing_id)
  * Email Mailbox:
    * [X] .create - check type is valid
    * [X] .create - check a slot is available
    * [X] .create - fetch created mailbox
  * Email Mailbox Responder:
    * [ ] Allow enable/disable from here too
  * Email Slot:
    * [ ] #delete - check for inactiveness
    * [ ] #delete - check for refundableness
    * [ ] .create - fetch created slot
  * LiveDNS Domain:
    * [ ] #replace_??_records_for - incorporate into #replace_records_for
          <https://www.rubydoc.info/gems/yard/file/docs/Tags.md#override>
    * [ ] Make record type a symbol
    * [ ] Add #zone method
  * LiveDNS Zone:
    * [ ] .create - fetch created zone
    * [ ] #replace_??_records_for - incorporate into #replace_records_for
          <https://www.rubydoc.info/gems/yard/file/docs/Tags.md#override>
    * [ ] Make record type a symbol
    * [ ] Add #zone method
  * LiveDNS Zone Snapshot:
    * [ ] Move method for getting listing to here

* Version 0.1.2
  * Gandi updates from 2019-05-23:
    * [ ] Domain API: Domain hosts (glue records)
    * [ ] Domain API: Domain nameservers
    * [ ] DomainAPI: LiveDNS management ?

* Version 0.1.3
  * [ ] Test against truffleruby if aligned with ruby 2.6.0
  * [ ] Test against jruby if aligned with ruby 2.6.0
