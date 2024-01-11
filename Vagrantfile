Vagrant.configure(2) do |config|

  arch = `arch`.strip()

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

  config.vm.define "rocky9" do |rocky9|
    if arch == 'x86_64'
      rocky9.vm.box = "bento/rockylinux-9.2"
    else
      rocky9.vm.box = "bento/rockylinux-9.2-arm64"
    end
    rocky9.vm.network :private_network, ip: "192.168.33.99"
    rocky9.vm.hostname = "rocky9.local"
    # vhost用にドメインを複数記載 host_varsのvhostを複数記載する場合など
    #rocky9.hostmanager.aliases = %w(cms.example.com stg.example.com)
    rocky9.vm.boot_timeout = 1200
    rocky9.vm.synced_folder '.', '/vagrant', disabled: true
    rocky9.vm.synced_folder './shared', '/mnt/vagrant'
    rocky9.vm.provision "ansible" do |ansible|
      ansible.playbook = "site.yml"
      ansible.inventory_path = "local"
      ansible.limit = "all"
      ansible.host_key_checking = false
      ansible.raw_arguments = []
    end
  end
end

