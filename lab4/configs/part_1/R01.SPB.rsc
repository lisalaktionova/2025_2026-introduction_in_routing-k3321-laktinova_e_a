/ip address add address=10.0.5.1/30 interface=ether2
/ip address add address=172.16.1.1/24 interface=ether3

/interface bridge add name=loopback
/ip address add address=10.0.255.4/32 interface=loopback network=10.0.255.4
/routing ospf instance set default router-id=10.0.255.4

/routing ospf network add network=10.0.5.0/30 area=backbone
/routing ospf network add network=10.0.255.4/32 area=backbone

/mpls ldp set enabled=yes transport-address=10.0.255.4 lsr-id=10.0.255.4
/mpls ldp interface add interface=ether2
/mpls ldp interface add interface=ether3

/routing bgp instance set default as=65123 router-id=10.0.255.4
/routing bgp network add network=10.0.255.0/24
/routing bgp peer add name=HKI remote-address=10.0.255.3 remote-as=65123 address-families=l2vpn,vpnv4 instance=default update-source=loopback route-reflect=no

/interface bridge add name=vrf
/ip address add address=10.0.255.14/32 interface=vrf
/routing bgp instance vrf add routing-mark=vrf_devops redistribute-connected=yes
/ip route vrf add routing-mark=vrf_devops interfaces=vrf export-route-targets=65123:11 import-route-targets=65123:11 route-distinguisher=65123:11

/system identity set name=R01.SPB
/user add name=lisa group=full password=12345
/user remove admin
