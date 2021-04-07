require 'spec_helper'

describe 'letsencrypt::install' do
  on_supported_os.each do |os, facts|
    let(:params) { default_params.merge(additional_params) }
    let(:default_params) do
      {
        configure_epel: false,
        package_ensure: 'installed',
        manage_install: true,
        manage_dependencies: true,
        path: '/opt/letsencrypt',
        repo: 'https://github.com/certbot/certbot.git',
        version: 'v1.7.0',
        package_name: 'letsencrypt',
        vcs_dependencies: vcs_dependencies,
      }
    end
    let(:additional_params) { {} }

    context "on #{os} based operating systems" do
      let :facts do
        facts
      end
      let(:vcs_dependencies) do
        case facts[:osfamily]
        when 'Debian'
          ['git', 'python3', 'python3-venv']
        when 'RedHat', 'OpenBSD', 'FreeBSD'
          ['git', 'python3', 'python3-virtualenv']
        end
      end

      describe 'with install_method => package' do
        let(:additional_params) { { install_method: 'package' } }

        it { is_expected.to compile }

        it 'contains the correct resources' do
          is_expected.not_to contain_vcsrepo('/opt/letsencrypt')
          vcs_dependencies.each do |package|
            is_expected.not_to contain_package(package)
          end

          is_expected.to contain_package('letsencrypt').with_ensure('installed')
        end

        describe 'with package_ensure => 0.3.0-1.el7' do
          let(:additional_params) { { install_method: 'package', package_ensure: '0.3.0-1.el7' } }

          it { is_expected.to compile }
          it { is_expected.to contain_package('letsencrypt').with_ensure('0.3.0-1.el7') }
        end

        case facts[:osfamily]
        when 'RedHat'
          describe 'with configure_epel => true' do
            let(:additional_params) { { install_method: 'package', configure_epel: true } }

            it { is_expected.to compile }

            it 'contains the correct resources' do
              is_expected.to contain_class('epel')
              is_expected.to contain_package('letsencrypt').that_requires('Class[epel]')
            end
          end
        end
      end

      describe 'with install_method => vcs' do
        let(:additional_params) { { install_method: 'vcs' } }

        it { is_expected.to compile }

        it 'contains the correct resources' do
          is_expected.to contain_vcsrepo('/opt/letsencrypt').with(source: 'https://github.com/certbot/certbot.git',
                                                                  revision: 'v1.7.0')
          vcs_dependencies.each do |package|
            is_expected.to contain_package(package)
          end

          is_expected.not_to contain_package('letsencrypt')
        end

        describe 'with custom path' do
          let(:additional_params) { { install_method: 'vcs', path: '/usr/lib/letsencrypt' } }

          it { is_expected.to contain_vcsrepo('/usr/lib/letsencrypt') }
        end

        describe 'with custom repo' do
          let(:additional_params) { { install_method: 'vcs', repo: 'git://foo.com/letsencrypt.git' } }

          it { is_expected.to contain_vcsrepo('/opt/letsencrypt').with_source('git://foo.com/letsencrypt.git') }
        end

        describe 'with custom version' do
          let(:additional_params) { { install_method: 'vcs', version: 'foo' } }

          it { is_expected.to contain_vcsrepo('/opt/letsencrypt').with_revision('foo') }
        end

        describe 'with manage_dependencies set to false' do
          let(:additional_params) { { install_method: 'vcs', manage_dependencies: false } }

          it 'does not contain the dependencies' do
            vcs_dependencies.each do |package|
              is_expected.not_to contain_package(package)
            end
          end
        end
      end
    end
  end
end
