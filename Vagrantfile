# -*- mode: ruby -*-
# vi: set ft=ruby :

# 禁用 VirtualBox 檢查
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'hyperv'

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204" 
  config.vm.box_version = ">= 0"

  # VM 基本設定
  config.vm.hostname = "lab01"
  config.vm.network "public_network",
    bridge: "外部虛擬交換器",
    ip: "192.168.11.110"

  # 同步資料夾配置
  # 生產環境模擬：停用同步資料夾，改用 Git Clone
  # config.vm.synced_folder ".", "/vagrant", disabled: true

  # 若開發時需要同步資料夾，可啟用
  config.vm.synced_folder ".", "/vagrant", disabled: false

  # Hyper-V Provider 配置
  config.vm.provider "hyperv" do |h|
    # VM 名稱
    h.vmname = "lab01"

    # 記憶體配置: 2GB
    h.memory = 2048

    # CPU 核心數
    h.cpus = 1

    # 啟用動態記憶體 (Hyper-V 特性)
    h.enable_virtualization_extensions = true
    h.linked_clone = true

    # 自動啟動與停止時間設定
    h.auto_start_action = "Nothing"
    h.auto_stop_action = "ShutDown"
  end

  # 磁碟擴充配置
  # 注意: vagrant-disksize plugin 與 Hyper-V 不相容，暫時停用
  # Hyper-V 磁碟大小由 base box 決定(128GB)，或在 VM 建立後手動擴充

  # Provision 腳本: VM 初始化時自動執行
  config.vm.provision "shell", path: "vagrant/provision.sh"

  # 可選: 每次啟動都執行的腳本
  # config.vm.provision "shell", path: "vagrant/startup.sh", run: "always"

  # SSH 配置
  config.ssh.forward_agent = true
  config.ssh.insert_key = true

  # 允許密碼登入 (生產環境模擬)
  config.vm.provision "shell", inline: <<-SHELL
    # 啟用 SSH 密碼認證
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
  SHELL

  # 訊息提示
  config.vm.post_up_message = <<-MESSAGE
  ========================================
  GraphQL Lab 開發環境已啟動！
  ========================================

  VM 資訊:
    - VM Name: lab01
    - Hostname: lab01
    - cpus: 1
    - RAM: 2GB
    - Disk: 128GB base box 預設決定，如不夠在手動擴充
    - Network: Public Network (Bridged)

  查詢 VM IP 位址:
    vagrant ssh -c "ip addr show | grep 'inet '"

  SSH 連線方式:
    1. Vagrant SSH:
       vagrant ssh

    2. 標準 SSH (需先查詢 IP):
       ssh vagrant@192.168.11.110
       ssh lab01@192.168.11.110   (密碼: adaruru)
       ssh root@192.168.11.110    (密碼: adaruru)

  常用指令:
    - vagrant ssh                        # 進入 VM
    - vagrant ssh -c "ip a"              # 查看 VM IP
    - vagrant halt                       # 關閉 VM
    - vagrant reload                     # 重新啟動 VM
    - vagrant destroy                    # 刪除 VM
    - vagrant provision                  # 重新執行 provision

  下一步:
    1. 查詢 VM IP: vagrant ssh -c "hostname -I"
    2. SSH 連線: ssh vagrant@<VM_IP>
    3. Clone 專案: git clone <repo_url>
    4. 啟動服務: docker compose up -d
  ========================================
  MESSAGE
end
