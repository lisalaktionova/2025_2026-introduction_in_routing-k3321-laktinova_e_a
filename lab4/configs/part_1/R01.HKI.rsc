/ip address add address=10.0.2.1/30 interface=ether2
/ip address add address=10.0.5.2/30 interface=ether3
/ip address add address=10.0.4.2/30 interface=ether4

/interface bridge add name=loopback
/ip address add address=10.0.255.3/32 interface=loopback network=10.0.255.3
/routing ospf instance set default router-id=10.0.255.3

/routing ospf network add network=10.0.2.0/30 area=backbone
/routing ospf network add network=10.0.5.0/30 area=backbone
/routing ospf network add network=10.0.4.0/30 area=backbone
/routing ospf network add network=10.0.255.3/32 area=backbone

/mpls ldp set enabled=yes transport-address=10.0.255.3 lsr-id=10.0.255.3
/mpls ldp interface add interface=ether2
/mpls ldp interface add interface=ether3
/mpls ldp interface add interface=ether4

/routing bgp instance set default as=65123 router-id=10.0.255.3
/routing bgp network add network=10.0.255.0/24
/routing bgp peer add name=LND remote-address=10.0.255.2 remote-as=65123 address-families=l2vpn,vpnv4 instance=default update-source=loopback route-reflect=yes
/routing bgp peer add name=SPB remote-address=10.0.255.4 remote-as=65123 address-families=l2vpn,vpnv4 instance=default update-source=loopback route-reflect=no
/routing bgp peer add name=LBN remote-address=10.0.255.5 remote-as=65123 address-families=l2vpn,vpnv4 instance=default update-source=loopback route-reflect=yes

/system identity set name=R01.HKI
/user add name=agonek group=full password=******
/user remove admin
