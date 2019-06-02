# frozen_string_literal: true

describe GandiV5::Email::Mailbox do
  subject do
    described_class.new fqdn: 'example.com', uuid: 'mailbox-uuid', type: :standard
  end

  let(:good_password) { 'aA111-___' }

  describe '#refresh' do
    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Email_Mailbox', 'get.yaml'))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/mailboxes/example.com/mailbox-uuid')
                                      .and_return(YAML.load_file(body_fixture))
      subject.refresh
    end

    its('address') { should eq 'address@example.com' }
    its('aliases') { should match_array %w[alias-1 alias-2] }
    its('fqdn') { should eq 'example.com' }
    its('uuid') { should eq 'mailbox-uuid' }
    its('login') { should eq 'address' }
    its('type') { should eq :standard }
    its('quota_used') { should eq 1_000_000 }
    its('responder.enabled') { should be false }
    its('responder.starts_at') { should eq Time.new(2000, 1, 1, 0, 0, 0) }
    its('responder.ends_at') { should eq Time.new(2000, 1, 2, 0, 0, 0) }
    its('responder.message') { should eq 'This is an autoresponse.' }
  end

  describe '#update' do
    let(:url) { 'https://api.gandi.net/v5/email/mailboxes/example.com/mailbox-uuid' }

    it 'Aliases' do
      expect(GandiV5).to receive(:patch).with(url, '{"aliases":["alias-1"]}')
                                        .and_return('message' => 'Confirmation message.')
      expect(subject).to receive(:refresh)
      expect(subject.update(aliases: ['alias-1'])).to eq 'Confirmation message.'
    end

    it 'Login' do
      expect(GandiV5).to receive(:patch).with(url, '{"login":"new-login"}')
                                        .and_return('message' => 'Confirmation message.')
      expect(subject).to receive(:refresh)
      expect(subject.update(login: 'new-login')).to eq 'Confirmation message.'
    end

    describe 'Password' do
      it 'Password is good' do
        expect(GandiV5).to receive(:patch).with(url, '{"password":"crypted_password"}')
                                          .and_return('message' => 'Confirmation message.')
        expect(subject).to receive(:refresh)
        expect(subject).to receive(:crypt_password).with(good_password).and_return('crypted_password')
        expect(subject.update(password: good_password)).to eq 'Confirmation message.'
      end

      it 'Password is bad' do
        expect(described_class).to receive(:check_password).with('password').and_raise(ArgumentError, 'message')
        expect { subject.update password: 'password' }.to raise_error ArgumentError, 'message'
      end
    end

    describe 'Responder' do
      before(:each) do
        expect(GandiV5).to receive(:patch).with(url, '{"responder":{"enabled":false}}')
                                          .and_return('message' => 'Confirmation message.')

        expect(subject).to receive(:refresh)
      end

      it 'Given a GandiV5::Email::Mailbox::Responder' do
        responder = double GandiV5::Email::Mailbox::Responder, to_gandi: { 'enabled' => false }
        expect(subject.update(responder: responder)).to eq 'Confirmation message.'
      end

      it 'Given a Hash' do
        responder = { enabled: false }
        expect(subject.update(responder: responder)).to eq 'Confirmation message.'
      end
    end

    it 'Given nothing' do
      expect(GandiV5).to_not receive(:patch)
      expect(subject).to_not receive(:refresh)
      expect(subject.update).to eq 'Nothing to update.'
    end
  end

  it '#delete' do
    url = 'https://api.gandi.net/v5/email/mailboxes/example.com/mailbox-uuid'
    expect(GandiV5).to receive(:delete).with(url)
                                       .and_return('message' => 'Confirmation message.')
    expect(subject.delete).to eq 'Confirmation message.'
  end

  it '#purge' do
    url = 'https://api.gandi.net/v5/email/mailboxes/example.com/mailbox-uuid/contents'
    expect(GandiV5).to receive(:delete).with(url)
                                       .and_return('message' => 'Confirmation message.')
    expect(subject.purge).to eq 'Confirmation message.'
  end

  describe '#quota' do
    it 'Free mailbox' do
      mailbox = described_class.new type: :free
      expect(mailbox.quota).to eq 3_221_225_472
    end

    it 'Standard mailbox' do
      mailbox = described_class.new type: :standard
      expect(mailbox.quota).to eq 3_221_225_472
    end

    it 'Premium mailbox' do
      mailbox = described_class.new type: :premium
      expect(mailbox.quota).to eq 53_687_091_200
    end
  end

  it '#quota_usage' do
    # Used / Quota
    mailbox = described_class.new type: :free, quota_used: 2_000_000_000
    expect(mailbox.quota_usage).to eq(0.620881716410319)
  end

  describe '#to_s' do
    it 'With no responder and no aliases' do
      mailbox = described_class.new(
        address: 'mailbox@example.com',
        type: :standard,
        quota_used: 1_000_000_000,
        responder: nil,
        aliases: []
      )
      expect(mailbox.to_s).to eq '[standard] mailbox@example.com (1000000000/3221225472 (31%))'
    end

    it 'With active responder but no aliases' do
      mailbox = described_class.new(
        address: 'mailbox@example.com',
        type: :standard,
        quota_used: 1_000_000_000,
        responder: GandiV5::Email::Mailbox::Responder.new(enabled: true),
        aliases: []
      )
      expect(mailbox.to_s).to eq '[standard] mailbox@example.com (1000000000/3221225472 (31%)) ' \
                                 'with active responder'
    end

    it 'With inactive responder but no aliases' do
      mailbox = described_class.new(
        address: 'mailbox@example.com',
        type: :standard,
        quota_used: 1_000_000_000,
        responder: GandiV5::Email::Mailbox::Responder.new(enabled: false),
        aliases: []
      )
      expect(mailbox.to_s).to eq '[standard] mailbox@example.com (1000000000/3221225472 (31%)) ' \
                                 'with inactive responder'
    end

    it 'With aliases but no responder' do
      mailbox = described_class.new(
        address: 'mailbox@example.com',
        type: :standard,
        quota_used: 1_000_000_000,
        responder: nil,
        aliases: %w[mailbox_2 mailbox_3]
      )
      expect(mailbox.to_s).to eq '[standard] mailbox@example.com (1000000000/3221225472 (31%)) ' \
                                 'aka: mailbox_2, mailbox_3'
    end

    it 'With active responder and aliases' do
      mailbox = described_class.new(
        address: 'mailbox@example.com',
        type: :standard,
        quota_used: 1_000_000_000,
        responder: GandiV5::Email::Mailbox::Responder.new(enabled: true),
        aliases: %w[mailbox_2 mailbox_3]
      )
      expect(mailbox.to_s).to eq '[standard] mailbox@example.com (1000000000/3221225472 (31%)) ' \
                                 'with active responder aka: mailbox_2, mailbox_3'
    end
  end

  describe '.create' do
    let(:url) { 'https://api.gandi.net/v5/email/mailboxes/example.com' }

    it 'No aliases and :standard type' do
      body = '{"mailbox_type":"standard","login":"login","password":"crypted_password","aliases":[]}'
      expect(GandiV5).to receive(:post).with(url, body)
                                       .and_return('message' => 'Confirmation message.')
      expect(described_class).to receive(:crypt_password).with(good_password).and_return('crypted_password')

      expect(described_class.create('example.com', 'login', good_password)).to eq 'Confirmation message.'
    end

    it 'With aliases' do
      body = '{"mailbox_type":"standard","login":"login","password":"crypted_password","aliases":["alias-1"]}'
      expect(GandiV5).to receive(:post).with(url, body)
                                       .and_return('message' => 'Confirmation message.')
      expect(described_class).to receive(:crypt_password).with(good_password).and_return('crypted_password')

      expect(described_class.create('example.com', 'login', good_password, aliases: ['alias-1']))
        .to eq 'Confirmation message.'
    end

    it 'With different type' do
      body = '{"mailbox_type":"premium","login":"login","password":"crypted_password","aliases":[]}'
      expect(GandiV5).to receive(:post).with(url, body)
                                       .and_return('message' => 'Confirmation message.')
      expect(described_class).to receive(:crypt_password).with(good_password).and_return('crypted_password')

      expect(described_class.create('example.com', 'login', good_password, type: :premium)).to eq 'Confirmation message.'
    end

    it 'Bad password' do
      expect(described_class).to receive(:check_password).with('password').and_raise(ArgumentError, 'message')
      expect { described_class.create 'example.com', 'login', 'password' }.to raise_error ArgumentError, 'message'
    end

    # TODO: pending 'Bad type'
    # TODO: pending 'No available slots'
  end

  describe '.fetch' do
    subject { described_class.fetch 'example.com', 'mailbox-uuid' }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Email_Mailbox', 'get.yaml'))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/mailboxes/example.com/mailbox-uuid')
                                      .and_return(YAML.load_file(body_fixture))
    end

    its('address') { should eq 'address@example.com' }
    its('aliases') { should match_array %w[alias-1 alias-2] }
    its('fqdn') { should eq 'example.com' }
    its('uuid') { should eq 'mailbox-uuid' }
    its('login') { should eq 'address' }
    its('type') { should eq :standard }
    its('quota_used') { should eq 1_000_000 }
    its('responder.enabled') { should be false }
    its('responder.starts_at') { should eq Time.new(2000, 1, 1, 0, 0, 0) }
    its('responder.ends_at') { should eq Time.new(2000, 1, 2, 0, 0, 0) }
    its('responder.message') { should eq 'This is an autoresponse.' }
  end

  describe '.list' do
    let(:body_fixture) do
      File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Email_Mailbox', 'list.yaml'))
    end

    describe 'With default values' do
      subject { described_class.list 'example.com' }

      before :each do
        headers = { params: { page: 1 } }
        expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/mailboxes/example.com', headers)
                                        .and_return(YAML.load_file(body_fixture))
      end

      its('count') { should eq 1 }
      its('first.address') { should eq 'address@example.com' }
      its('first.fqdn') { should eq 'example.com' }
      its('first.uuid') { should eq 'mailbox-uuid' }
      its('first.login') { should eq 'address' }
      its('first.type') { should eq :standard }
      its('first.quota_used') { should eq 1_000_000 }
    end

    it 'Keeps fetching until no more to get' do
      headers1 = { params: { page: 1, per_page: 1 } }
      headers2 = { params: { page: 2, per_page: 1 } }
      # rubocop:disable Layout/MultilineMethodCallIndentation
      # https://github.com/rubocop-hq/rubocop/issues/7088
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/mailboxes/example.com', headers1)
                                      .ordered
                                      .and_return(YAML.load_file(body_fixture))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/mailboxes/example.com', headers2)
                                      .ordered
                                      .and_return([])
      # rubocop:enable Layout/MultilineMethodCallIndentation

      expect(described_class.list('example.com', per_page: 1).count).to eq 1
    end

    it 'Given a range as page number' do
      headers1 = { params: { page: 1, per_page: 1 } }
      headers2 = { params: { page: 2, per_page: 1 } }
      # rubocop:disable Layout/MultilineMethodCallIndentation
      # https://github.com/rubocop-hq/rubocop/issues/7088
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/mailboxes/example.com', headers1)
                                      .ordered
                                      .and_return(YAML.load_file(body_fixture))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/mailboxes/example.com', headers2)
                                      .ordered
                                      .and_return([])
      # rubocop:enable Layout/MultilineMethodCallIndentation

      expect(described_class.list('example.com', page: (1..2), per_page: 1).count).to eq 1
    end

    describe 'Passes optional query params' do
      {
        login: '~login',
        sort_by: :sort_by
      }.each do |param, query_param|
        it param.to_s do
          headers = { params: { page: 1 }.merge(query_param => 'value') }
          expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/mailboxes/example.com', headers)
                                          .and_return([])
          expect(described_class.list('example.com', param => 'value')).to eq []
        end
      end
    end
  end

  describe '.check_password' do
    it 'Too short' do
      expect { described_class.send :check_password, 'a' * 8 }.to raise_error ArgumentError,
                                                                              'password must be between ' \
                                                                              '9 and 200 characters'
    end

    it 'Too long' do
      expect { described_class.send :check_password, 'a' * 201 }.to raise_error ArgumentError,
                                                                                'password must be between ' \
                                                                                '9 and 200 characters'
    end

    it 'At least 1 upper case' do
      expect { described_class.send :check_password, 'a1!' * 3 }.to raise_error ArgumentError,
                                                                                'password must contain at least ' \
                                                                                'one upper case character'
    end

    it 'At least 3 numbers' do
      expect { described_class.send :check_password, 'aA!' * 3 }.to raise_error ArgumentError,
                                                                                'password must contain at least ' \
                                                                                'three numbers'
    end

    it 'At least 1 special character' do
      expect { described_class.send :check_password, 'aA1' * 3 }.to raise_error ArgumentError,
                                                                                'password must contain at least ' \
                                                                                'one special character'
    end

    it 'Is a \'good\' password' do
      expect { described_class.send :check_password, good_password }.to_not raise_error
    end

    it 'Is delegated to by #check_password' do
      returns = double NilClass
      expect(described_class).to receive(:check_password).with('password').and_return(returns)
      expect(subject.send(:check_password, 'password')).to be returns
    end
  end

  describe '.crypt_password' do
    let(:random_number) { 2_674_341_316_769 }

    before :each do
      allow(SecureRandom).to receive(:random_number).with(36**8).and_return(random_number)
    end

    it 'For "password_1"' do
      expect(described_class.send(:crypt_password, 'password_1')).to eq '$6$y4kprqn5$HcA7fWQKZOkt2if38EmourBSgUtgQer0QEao' \
                                                                        'N/qxw/2HamYbq1.EQn0lx6q6sf6etlWhHe0PDBXZ7k1Y4VZkN/'
    end

    it 'For "password_2"' do
      expect(described_class.send(:crypt_password, 'password_2')).to eq '$6$y4kprqn5$HQbp65drFzXYwUHH.FDHsvtZ9u4EYM2sVKp4' \
                                                                        'U.w9IgStZf2OeLgP0ifYo9LKE8pr30l8MUwDtmhS8.ztK8o8p/'
    end

    it 'Is delegated to by #crypt_password' do
      returns = double NilClass
      expect(described_class).to receive(:crypt_password).with('password').and_return(returns)
      expect(subject.send(:crypt_password, 'password')).to be returns
    end
  end
end
