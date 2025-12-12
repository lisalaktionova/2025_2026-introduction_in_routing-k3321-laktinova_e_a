interface vlan add name=VLAN10 interface=ether2 vlan-id=10
/interface vlan add name=VLAN20 interface=ether2 vlan-id=20
/ip address add address=10.10.10.1/24 interface=VLAN10
/ip address add address=10.10.20.1/24 interface=VLAN20
/ip pool add name=POOL_VLAN10 ranges=10.10.10.2-10.10.10.100
/ip pool add name=POOL_VLAN20 ranges=10.10.20.2-10.10.20.100
/ip dhcp-server add name=DHCP_VLAN10 interface=VLAN10 address-pool=POOL_VLAN10 disabled=no
/ip dhcp-server add name=DHCP_VLAN20 interface=VLAN20 address-pool=POOL_VLAN20 disabled=no
/ip dhcp-server network add address=10.10.10.0/24 gateway=10.10.10.1
/ip dhcp-server network add address=10.10.20.0/24 gateway=10.10.20.1
/system identity set name=R.01
/user add name=lisa group=full password=12345
/user remove admin
