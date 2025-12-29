/ip address add address=10.0.6.1/30 interface=ether2
/ip address add address=172.16.1.1/24 interface=ether3

/interface bridge add name=loopback
/ip address add address=10.0.255.6/32 interface=loopback network=10.0.255.6
/routing ospf instance set default router-id=10.0.255.6

/routing ospf network add network=10.0.6.0/30 area=backbone
/routing ospf network add network=10.0.255.6/32 area=backbone

/mpls ldp set enabled=yes transport-address=10.0.255.6 lsr-id=10.0.255.6
/mpls ldp interface add interface=ether2
/mpls ldp interface add interface=ether3

/routing bgp instance set default as=65123 router-id=10.0.255.6
/routing bgp network add network=10.0.255.0/24
/routing bgp peer add name=LBN remote-address=10.0.255.5 remote-as=65123 address-families=l2vpn,vpnv4 instance=default update-source=loopback route-reflect=no

/interface bridge add name=vpls
/interface bridge port add bridge=vpls interface=ether3
/ip address add address=10.10.255.16/24 interface=vpls
/interface vpls bgp-vpls add bridge=vpls route-distinguisher=65123:11 import-route-targets=65123:11 export-route-targets=65123:11 site-id=16

/system identity set name=R01.SVL
/user add name=lisa group=full password=12345
/user remove admin
