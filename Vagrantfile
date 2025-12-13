# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Base Box: Ubuntu 22.04 LTS (Jammy Jellyfish)
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = ">= 0"

  # VM 基本設定
  config.vm.hostname = "graphqllab-dev"

  # 網路配置
  # Private Network: Host-Only 模式，用於開發環境
  config.vm.network "private_network", ip: "192.168.56.10"

  # Port Forwarding: 將 VM 服務暴露到 Windows Host
  # Docker 相關服務
  config.vm.network "forwarded_port", guest: 8080, host: 8080, host_ip: "127.0.0.1"  # Go API (DEV)
  config.vm.network "forwarded_port", guest: 8081, host: 8081, host_ip: "127.0.0.1"  # Go API (SIT)
  config.vm.network "forwarded_port", guest: 3306, host: 3306, host_ip: "127.0.0.1"  # MySQL
  config.vm.network "forwarded_port", guest: 2375, host: 2375, host_ip: "127.0.0.1"  # Docker Daemon (可選)

  # 同步資料夾配置
  # 注意: Hyper-V 預設使用 SMB，Windows 需要啟用 SMB 功能
  # 方案 1: 同步專案目錄 (開發用，可能較慢)
  config.vm.synced_folder ".", "/vagrant", disabled: false

  # 方案 2: 建議在 VM 內用 Git Clone (生產環境模擬)
  # config.vm.synced_folder ".", "/vagrant", disabled: true

  # Hyper-V Provider 配置
  config.vm.provider "hyperv" do |h|
    # VM 名稱
    h.vmname = "GraphQLLab-DevVM"

    # 記憶體配置: 2GB
    h.memory = 2048

    # CPU 核心數
    h.cpus = 2

    # 啟用動態記憶體 (Hyper-V 特性)
    h.enable_virtualization_extensions = true
    h.linked_clone = true

    # 自動啟動與停止時間設定
    h.auto_start_action = "Nothing"
    h.auto_stop_action = "ShutDown"
  end

  # VirtualBox Provider 配置 (備用，若不使用 Hyper-V)
  config.vm.provider "virtualbox" do |vb|
    vb.name = "GraphQLLab-DevVM"
    vb.memory = 2048
    vb.cpus = 2
  end

  # 磁碟擴充配置
  # 注意: 需要安裝 vagrant-disksize plugin
  # 執行: vagrant plugin install vagrant-disksize
  if Vagrant.has_plugin?("vagrant-disksize")
    config.disksize.size = "100GB"
  else
    puts "警告: vagrant-disksize plugin 未安裝，磁碟將使用預設大小"
    puts "執行安裝: vagrant plugin install vagrant-disksize"
  end

  # Provision 腳本: VM 初始化時自動執行
  config.vm.provision "shell", path: "vagrant/provision.sh"

  # 可選: 每次啟動都執行的腳本
  # config.vm.provision "shell", path: "vagrant/startup.sh", run: "always"

  # SSH 配置
  config.ssh.forward_agent = true
  config.ssh.insert_key = true

  # 訊息提示
  config.vm.post_up_message = <<-MESSAGE
  ========================================
  GraphQL Lab 開發環境已啟動！
  ========================================

  VM 資訊:
    - IP: 192.168.56.10
    - Hostname: graphqllab-dev
    - RAM: 2GB
    - Disk: 100GB

  存取方式:
    - SSH: vagrant ssh
    - Go API (DEV): http://localhost:8080
    - Go API (SIT): http://localhost:8081
    - MySQL: localhost:3306

  常用指令:
    - vagrant ssh          # 進入 VM
    - vagrant halt         # 關閉 VM
    - vagrant reload       # 重新啟動 VM
    - vagrant destroy      # 刪除 VM
    - vagrant provision    # 重新執行 provision

  下一步:
    1. vagrant ssh
    2. cd /vagrant
    3. docker compose up -d
  ========================================
  MESSAGE
end
