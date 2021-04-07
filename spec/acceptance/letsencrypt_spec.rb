require 'spec_helper_acceptance'

describe 'letsencrypt' do
  context 'with defaults values' do
    pp = %(
      class { 'letsencrypt' :
        email  => 'letsregister@example.com',
        config => {
          'server' => 'https://acme-staging-v02.api.letsencrypt.org/directory',
        },
      }
    )

    it 'installs letsencrypt without error' do
      apply_manifest(pp, catch_failures: true)
    end
    it 'installs letsencrypt idempotently' do
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/letsencrypt/cli.ini') do
      it { is_expected.to be_file }
      it { is_expected.to be_owned_by 'root' }
      it { is_expected.to be_grouped_into 'root' }
      it { is_expected.to be_mode 644 }
      its(:content) { is_expected.to match %r{server = https://acme-staging-v02.api.letsencrypt.org/directory} }
      its(:content) { is_expected.to match %r{email = letsregister@example.com} }
    end
  end

  context 'with install_method => vcs' do
    pp = %(
      class { 'letsencrypt' :
        install_method => 'vcs',
        email          => 'letsregister@example.com',
        config         => {
          'server' => 'https://acme-staging-v02.api.letsencrypt.org/directory',
        },
      }
    )

    it 'installs letsencrypt without error' do
      apply_manifest(pp, catch_failures: true)
    end
    it 'installs letsencrypt idempotently' do
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/letsencrypt/cli.ini') do
      it { is_expected.to be_file }
      it { is_expected.to be_owned_by 'root' }
      it { is_expected.to be_grouped_into 'root' }
      it { is_expected.to be_mode 644 }
      its(:content) { is_expected.to match %r{server = https://acme-staging-v02.api.letsencrypt.org/directory} }
      its(:content) { is_expected.to match %r{email = letsregister@example.com} }
    end

    describe file('/opt/letsencrypt/venv3/bin/certbot') do
      it { is_expected.to be_file }
      it { is_expected.to be_owned_by 'root' }
      it { is_expected.to be_grouped_into 'root' }
      it { is_expected.to be_mode 755 }
    end
  end
end
