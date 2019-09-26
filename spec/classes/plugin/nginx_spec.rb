require 'spec_helper'

describe 'letsencrypt::plugin::nginx' do
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
        when 'RedHat'
          facts[:operatingsystem] == 'Fedora' ? 'python3-certbot-nginx' : 'python2-certbot-nginx'
        end
      end

      context 'without required parameters' do
        it { is_expected.not_to compile }
      end

      context 'with required parameters' do
        it do
          if package_name.nil?
            is_expected.not_to compile
          else
            is_expected.to compile.with_all_deps
          end
        end

        describe 'with manage_package => true' do
          let(:params) { super().merge(manage_package: true) }

          it do
            if package_name.nil?
              is_expected.not_to compile
            else
              is_expected.to contain_class('letsencrypt::plugin::nginx').with_package_name(package_name)
              is_expected.to contain_package(package_name).with_ensure('installed')
            end
          end
        end

        describe 'with manage_package => false' do
          let(:params) { super().merge(manage_package: false, package_name: 'nginx-package') }

          it { is_expected.not_to contain_package('nginx-package') }
        end
      end
    end
  end
end
