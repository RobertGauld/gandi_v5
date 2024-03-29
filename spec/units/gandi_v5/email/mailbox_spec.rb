# frozen_string_literal: true

describe GandiV5::Email::Mailbox do
  subject do
    described_class.new fqdn: 'example.com', uuid: 'mailbox-uuid', type: :standard
  end

  let(:good_password) { 'aA111-___' }

  describe '#refresh' do
    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Email_Mailbox', 'fetch.yml'))
      if RUBY_VERSION >= '3.1.0'
        expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/mailboxes/example.com/mailbox-uuid')
                                        .and_return([nil, YAML.load_file(body_fixture, permitted_classes: [Time])])
      else
        expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/mailboxes/example.com/mailbox-uuid')
                                        .and_return([nil, YAML.load_file(body_fixture)])
      end
      subject.refresh
    end

    its('address') { should eq 'address@example.com' }
    its('aliases') { should match_array %w[alias-1 alias-2] }
    its('fqdn') { should eq 'example.com' }
    its('uuid') { should eq 'mailbox-uuid' }
    its('login') { should eq 'address' }
    its('type') { should eq :standard }
    its('quota_used') { should eq 1_000_000 }
    its('responder.mailbox') { should be subject }
    its('responder.enabled') { should be false }
    its('responder.starts_at') { should eq Time.new(2000, 1, 1, 0, 0, 0) }
    its('responder.ends_at') { should eq Time.new(2000, 1, 2, 0, 0, 0) }
    its('responder.message') { should eq 'This is an autoresponse.' }
  end

  describe '#update' do
    let(:url) { 'https://api.gandi.net/v5/email/mailboxes/example.com/mailbox-uuid' }

    it 'Aliases' do
      expect(GandiV5).to receive(:patch).with(url, '{"aliases":["alias-1"]}')
                                        .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject).to receive(:refresh)
      expect(subject.update(aliases: ['alias-1'])).to eq 'Confirmation message.'
    end

    it 'Login' do
      expect(GandiV5).to receive(:patch).with(url, '{"login":"new-login"}')
                                        .and_return([nil, { 'message' => 'Confirmation message.' }])
      expect(subject).to receive(:refresh)
      expect(subject.update(login: 'new-login')).to eq 'Confirmation message.'
    end

    describe 'Password' do
      it 'Password is good' do
        expect(GandiV5).to receive(:patch).with(url, '{"password":"crypted_password"}')
                                          .and_return([nil, { 'message' => 'Confirmation message.' }])
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
                                          .and_return([nil, { 'message' => 'Confirmation message.' }])

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

  describe '#upgrade' do
    let(:url) { 'https://api.gandi.net/v5/email/mailboxes/example.com/mailbox-uuid/type' }

    context 'No sharing_id' do
      it 'Is upgraded' do
        expect(GandiV5).to receive(:patch).with(url, '{"mailbox_type":"premium"}', 'Dry-Run': 0)
                                          .and_return([nil, { 'message' => 'Confirmation message.' }])
        expect(subject.upgrade).to be true
        expect(subject.type).to be :premium
      end

      it 'Is already premium' do
        subject.instance_exec { @type = :premium }
        expect(GandiV5).to_not receive(:patch)
        expect(subject.upgrade).to be false
      end
    end

    context 'With sharing_id' do
      let(:url) { 'https://api.gandi.net/v5/email/mailboxes/example.com/mailbox-uuid/type?sharing_id=abc' }

      it 'Is upgraded' do
        expect(GandiV5).to receive(:patch).with(url, '{"mailbox_type":"premium"}', 'Dry-Run': 0)
                                          .and_return([nil, { 'message' => 'Confirmation message.' }])
        expect(subject.upgrade(sharing_id: 'abc')).to be true
        expect(subject.type).to be :premium
      end

      it 'Is already premium' do
        subject.instance_exec { @type = :premium }
        expect(GandiV5).to_not receive(:patch)
        expect(subject.upgrade(sharing_id: 'abc')).to be false
      end
    end

    context 'Dry run' do
      it 'Is upgraded' do
        expect(GandiV5).to receive(:patch).with(url, '{"mailbox_type":"premium"}', 'Dry-Run': 1)
                                          .and_return([nil, { 'status' => 'success' }])
        expect(subject.upgrade(dry_run: true)).to eq('status' => 'success')
        expect(subject.type).to be :standard
      end

      it 'Is already premium' do
        subject.instance_exec { @type = :premium }
        expect(GandiV5).to_not receive(:patch)
        expect(subject.upgrade(dry_run: true)).to be false
      end
    end
  end

  describe '#downgrade' do
    let(:url) { 'https://api.gandi.net/v5/email/mailboxes/example.com/mailbox-uuid/type' }

    context 'No sharing_id' do
      it 'Is downgraded' do
        subject.instance_exec { @type = :premium }
        expect(GandiV5).to receive(:patch).with(url, '{"mailbox_type":"standard"}', 'Dry-Run': 0)
                                          .and_return([nil, { 'message' => 'Confirmation message.' }])
        expect(subject.downgrade).to be true
        expect(subject.type).to be :standard
      end

      it 'Is already premium' do
        expect(GandiV5).to_not receive(:patch)
        expect(subject.downgrade).to be false
      end
    end

    context 'With sharing_id' do
      let(:url) { 'https://api.gandi.net/v5/email/mailboxes/example.com/mailbox-uuid/type?sharing_id=abc' }

      it 'Is downgraded' do
        subject.instance_exec { @type = :premium }
        expect(GandiV5).to receive(:patch).with(url, '{"mailbox_type":"standard"}', 'Dry-Run': 0)
                                          .and_return([nil, { 'message' => 'Confirmation message.' }])
        expect(subject.downgrade(sharing_id: 'abc')).to be true
        expect(subject.type).to be :standard
      end

      it 'Is already premium' do
        expect(GandiV5).to_not receive(:patch)
        expect(subject.downgrade(sharing_id: 'abc')).to be false
      end
    end

    context 'Dry run' do
      it 'Is downgraded' do
        subject.instance_exec { @type = :premium }
        expect(GandiV5).to receive(:patch).with(url, '{"mailbox_type":"standard"}', 'Dry-Run': 1)
                                          .and_return([nil, { 'status' => 'success' }])
        expect(subject.downgrade(dry_run: true)).to eq('status' => 'success')
        expect(subject.type).to be :premium
      end

      it 'Is already premium' do
        expect(GandiV5).to_not receive(:patch)
        expect(subject.downgrade(dry_run: true)).to be false
      end
    end
  end

  it '#delete' do
    url = 'https://api.gandi.net/v5/email/mailboxes/example.com/mailbox-uuid'
    expect(GandiV5).to receive(:delete).with(url)
                                       .and_return([nil, { 'message' => 'Confirmation message.' }])
    expect(subject.delete).to eq 'Confirmation message.'
  end

  it '#purge' do
    url = 'https://api.gandi.net/v5/email/mailboxes/example.com/mailbox-uuid/contents'
    expect(GandiV5).to receive(:delete).with(url)
                                       .and_return([nil, { 'message' => 'Confirmation message.' }])
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
    let(:created_response) do
      double(
        RestClient::Response,
        headers: { location: 'https://api.gandi.net/v5/email/mailboxes/example.com/created-mailbox-uuid' }
      )
    end
    let(:created_mailbox) { double GandiV5::Email::Mailbox }

    before :each do
      allow(GandiV5::Email::Slot).to receive(:list).and_return [
        GandiV5::Email::Slot.new(mailbox_type: :standard, status: :inactive),
        GandiV5::Email::Slot.new(mailbox_type: :premium, status: :inactive)
      ]
    end

    it 'No aliases and :standard type' do
      body = '{"mailbox_type":"standard","login":"login","password":"crypted_password","aliases":[]}'
      expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0)
                                       .and_return([created_response, { 'message' => 'Confirmation message.' }])
      expect(described_class).to receive(:crypt_password).with(good_password).and_return('crypted_password')
      expect(described_class).to receive(:fetch).with('example.com', 'created-mailbox-uuid').and_return(created_mailbox)

      expect(described_class.create('example.com', 'login', good_password)).to be created_mailbox
    end

    it 'With aliases' do
      body = '{"mailbox_type":"standard","login":"login","password":"crypted_password","aliases":["alias-1"]}'
      expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0)
                                       .and_return([created_response, { 'message' => 'Confirmation message.' }])
      expect(described_class).to receive(:crypt_password).with(good_password).and_return('crypted_password')
      expect(described_class).to receive(:fetch).with('example.com', 'created-mailbox-uuid').and_return(created_mailbox)

      expect(described_class.create('example.com', 'login', good_password, aliases: ['alias-1'])).to be created_mailbox
    end

    it 'With different type' do
      body = '{"mailbox_type":"premium","login":"login","password":"crypted_password","aliases":[]}'
      expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 0)
                                       .and_return([created_response, { 'message' => 'Confirmation message.' }])
      expect(described_class).to receive(:crypt_password).with(good_password).and_return('crypted_password')
      expect(described_class).to receive(:fetch).with('example.com', 'created-mailbox-uuid').and_return(created_mailbox)

      expect(described_class.create('example.com', 'login', good_password, type: :premium)).to be created_mailbox
    end

    it 'Bad password' do
      expect(described_class).to receive(:check_password).with('password').and_raise(ArgumentError, 'message')
      expect { described_class.create 'example.com', 'login', 'password' }.to raise_error ArgumentError, 'message'
    end

    it 'Bad type' do
      expect { described_class.create 'example.com', 'login', good_password, type: :invalid }.to raise_error(
        ArgumentError,
        ':invalid is not a valid type'
      )
    end

    it 'No free slot' do
      expect(GandiV5::Email::Slot).to receive(:list).and_return [
        GandiV5::Email::Slot.new(mailbox_type: :standard, status: :active),
        GandiV5::Email::Slot.new(mailbox_type: :premium, status: :inactive)
      ]
      expect { described_class.create 'example.com', 'login', good_password }.to raise_error(
        GandiV5::Error,
        'no available standard slots'
      )
    end

    it 'Doing a dry run' do
      body = '{"mailbox_type":"standard","login":"login","password":"crypted_password","aliases":[]}'
      expect(GandiV5).to receive(:post).with(url, body, 'Dry-Run': 1)
                                       .and_return([nil, { 'status' => 'success' }])
      expect(described_class).to receive(:crypt_password).with(good_password).and_return('crypted_password')
      expect(described_class).to_not receive(:fetch)

      expect(described_class.create('example.com', 'login', good_password, dry_run: true)).to eq('status' => 'success')
    end
  end

  describe '.fetch' do
    subject { described_class.fetch 'example.com', 'mailbox-uuid' }

    before :each do
      body_fixture = File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Email_Mailbox', 'fetch.yml'))
      expect(GandiV5).to receive(:get).with('https://api.gandi.net/v5/email/mailboxes/example.com/mailbox-uuid')
                                      .and_return([nil, YAML.load_file(body_fixture)])
    end

    its('address') { should eq 'address@example.com' }
    its('aliases') { should match_array %w[alias-1 alias-2] }
    its('fqdn') { should eq 'example.com' }
    its('uuid') { should eq 'mailbox-uuid' }
    its('login') { should eq 'address' }
    its('type') { should eq :standard }
    its('quota_used') { should eq 1_000_000 }
    its('responder.mailbox') { should be subject }
    its('responder.enabled') { should be false }
    its('responder.starts_at') { should eq Time.new(2000, 1, 1, 0, 0, 0) }
    its('responder.ends_at') { should eq Time.new(2000, 1, 2, 0, 0, 0) }
    its('responder.message') { should eq 'This is an autoresponse.' }
  end

  describe '.list' do
    let(:body_fixture) do
      File.expand_path(File.join('spec', 'fixtures', 'bodies', 'GandiV5_Email_Mailbox', 'list.yml'))
    end
    let(:url) { 'https://api.gandi.net/v5/email/mailboxes/example.com' }

    describe 'With default values' do
      subject { described_class.list 'example.com' }

      before :each do
        expect(GandiV5).to receive(:paginated_get).with(url, (1..), 100, params: {})
                                                  .and_yield(YAML.load_file(body_fixture))
      end

      its('count') { should eq 1 }
      its('first.address') { should eq 'address@example.com' }
      its('first.fqdn') { should eq 'example.com' }
      its('first.uuid') { should eq 'mailbox-uuid' }
      its('first.login') { should eq 'address' }
      its('first.type') { should eq :standard }
      its('first.quota_used') { should eq 1_000_000 }
    end

    describe 'Passes optional query params' do
      {
        login: '~login',
        sort_by: :sort_by
      }.each do |param, query_param|
        it param.to_s do
          expect(GandiV5).to receive(:paginated_get).with(url, (1..), 100, params: { query_param => 'value' })
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
