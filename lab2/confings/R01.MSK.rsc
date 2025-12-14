/ip address add address=172.21.21.2/30 interface=ether2
/ip address add address=172.21.23.1/30 interface=ether3
/ip address add address=10.0.1.1/24 interface=ether4
/ip pool add name=pool ranges=10.0.1.2-10.0.1.254
/ip dhcp-server add name=dhcp interface=ether4 address-pool=pool disabled=no
/ip route add dst-address=10.0.3.0/24 gateway=172.21.21.1
/ip route add dst-address=10.0.2.0/24 gateway=172.21.23.2
/ip dhcp-server network add address=10.0.1.0/24 gateway=10.0.1.1
/system identity set name=R01.MSK
/user add name=lisa group=full password=12345
/user remove admin
