require 'spec_helper'

describe 'redis::default' do
  context 'When all attributes are default, on CentOS 7.4.1708' do
    let(:chef_run) do
      # for a complete list of available platforms and versions see:
      # https://github.com/customink/fauxhai/blob/master/PLATFORMS.md
      runner = ChefSpec::ServerRunner.new(platform: 'centos', version: '7.4.1708')
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs the epel-release package' do
      expect(chef_run).to install_package('epel-release')
    end

    it 'installs the redis package' do
      expect(chef_run).to install_package('redis')
    end

    it 'starts the redis service' do
      expect(chef_run).to start_service('redis')
      expect(chef_run).to enable_service('redis')
    end
  end
end
