# To Do List

* Version 0.2.0
  * Domain:
    * [ ] .restore_information - test when I have a restorable domain
    * [X] .create - return created domain (unless a dry run)
    * [ ] .availability - return a new Availability object
    * [X] .tld - return a new TLD object
    * [X] .tlds - return an array of new TLD object
    * [ ] Add method
          renewal_price(currency: 'GBP', period: 1, sharing_id: self.sharing_id)
  * Email Mailbox:
    * [X] .create - check type is valid
    * [X] .create - check a slot is available
    * [X] .create - fetch created mailbox
  * Email Mailbox Responder:
    * [X] Allow enable/disable from here too
  * Email Slot:
    * [X] #delete - check for inactiveness
    * [X] #delete - check for refundableness
    * [X] .create - fetch created slot
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

* Version 0.2.1
  * Gandi updates from 2019-05-23:
    * [ ] Domain API: Domain hosts (glue records)
    * [ ] Domain API: Domain nameservers
    * [ ] DomainAPI: LiveDNS management ?

* Version 0.2.2
  * [ ] Add LiveDNS::Domain#zone to get the LiveDNS::Zone for the domain
  * [ ] Add LiveDNS::Zone::Snapshot#.zone to get the LiveDNS::Zone for the snapshot.

* Version 0.2.3
  * [ ] Test against truffleruby if aligned with ruby 2.6.0 (looks like it is)
  * [ ] Test against jruby 9.3.0.0 when released (if aligned with ruby 2.6.0)
