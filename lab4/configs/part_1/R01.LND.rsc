/ip address add address=10.0.1.1/30 interface=ether2
/ip address add address=10.0.2.2/30 interface=ether3
/ip address add address=10.0.3.2/30 interface=ether4

/interface bridge add name=loopback
/ip address add address=10.0.255.2/32 interface=loopback network=10.0.255.2
/routing ospf instance set default router-id=10.0.255.2

/routing ospf network add network=10.0.1.0/30 area=backbone
/routing ospf network add network=10.0.2.0/30 area=backbone
/routing ospf network add network=10.0.3.0/30 area=backbone
/routing ospf network add network=10.0.255.2/32 area=backbone

/mpls ldp set enabled=yes transport-address=10.0.255.2 lsr-id=10.0.255.2
/mpls ldp interface add interface=ether2
/mpls ldp interface add interface=ether3
/mpls ldp interface add interface=ether4

/routing bgp instance set default as=65123 router-id=10.0.255.2 cluster-id=10.255.255.255
/routing bgp network add network=10.0.255.0/24
/routing bgp peer add name=NY remote-address=10.0.255.1 remote-as=65123 address-families=l2vpn,vpnv4 instance=default update-source=loopback  route-reflect=no
/routing bgp peer add name=HKI remote-address=10.0.255.3 remote-as=65123 address-families=l2vpn,vpnv4 instance=default update-source=loopback route-reflect=yes
/routing bgp peer add name=LBN remote-address=10.0.255.5 remote-as=65123 address-families=l2vpn,vpnv4 instance=default update-source=loopback route-reflect=yes


/system identity set name=R01.LND
/user add name=lisa group=full password=12345
/user remove admin
