#
# Cookbook:: embyserver
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

# selinux off
execute 'selinuxoff' do
  command 'sudo setenforce 0'
  not_if { ::File.exist?("/tmp/firstrunflag") }
end

# firewall off
execute 'selinuxoff' do
  command 'systemctl disable firewalld; systemctl stop firewalld'
  not_if { ::File.exist?("/tmp/firstrunflag") }
end

file '/tmp/firstrunflag' do
  action :create
end

# directories stage
dir_list = ['/media/Videos', '/opt/emby-server', '/opt/emby-server/cache']
dir_list.each { |i| directory i }

cookbook_file '/etc/selinux/config' do
  source 'selinux.conf'
  mode '0644'
  owner 'root'
  group 'root'
  notifies :run, 'execute[reboot_system]', :delayed
end

# some packages
%w(epel-release
   htop
   mc
   nfs-utils).each do |pkg|
     package pkg
   end

# # remote file
# remote_file '/tmp/emby-server-rpm_3.5.0.0_x86_64.rpm' do
#   source 'https://github.com/MediaBrowser/Emby.Releases/releases/download/3.5.0.0/emby-server-rpm_3.5.0.0_x86_64.rpm'
#   action :create
# end

linea = '172.17.102.164:/var/nfsshare/Videos /media/Videos   nfs defaults 0 0'

execute 'insertalinea' do
  command "grep -q -F #{linea} /etc/fstab || echo #{linea} >> /etc/fstab"
end

# mount '/media/Videos' do
#   device '172.17.102.164:/var/nfsshare/Videos'
#   fstype 'nfs'
#   options 'rw'
# end

cookbook_file '/tmp/emby-server-rpm_3.5.0.0_x86_64.rpm' do
  source 'emby-server-rpm_3.5.0.0_x86_64.rpm'
  mode '0755'
  owner 'root'
  group 'root'
end

# install emby rpm
package 'emby-server' do
  action :install
  source '/tmp/emby-server-rpm_3.5.0.0_x86_64.rpm'
end

# emby cache
directory '/opt/emby-server/cache' do
  action :create
  owner 'emby'
  notifies :run, 'execute[reboot_system]', :delayed
end

# reboot system
execute 'reboot_system' do
  command '{ sleep 300; reboot; } &'
  action :nothing
end
