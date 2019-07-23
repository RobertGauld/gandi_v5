[![Gem Version](https://badge.fury.io/rb/gandi_v5.png)](http://badge.fury.io/rb/gandi_v5)
[![Build Status](https://secure.travis-ci.org/robertgauld/gandi_v5.png?branch=master)](http://travis-ci.org/robertgauld/gandi_v5)
[![Coveralls Status](https://coveralls.io/repos/robertgauld/gandi_v5/badge.png?branch=master)](https://coveralls.io/r/robertgauld/gandi_v5)
[![Code Climate](https://codeclimate.com/github/robertgauld/gandi_v5.png?branch=master)](https://codeclimate.com/github/robertgauld/gandi_v5)


## Ruby Versions
This gem supports the following versions of ruby, it may work on other versions but is not tested against them so don't rely on it.

* ruby:
  * 2.6.0 - 2.6.3
* jruby, once it's reached parity with ruby 2.6.x


## Gandi V5

Make use of Gandi's V5 API.
See the table in the [Versioning section](#Versioning) to see what Gandi
API Changes each version is current for.

Gandi say: **_"Please note that this API is currently in BETA testing, so care should be taken when used in production._"**

But then you were going to be careful anyway as this gem is currently in the version 0.something range weren't you!

Details of the API can be found at:

* <https://api.gandi.net/docs/>
* <https://doc.livedns.gandi.net/>


## Installation

If you're using bundler then add it to your Gemfile and run the bundle command.

```ruby
gem 'gandi_v5', '~> 0.1'
```

If you're not using bundler then install it from the command line.
```bash
gem install gandi_v5 -v '~> 0.1'
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

#### Domains

```ruby
# Get an array of all your domains.
domains = GandiV5.domains

# Since each domain has only basic information, lets get all of the information.
domains.map!(&:refresh)
```

TODO: More examples!


## Versioning

We follow the [Semantic Versioning](http://semver.org/) concept.

| Gem Version     | Gandi API Release Date | 
| --------------- | ---------------------- |
| 0.2.0           | 2019-05-16             |
| 0.1.0           | 2019-05-16             |

See <https://api.gandi.net/docs/reference#API-Changelog> to find out what
Gandi changed on each date.
