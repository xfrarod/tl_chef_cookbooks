#
# Cookbook:: custom_nginx
# Recipe:: default
#
# Copyright:: 2019, The Authors, All Rights Reserved.
node.default['nginx']['init_style'] = 'systemd'
node.default['nginx']['gzip'] = 'on'

package "openssl"

include_recipe "nginx::default"
