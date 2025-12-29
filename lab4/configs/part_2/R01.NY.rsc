/interface bridge add name=loopback
/ip address add address=10.0.255.1/32 interface=loopback

/routing ospf instance set [find default=yes] router-id=10.0.255.1
/routing ospf area add name=backbone area-id=0.0.0.0
/routing ospf network add network=10.0.0.0/16 area=backbone

/mpls set enabled=yes
/mpls ldp set enabled=yes transport-address=10.0.255.1
/mpls ldp interface add interface=ether2

/routing bgp instance set default as=65123 router-id=10.0.255.1
/routing bgp peer add name=LND remote-address=10.0.255.2 remote-as=65123 update-source=loopback address-families=vpnv4,l2vpn

/interface bridge add name=vpls
/interface bridge port add bridge=vpls interface=ether1
/ip address add address=10.10.255.11/24 interface=vpls

/interface vpls bgp-vpls add \
  bridge=vpls \
  route-distinguisher=65123:11 \
  import-route-targets=65123:11 \
  export-route-targets=65123:11 \
  site-id=11

/system identity set name=R01.NY
/user add name=lisa group=full password=12345
/user remove admin
