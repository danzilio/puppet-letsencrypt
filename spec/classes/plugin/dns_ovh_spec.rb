require 'spec_helper'

describe 'letsencrypt::plugin::dns_ovh' do
  on_supported_os.each do |os, facts|
    context "on #{os} based operating systems" do
      let(:facts) { facts }
      let(:params) { {} }
      let(:pre_condition) do
        <<-PUPPET
        class { 'letsencrypt':
          email => 'foo@example.com',
        }
        PUPPET
      end
      let(:package_name) do
        case facts[:osfamily]
        when 'Debian'
          'python3-certbot-dns-ovh'
        when 'RedHat'
          facts[:operatingsystem] == 'Fedora' ? 'python3-certbot-dns-ovh' : 'python2-certbot-dns-ovh'
        end
      end

      context 'without required parameters' do
        it { is_expected.not_to compile }
      end

      context 'with required parameters' do
        let(:params) do
          super().merge(
            endpoint: 'ovh-eu',
            application_key: 'MDAwMDAwMDAwMDAw',
            application_secret: 'MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAw',
            consumer_key: 'MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAw'
          )
        end

        it do
          if package_name.nil?
            is_expected.not_to compile
          else
            is_expected.to compile.with_all_deps

            is_expected.to contain_file('/etc/letsencrypt/dns-ovh.ini').
              with_ensure('file').
              with_owner('root').
              with_group('root').
              with_mode('0400').
              with_content(%r{^.*dns_ovh_endpoint.*$})
          end
        end

        describe 'with manage_package => true' do
          let(:params) { super().merge(manage_package: true) }

          it do
            if package_name.nil?
              is_expected.not_to compile
            else
              is_expected.to contain_class('letsencrypt::plugin::dns_ovh').with_package_name(package_name)
              is_expected.to contain_package(package_name).with_ensure('installed')
            end
          end
        end

        describe 'with manage_package => false' do
          let(:params) { super().merge(manage_package: false, package_name: 'dns-ovh-package') }

          it { is_expected.not_to contain_package('dns-ovh-package') }
        end
      end
    end
  end
end
