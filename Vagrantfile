require 'yaml'
# required_plugins = %w(vagrant-hostmanager)
required_plugins = %w(  )
VAGRANTFILE_API_VERSION = '2'

def node_val(node, config, sym)
  name = sym.to_s
  node[name] || val(config, sym)
end

def val(config, sym)
  name = sym.to_s
  ENV[name] || ENV[name.upcase] || config[name]
end

def loadConfiguration()
  config_filename = ENV['CONFIG'] || 'vagrant.yaml'
  local_config_filename = ENV['LOCAL_CONFIG'] || 'local_vagrant.yaml'
  config_file = File.join( File.dirname(__FILE__), config_filename)
  local_config_file = File.join( File.dirname(__FILE__), local_config_filename)
  local_config = File.exist?(local_config_file) ? YAML::load_file(local_config_file) : {}

  # Overload default config with local config
  config = YAML.load_file(config_file)
  config.merge(local_config)
end

# Beware this might need vagrant version >= 1.7.2
def checkForVagrantPlugins(plugins_list)
  # Install required vagrant plugins if necessary
  plugins_list.each do |plugin|
    need_restart = false
    unless Vagrant.has_plugin? plugin
      system "vagrant plugin install #{plugin}"
      need_restart = true
    end
    exec "vagrant #{ARGV.join(' ')}" if need_restart
  end
end

main_config = loadConfiguration()

# Install mandatory plugins
checkForVagrantPlugins(required_plugins)
provider = 'virtualbox'
has_provider_arg = ARGV.index {|s| s.include?('--provider')}

if ARGV.include?('--provider=libvirt') ||
  (!has_provider_arg &&
   ENV['VAGRANT_DEFAULT_PROVIDER'] == 'libvirt') ||
  (!has_provider_arg &&
   val(main_config, :provider) == 'libvirt')

  required_plugins << 'vagrant-libvirt'
  required_plugins << 'fog-libvirt'
  provider = 'libvirt'
end

if ARGV.include?('--provider=parallels') ||
  (!has_provider_arg &&
   ENV['VAGRANT_DEFAULT_PROVIDER'] == 'parallels') ||
  (!has_provider_arg &&
   val(main_config, :provider) == 'parallels')

  required_plugins << 'vagrant-parallels'
  provider = 'parallels'
end

if provider != 'virtualbox' && ARGV.include?('up')
  if not ARGV.include?('--no-parallel')
    puts "You really want the machine not to be started in parallel. Please rerun with --no-parallel argument. #{provider}"
    exit
  end
end

# Install mandatory plugins
checkForVagrantPlugins(required_plugins)


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  if Vagrant.has_plugin?('vagrant-cachier')
    config.cache.scope = :box
    config.cache.synced_folder_opts = {
      type: :nfs,
      mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
    }
  end

  if Vagrant.has_plugin?('vagrant-hostmanager')
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true
  end

  if Vagrant.has_plugin?('landrush')
    config.landrush.enabled = true
    # config.landrush.upstream '172.30.16.200'
    config.landrush.upstream '192.168.1.254'
    config.landrush.tld = "#{val(main_config, :domain)}"
  end

  config.vm.box = "#{val(main_config, :image)}"

  # Install Puppet
  config.puppet_install.puppet_version = '3.7.5'

  ## Hosts configuration
  main_config['hosts'].each_with_index do |node, index|

    autostart = node_val(node, main_config, :autostart)
    config.vm.define node['name'], autostart: autostart do |client_config|
      client_config.vm.host_name = "#{node['name']}.#{val(main_config, :domain)}"
      shell_command = []
      if provider == 'libvirt'
        client_config.vm.provider :libvirt do |os_client, override|
          override.vm.network :private_network, ip: "#{node['ip']}",
            :libvirt__network_name => 'private_network'
          os_client.memory = node_val(node, main_config, :memory)
          os_client.cpus = node_val(node, main_config, :cpu)
        end
      end
      if provider == 'parallels'
        client_config.vm.provider :parallels do |os_client, override|
          # Create a private network, which allows host-only access to the machine
          # using a specific IP.
          override.vm.network :private_network, ip: "#{node['ip']}"
          os_client.memory = node_val(node, main_config, :memory)
          os_client.cpus = node_val(node, main_config, :cpu)
        end
      end
      if provider == 'virtualbox'
        client_config.vm.provider :virtualbox do |os_client, override|
          # Create a private network, which allows host-only access to the machine
          # using a specific IP.
          override.vm.network :private_network, ip: "#{node['ip']}"
          os_client.customize ['modifyvm', :id, '--memory', node_val(node, main_config, :memory)]
          os_client.customize ['modifyvm', :id, '--cpus', node_val(node, main_config, :cpu)]
        end
      end

      client_config.vm.provision :shell do |shell|
        shell.inline = shell_command.join(';')
      end

      client_config.vm.synced_folder "hieradata/", "/tmp/vagrant-hiera/"
      client_config.vm.provision :puppet do |pp_masterless|
        pp_masterless.manifest_file = "nodes.pp"
        pp_masterless.hiera_config_path = "hiera.yaml"
        pp_masterless.working_directory = "/tmp/vagrant-puppet"
        pp_masterless.module_path = ["modules","sitemodules"]
        pp_masterless.synced_folder_type = 'nfs'
        pp_masterless.options = "--yamldir /hieradata --verbose --debug"
      end
    end
  end
end
