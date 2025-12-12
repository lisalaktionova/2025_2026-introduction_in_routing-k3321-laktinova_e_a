/interface bridge add name=bridge0 vlan-filtering=yes
/interface bridge port add bridge=bridge0 interface=ether2
/interface bridge port add bridge=bridge0 interface=ether3
/interface bridge vlan add bridge=bridge0 vlan-ids=10 tagged=bridge0,ether2 untagged=ether3
/interface bridge port set pvid=10 numbers=1
/interface vlan add name=vlan10 interface=bridge0 vlan-id=10
/ip dhcp-client add interface=vlan10
/ip dhcp-client enable numbers=1
/system identity set name=SW02.L3.01
/user add name=lisa group=full password=12345
/user remove admin
