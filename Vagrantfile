Vagrant.configure(2) do |config|

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

  #config.vm.define "centos7" do |centos7|
  #  centos7.vm.box = "bento/centos-7"
  #  centos7.vm.network :private_network, ip: "192.168.33.99"
  #  centos7.vm.hostname = "centos7.local"
  #  # vhost用にドメインを複数記載 host_varsのvhostを複数記載する場合など
  #  #centos7.hostmanager.aliases = %w(cms.example.com stg.example.com)
  #  centos7.vm.boot_timeout = 1200
  #end

  #config.vm.define "centos8" do |centos8|
  #  centos8.vm.box = "bento/centos-8"
  #  centos8.vm.network :private_network, ip: "192.168.33.100"
  #  centos8.vm.hostname = "centos8.local"
  #  # vhost用にドメインを複数記載 host_varsのvhostを複数記載する場合など
  #  #centos8.hostmanager.aliases = %w(cms.example.com stg.example.com)
  #  centos8.vm.boot_timeout = 1200
  #end

  config.vm.define "amzn2" do |amzn2|
    amzn2.vm.box = "bento/amazonlinux-2"
    amzn2.vm.network :private_network, ip: "192.168.33.101"
    amzn2.vm.hostname = "amzn2.local"
    # vhost用にドメインを複数記載 host_varsのvhostを複数記載する場合など
    #amzn2.hostmanager.aliases = %w(cms.example.com stg.example.com)
    amzn2.vm.boot_timeout = 1200
    amzn2.vm.provision "ansible" do |ansible|
      ansible.playbook = "site.yml"
      ansible.inventory_path = "local"
      ansible.limit = "all"
      ansible.host_key_checking = false
      ansible.raw_arguments = []
    end
  end
end

