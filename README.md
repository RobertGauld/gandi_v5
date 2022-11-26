[![Gem Version](https://badge.fury.io/rb/gandi_v5.png)](http://badge.fury.io/rb/gandi_v5)
[![Commit Checks](https://github.com/robertgauld/gandi_v5/workflows/Commit%20Checks/badge.svg)](https://github.com/robertgauld/gandi_v5/actions?query=workflow%3A%22Commit+Checks%22)
[![Coveralls Status](https://coveralls.io/repos/robertgauld/gandi_v5/badge.png?branch=main)](https://coveralls.io/r/robertgauld/gandi_v5)
[![Code Climate](https://codeclimate.com/github/robertgauld/gandi_v5.png?branch=main)](https://codeclimate.com/github/robertgauld/gandi_v5)

## Ruby Versions

This gem supports the following versions of ruby, it may work on other versions but is not tested against them so don't rely on it.

* ruby:
  * 2.6.0 - 2.6.7
  * 2.7.0 - 2.7.7
  * 3.0.0 - 3.0.5
  * 3.1.0 - 3.1.3
  * truffleruby 20.1.0 - 22.3.0 **(Except: 21.3.0, and 22.0.0.2 due to "truffleruby: an internal exception escaped out of the interpreter")**
  * jruby 9.3.7.0 - jruby-9.4.0.0

This gem doesn't yet support the following versions of ruby, although hopefully it soon will.

* rubinius - not yet at parity with ruby 2.6.x


## Gandi V5

Make use of Gandi's V5 API.
See the table in the [Versioning section](#Versioning) to see what Gandi
API Changes each version is current for.

Gandi say: **_"Please note that this API is currently in BETA testing, so care should be taken when used in production._"**

But then you were going to be careful anyway as this gem is currently in the version 0.something range weren't you!

Details of Gandi's API can be found at:

* <https://api.gandi.net/docs/>
* <https://doc.livedns.gandi.net/>

Details of the gem's API can be found at <https://rubydoc.info/github/robertgauld/gandi_v5/main>

## Installation

If you're using bundler then add it to your Gemfile and run the bundle command.

```ruby
gem 'gandi_v5', '~> 0.10'
```

If you're not using bundler then install it from the command line.
```bash
gem install gandi_v5 -v '~> 0.10'
```

## Usage

### Setup

You'll need you Gandi API KEY, you can get this by logging into Gandi and
navigating to User Settings -> Change password & configure access restrictions.

```ruby
require 'gandi_v5'    # Unless you're using Bundler
GandiV5.api_key = '…' # Unless you've set it in the environment variable GANDI_API_KEY
```

### Examples

#### List renewal dates and costs for all domains

```ruby
# For each domain (sorted by assending renewal date) print <date>\t<cost>\t<fqdn>
GandiV5::Domain.list.each do |domain|
  puts [
    domain.dates.registry_ends_at.to_date,
    "£#{domain.renewal_price.price_after_taxes}",
    domain.fqdn
  ].join("\t")
end
```

#### List email addresses for all domains

```ruby
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
```

#### Domains

```ruby
# Get an array of all your domains.
domains = GandiV5.domains

# Since each domain has only basic information, lets get all of the information.
domains.map!(&:refresh)
```

## Versioning

We follow the [Semantic Versioning](http://semver.org/) concept.

| Gem Version     | Gandi API Release Date   |
| --------------- | ------------------------ |
| 0.10.0          | 2020-12-10               |
| 0.9.0           | 2020-07-29               |
| 0.8.0           | 2020-07-10               |
| 0.7.0           | 2020-05-07               |
| 0.6.0           | 2020-05-07 (not LiveDNS) |
| 0.5.0           | 2019-10-01               |
| 0.4.0           | 2019-10-01               |
| 0.3.0           | 2019-08-22               |
| 0.2.0           | 2019-05-16               |
| 0.1.0           | 2019-05-16               |

See <https://api.gandi.net/docs/reference#API-Changelog> to find out what
Gandi changed on each date.
