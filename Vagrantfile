Vagrant.configure(2) do |config|
  config.vm.box = "bento/centos-7.3"
  config.vm.hostname = "vagrant-movabletype"
  config.vm.network "private_network", ip: "192.168.33.99"
  config.vm.synced_folder "./shared", "/var/www/"
  config.vm.boot_timeout = 1200

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "site.yml"
    ansible.inventory_path = "local"
    ansible.sudo = "yes"
    ansible.limit = "all"
    ansible.raw_arguments = [
      "-s"
    ]
  end
end
