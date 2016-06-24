
# Copyright (c) 2011 Dell Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Note : This script runs on both the admin and compute nodes.
# It intentionally ignores the bios->enable node data flag.

bmc_vlan_net = Barclamp::Inventory.get_network_by_type(node, "bmc_vlan")
bmc_net = Barclamp::Inventory.get_network_by_type(node, "bmc")
admin_net = Barclamp::Inventory.get_network_by_type(node, "admin")

return if bmc_vlan_net.nil? || bmc_net.nil? || admin_net.nil?

bash "Set up masquerading for the BMC network" do
  code <<EOC
iptables -t nat -F POSTROUTING
iptables -t nat -A POSTROUTING -s #{admin_net.subnet}/#{admin_net.netmask} -d #{bmc_net.subnet}/#{bmc_net.netmask} -j SNAT --to-source #{bmc_vlan_net.address}
iptables -P FORWARD DROP
iptables -F FORWARD
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s #{admin_net.subnet}/#{admin_net.netmask} -d #{bmc_net.subnet}/#{bmc_net.netmask} -j ACCEPT
echo 1 >/proc/sys/net/ipv4/ip_forward
EOC
  not_if "iptables -t nat --list -n | grep #{bmc_vlan_net.address}"
end
