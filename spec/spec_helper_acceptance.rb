require 'beaker-rspec'
require 'beaker-puppet'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'

run_puppet_install_helper unless ENV['BEAKER_provision'] == 'no'
install_module
install_module_dependencies

RSpec.configure do |c|
  # Configure all nodes in nodeset
  c.before :suite do
    hosts.each do |host|
      # docker image does not provide cron in all cases
      case fact('os.family')
      when 'Debian'
        host.install_package('cron')
      when 'RedHat'
        host.install_package('crontabs')
      end
    end
  end
  install_module_from_forge('camptocamp-systemd', '>= 2.6.0')
end
