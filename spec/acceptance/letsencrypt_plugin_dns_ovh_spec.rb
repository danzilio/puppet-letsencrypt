require 'spec_helper_acceptance'

describe 'letsencrypt::plugin::dns_ovh' do
  supported = case fact('os.family')
              when 'Debian'
                # Debian started shipping in Buster, Ubuntu started shipping in Disco
                fact('os.release.major') != '10' && fact('os.release.major') != '19.04'
              when 'RedHat'
                true
              else
                false
              end

  context 'with defaults values' do
    pp = <<-PUPPET
      class { 'letsencrypt' :
        email  => 'letsregister@example.com',
        config => {
          'server' => 'https://acme-staging.api.letsencrypt.org/directory',
        },
      }
      class { 'letsencrypt::plugin::dns_ovh':
        endpoint           => 'ovh-eu',
        application_key    => 'MDAwMDAwMDAwMDAw',
        application_secret => 'MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAw',
        consumer_key       => 'MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAw',
      }
    PUPPET

    if supported
      it 'installs letsencrypt and dns ovh plugin without error' do
        apply_manifest(pp, catch_failures: true)
      end
      it 'installs letsencrypt and dns ovh idempotently' do
        apply_manifest(pp, catch_changes: true)
      end

      describe file('/etc/letsencrypt/dns-ovh.ini') do
        it { is_expected.to be_file }
        it { is_expected.to be_owned_by 'root' }
        it { is_expected.to be_grouped_into 'root' }
        it { is_expected.to be_mode 400 }
      end
    else
      it 'fails to install' do
        apply_manifest(pp, expect_failures: true)
      end
    end
  end
end
