# frozen_string_literal: true

describe GandiV5 do
  let(:api_key) { ENV['GANDI_API_KEY'] }

  it '.domain' do
    returns = double GandiV5::Domain
    expect(GandiV5::Domain).to receive(:fetch).with('example.com').and_return(returns)
    expect(described_class.domain('example.com')).to be returns
  end

  it '.domains' do
    returns = double Array
    expect(GandiV5::Domain).to receive(:list).with(param: :value).and_return(returns)
    expect(described_class.domains(param: :value)).to be returns
  end

  it '.mailboxes' do
    returns = double Array
    expect(GandiV5::Email::Mailbox).to receive(:list).with('example.com', param: :value).and_return(returns)
    expect(described_class.mailboxes('example.com', param: :value)).to be returns
  end

  it '.mailbox_slots' do
    returns = double Array
    expect(GandiV5::Email::Slot).to receive(:list).with('example.com').and_return(returns)
    expect(described_class.mailbox_slots('example.com')).to be returns
  end

  it 'Has a version' do
    expect(defined?(GandiV5::VERSION)).to eq 'constant'
    expect(GandiV5::VERSION).to_not be_empty
  end

  describe 'Attributes' do
    describe 'api_key' do
      it '.api_key=' do
        described_class.api_key = '1a'
        expect(described_class.send(:api_key)).to eq '1a'
        described_class.api_key = api_key
      end

      it 'is write only' do
        expect { described_class.api_key }.to raise_error NoMethodError
      end
    end
  end

  describe 'Uses RestClient' do
    let(:response) do
      double RestClient::Response, body: 'Hello world!', headers: { content_type: 'text/plain' }
    end

    %i[get delete].each do |method|
      describe ":#{method}" do
        it 'As JSON' do
          response_data = { 'hello' => 'world' }
          response = double RestClient::Response, body: response_data.to_json, headers: { content_type: 'application/json' }
          expect(described_class).to receive(:prepare_headers)
          expect(RestClient).to receive(method).with('url', hash_including(accept: 'application/json'))
                                               .and_return(response)
          expect(described_class.send(method, 'url', accept: 'application/json'))
            .to match_array [response, response_data]
        end

        it 'As text' do
          expect(described_class).to receive(:prepare_headers)
          expect(RestClient).to receive(method).with('url', hash_including(accept: 'text/plain')).and_return(response)
          expect(described_class.send(method, 'url', accept: 'text/plain')).to match_array [response, 'Hello world!']
        end

        it 'Passes request headers' do
          expect(described_class).to receive(:prepare_headers)
          expect(described_class).to receive(:parse_response)
          expect(RestClient).to receive(method).with(anything, header: 'value').and_return(response)
          expect(described_class.send(method, 'url', header: 'value')).to match_array [response, nil]
        end

        it 'Adds authentication header' do
          expect(RestClient).to receive(method).with(anything, hash_including(authorization: 'Apikey abdce12345'))
                                               .and_return(response)
          expect(described_class).to receive(:parse_response)
          expect(described_class.send(method, 'https://api.gandi.net/v5/')).to match_array [response, nil]
        end

        it 'Default accept header' do
          expect(RestClient).to receive(method).with(any_args, hash_including(accept: 'application/json'))
                                               .and_return(response)
          expect(described_class).to receive(:parse_response)
          expect(described_class.send(method, 'https://api.gandi.net/v5/')).to match_array [response, nil]
        end

        it 'Converts a 406 (bad request) exception' do
          expect(RestClient).to receive(method).and_raise(RestClient::BadRequest)
          expect(described_class).to receive(:handle_bad_request)
          described_class.send(method, 'https://api.gandi.net/v5/')
        end
      end
    end

    it ':delete handles no content-type' do
      response = double RestClient::Response, headers: {}
      expect(described_class).to receive(:prepare_headers)
      expect(RestClient).to receive(:delete).with('url', hash_including(accept: 'text/plain')).and_return(response)
      expect(described_class.delete('url', accept: 'text/plain')).to match_array [response, nil]
    end

    %i[patch post put].each do |method|
      describe ":#{method}" do
        let(:payload) { '{"say":"hello world"}' }

        it 'As JSON' do
          response_data = { 'said' => 'hello world' }
          response = double RestClient::Response, body: response_data.to_json, headers: { content_type: 'application/json' }
          expect(described_class).to receive(:prepare_headers)
          expect(RestClient).to receive(method).with('url', payload, hash_including(accept: 'application/json'))
                                               .and_return(response)
          expect(described_class.send(method, 'url', payload, accept: 'application/json'))
            .to match_array [response, response_data]
        end

        it 'As text' do
          expect(described_class).to receive(:prepare_headers)
          expect(RestClient).to receive(method).with('url', payload, hash_including(accept: 'text/plain'))
                                               .and_return(response)
          array = [response, 'Hello world!']
          expect(described_class.send(method, 'url', payload, accept: 'text/plain')).to match_array array
        end

        it 'Passes payload' do
          expect(described_class).to receive(:prepare_headers)
          expect(described_class).to receive(:parse_response)
          expect(RestClient).to receive(method).with(anything, payload, any_args).and_return(response)
          expect(described_class.send(method, 'url', payload)).to match_array [response, nil]
        end

        it 'Passes request headers' do
          expect(described_class).to receive(:prepare_headers)
          expect(described_class).to receive(:parse_response)
          expect(RestClient).to receive(method).with(any_args, hash_including(header: 'value')).and_return(response)
          expect(described_class.send(method, 'url', payload, header: 'value')).to match_array [response, nil]
        end

        it 'Adds content type header' do
          expect(RestClient).to receive(method).with(any_args, hash_including('content-type': 'application/json'))
          expect(described_class).to receive(:parse_response)
          expect(described_class.send(method, 'https://api.gandi.net/v5/', payload)).to match_array [nil, nil]
        end

        it 'Adds authentication header' do
          expect(RestClient).to receive(method).with(any_args, hash_including(authorization: 'Apikey abdce12345'))
                                               .and_return(response)
          expect(described_class).to receive(:parse_response)
          expect(described_class.send(method, 'https://api.gandi.net/v5/', payload)).to match_array [response, nil]
        end

        it 'Default accept header' do
          expect(RestClient).to receive(method).with(any_args, hash_including(accept: 'application/json'))
                                               .and_return(response)
          expect(described_class).to receive(:parse_response)
          expect(described_class.send(method, 'https://api.gandi.net/v5/', payload)).to match_array [response, nil]
        end

        it 'Converts a 406 (bad request) exception' do
          expect(RestClient).to receive(method).and_raise(RestClient::BadRequest)
          expect(described_class).to receive(:handle_bad_request)
          described_class.send(method, 'https://api.gandi.net/v5/', payload)
        end
      end
    end
  end

  describe 'Prepares headers' do
    it 'Sets accept it not present' do
      headers = {}
      described_class.send(:prepare_headers, headers, GandiV5::BASE)
      expect(headers[:accept]).to eq 'application/json'
    end

    it 'Leaves accept alone if present' do
      headers = { accept: 'leave/alone' }
      described_class.send(:prepare_headers, headers, GandiV5::BASE)
      expect(headers[:accept]).to eq 'leave/alone'
    end

    it 'Sets authorization' do
      headers = {}
      described_class.send(:prepare_headers, headers, GandiV5::BASE)
      expect(headers[:authorization]).to eq "Apikey #{api_key}"
    end
  end

  describe 'Parses response' do
    it 'Text' do
      response = double RestClient::Response, body: 'Hello World', headers: { content_type: 'text/plain' }
      expect(described_class.send(:parse_response, response)).to eq 'Hello World'
    end

    describe 'JSON' do
      it 'Response is parsable' do
        response = double RestClient::Response, body: '{"hello":"world"}', headers: { content_type: 'application/json' }
        expect(described_class.send(:parse_response, response)).to eq('hello' => 'world')
      end

      it 'Response is an error message' do
        response = double RestClient::Response, body: '{"status":"error"}', headers: { content_type: 'application/json' }
        expect { described_class.send(:parse_response, response) }.to raise_error GandiV5::Error::GandiError
      end
    end

    it 'Raises ArgumentError when requesting an unknown parser' do
      response = double RestClient::Response, headers: { content_type: 'unknown/unknown' }
      expect { described_class.send(:parse_response, response) }
        .to raise_error ArgumentError, 'Don\'t know how to parse a unknown/unknown response'
    end
  end

  describe 'Handles HTTP error 406 (Bad Request)' do
    it 'Passes on exception if body is not JSON' do
      response = double RestClient::Response,
                        code: '406',
                        body: 'Something went wrong!'
      exception = RestClient::BadRequest.new response
      expect { described_class.send(:handle_bad_request, exception) }
        .to raise_error exception
    end

    it 'Passes on exception if body is JSON but not an error hash' do
      response = double RestClient::Response,
                        code: '406',
                        body: '{"status":"not error"}'
      exception = RestClient::BadRequest.new response
      expect { described_class.send(:handle_bad_request, exception) }
        .to raise_error RestClient::BadRequest
    end

    it 'Raises GandiV5::Error::GandiError if response is an error hash' do
      response = double RestClient::Response,
                        code: '406',
                        body: '{"status":"error","errors":[{"name":"field","description":"message"}]}'
      exception = RestClient::BadRequest.new response
      expect { described_class.send(:handle_bad_request, exception) }
        .to raise_error GandiV5::Error::GandiError, 'field: message'
    end
  end

  describe '.paginated_get' do
    let(:url) { "#{GandiV5::BASE}test/url" }
    let(:do_nothing) { ->(_this_data) { nil } }

    it 'Keeps fetching until getting a partial list' do
      headers1 = { params: { 'page' => 1, 'per_page' => 2 } }
      headers2 = { params: { 'page' => 2, 'per_page' => 2 } }
      expect(GandiV5).to receive(:get).with(url, headers1)
                                      .ordered
                                      .and_return([nil, %i[a b]])
      expect(GandiV5).to receive(:get).with(url, headers2)
                                      .ordered
                                      .and_return([nil, %i[c]])

      described_class.paginated_get(url, (1..2), 2, &do_nothing)
    end

    it 'Keeps fetching until getting an empty list' do
      headers1 = { params: { 'page' => 1, 'per_page' => 2 } }
      headers2 = { params: { 'page' => 2, 'per_page' => 2 } }
      expect(GandiV5).to receive(:get).with(url, headers1)
                                      .ordered
                                      .and_return([nil, %i[a b]])
      expect(GandiV5).to receive(:get).with(url, headers2)
                                      .ordered
                                      .and_return([nil, []])

      described_class.paginated_get(url, (1..2), 2, &do_nothing)
    end

    it 'Passes per_page option' do
      headers = { params: { 'page' => 1, 'per_page' => 100 } }
      expect(GandiV5).to receive(:get).with(url, headers)
                                      .and_return([nil, []])
      described_class.paginated_get(url, 1, 100, &do_nothing)
    end

    it 'Passes on other params' do
      headers = { params: { 'page' => 1, 'per_page' => 100, 'custom' => 'value' } }
      expect(GandiV5).to receive(:get).with(url, headers)
                                      .and_return([nil, []])
      described_class.paginated_get(url, 1, 100, params: { custom: 'value' }, &do_nothing)
    end

    it 'Passes on other headers' do
      headers = { params: { 'page' => 1, 'per_page' => 100 }, custom: :value }
      expect(GandiV5).to receive(:get).with(url, headers)
                                      .and_return([nil, []])
      described_class.paginated_get(url, 1, 100, custom: :value, &do_nothing)
    end

    describe 'Honors passed pages' do
      it 'Has an each method' do
        headers1 = { params: { 'page' => 1, 'per_page' => 2 } }
        headers2 = { params: { 'page' => 2, 'per_page' => 2 } }
        expect(GandiV5).to receive(:get).with(url, headers1)
                                        .ordered
                                        .and_return([nil, %i[a b]])
        expect(GandiV5).to receive(:get).with(url, headers2)
                                        .ordered
                                        .and_return([nil, %i[c d]])

        described_class.paginated_get(url, (1..2), 2, &do_nothing)
      end

      it 'Positive integer' do
        headers = { params: { 'page' => 3, 'per_page' => 2 } }
        expect(GandiV5).to receive(:get).with(url, headers)
                                        .ordered
                                        .and_return([nil, %i[a b c]])
        described_class.paginated_get(url, 3, 2, &do_nothing)
      end

      it 'Nonpositive integer' do
        expect { described_class.paginated_get(url, -3, 2, &do_nothing) }.to \
          raise_error ArgumentError, 'page must be positive'
      end
    end

    it 'Relies on caller to build their list' do
      this_data = [:a]
      expect(GandiV5).to receive(:get).and_return([nil, this_data])
      expect { |b| described_class.paginated_get(url, 1, 100, &b) }.to yield_with_args(this_data)
    end

    it 'Requires a block' do
      allow(GandiV5).to receive(:get).and_return([nil, [:a]])

      expect { described_class.paginated_get(url) }.to raise_error LocalJumpError
    end
  end
end
