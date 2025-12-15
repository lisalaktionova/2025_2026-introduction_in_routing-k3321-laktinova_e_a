/ip address add address=10.0.3.1/30 interface=ether2
/ip address add address=10.0.4.1/30 interface=ether3
/ip address add address=10.0.6.2/30 interface=ether4

/interface bridge add name=loopback
/ip address add address=10.0.255.5/32 interface=loopback network=10.0.255.5
/routing ospf instance set default router-id=10.0.255.5

/routing ospf network add network=10.0.3.0/30 area=backbone
/routing ospf network add network=10.0.4.0/30 area=backbone
/routing ospf network add network=10.0.6.0/30 area=backbone
/routing ospf network add network=10.0.255.5/32 area=backbone

/mpls ldp set enabled=yes transport-address=10.0.255.5 lsr-id=10.0.255.5
/mpls ldp interface add interface=ether2
/mpls ldp interface add interface=ether3
/mpls ldp interface add interface=ether4

/routing bgp instance set default as=65123 router-id=10.0.255.5
/routing bgp network add network=10.0.255.0/24
/routing bgp peer add name=LND remote-address=10.0.255.2 remote-as=65123 address-families=l2vpn,vpnv4 instance=default update-source=loopback route-reflect=yes
/routing bgp peer add name=HKI remote-address=10.0.255.3 remote-as=65123 address-families=l2vpn,vpnv4 instance=default update-source=loopback route-reflect=yes
/routing bgp peer add name=SVL remote-address=10.0.255.6 remote-as=65123 address-families=l2vpn,vpnv4 instance=default update-source=loopback route-reflect=no


/system identity set name=R01.LBN
/user add name=lisa group=full password=12345
/user remove admin
