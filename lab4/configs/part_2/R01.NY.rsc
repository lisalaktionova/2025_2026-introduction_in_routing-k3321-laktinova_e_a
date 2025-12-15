/ip address add address=172.16.1.3/24 interface=ether2
/ip address add address=10.0.1.2/30 interface=ether3

/interface bridge add name=loopback
/ip address add address=10.0.255.1/32 interface=loopback network=10.0.255.1
/routing ospf instance set default router-id=10.0.255.1

/routing ospf network add network=10.0.1.0/30 area=backbone
/routing ospf network add network=10.0.255.1/32 area=backbone

/mpls ldp set enabled=yes transport-address=10.0.255.1 lsr-id=10.0.255.1
/mpls ldp interface add interface=ether2
/mpls ldp interface add interface=ether3

/routing bgp instance set default as=65123 router-id=10.0.255.1
/routing bgp network add network=10.0.255.0/24
/routing bgp peer add name=LND remote-address=10.0.255.2 remote-as=65123 address-families=l2vpn,vpnv4 instance=default update-source=loopback route-reflect=no

/interface bridge add name=vpls
/interface bridge port add bridge=vpls interface=ether2
/ip address add address=10.10.255.11/24 interface=vpls
/interface vpls bgp-vpls add bridge=vpls route-distinguisher=65123:11 import-route-targets=65123:11 export-route-targets=65123:11 site-id=11

/system identity set name=R01.NY
/user add name=lisa group=full password=12345
/user remove admin
