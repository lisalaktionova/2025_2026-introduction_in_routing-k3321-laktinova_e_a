# header

- University: [ITMO University](https://itmo.ru/ru/)
- Faculty: [FICT](https://fict.itmo.ru)
- Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)
- Year: 2025/2026
- Group: K3321
- Author: Laktionova Elizaveta Artemovna
- Lab: Lab4
- Date of create: 14.12.2025
- Date of finished: 15.12.2025

# Общая часть

Схема сети:

![схема сети](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab4/img/scheme.png)

Аналогично 3й лабораторной были настроены ip адреса на интерфейсах, ospf и mpls. Пример конфигурации для роутера из Хельсинки:

```
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
```

Проверка:

`ip route print` и `mpls forwarding-table print`

![mpls_ospf]()

Для настройки iBGP с RR кластером выбрали в качестве RR роутера R01.LND и присвоили ему `cluster-id = 10.255.255.255`. Роутеры R01.HKI и R01.LBN так же входят в этот кластер, поэтому для них в пире прописывается `route-reflect=yes`, для остальных роутеров - `route-reflect=no`. Также в пире прописывается адрес лупбека роутера назначения (10.0.255.x). В качестве AS был выбран 65123 (всего AS одна). Обязательно прописывается `address-families=l2vpn,vpnv4 `, `l2vpn` для vpls, а `vpnv4` для vrf (так как нам нужно передавать не обычные ipv4 маршруты).

```
/routing bgp instance set default as=65123 router-id=10.0.255.2 cluster-id=10.255.255.255
/routing bgp network add network=10.0.255.0/24
/routing bgp peer add name=NY remote-address=10.0.255.1 remote-as=65123 address-families=l2vpn,vpnv4 instance=default update-source=loopback  route-reflect=no
/routing bgp peer add name=HKI remote-address=10.0.255.3 remote-as=65123 address-families=l2vpn,vpnv4 instance=default update-source=loopback route-reflect=yes
/routing bgp peer add name=LBN remote-address=10.0.255.5 remote-as=65123 address-families=l2vpn,vpnv4 instance=default update-source=loopback route-reflect=yes
```

Проверка (на примере конечного роутера R01.NY):

`routing bgp peer print` и `ip route print where bgp`

![bgp]()

# Часть 1

Настройка vrf осуществляется только на конечных роутерах. Для этого bgp инстанс с названием таблицы маршрутизации `vrf_devops` и параметром `redistribute-connected=yes` для анонсирования сетей, подключенных к этому роутеру. Создается vrf с таким же названием таблицы маршрутизации и задается `export-route-targets` и `import-route-targets` со значением AS:ID vrf,для упрощения `route-distinguisher` - уникальная метка конкретного vrf задан с таким же значением.

```
/interface bridge add name=vrf
/ip address add address=10.0.255.11/32 interface=vrf
/routing bgp instance vrf add routing-mark=vrf_devops redistribute-connected=yes
/ip route vrf add routing-mark=vrf_devops interfaces=vrf export-route-targets=65123:11 import-route-targets=65123:11 route-distinguisher=65123:11
```

Проверка (попробуем пропинговать R01.SVL с R01.NY по таблице `vrf_devops`):

`ip route print where routing-mark=vrf_devops` и `ping 10.0.255.16 routing-table=vrf_devops src=10.0.255.11`

![vrf]()

# Часть 2

Снесли vrf и настроила мост для vpls, куда включила интерфейс, ведущий к конечному устройству. Также необходимо было прописать RD, RT аналогично vrf и задать site-id (уникальный номер конечного роутера). Так как vpls работает на 2 уровне, я подняла dhcp сервер (на R01.SVL) для раздачи ip конечным устройствам из одной сети `172.16.1.0/24`.

```
/interface bridge add name=vpls
/interface bridge port add bridge=vpls interface=ether3
/ip address add address=10.10.255.16/24 interface=vpls
/interface vpls bgp-vpls add bridge=vpls route-distinguisher=65123:11 import-route-targets=65123:11 export-route-targets=65123:11 site-id=16

/ip pool add name=vpls_pool ranges=172.16.1.10-172.16.1.100
/ip dhcp-server network add address=172.16.1.0/24 gateway=172.16.1.1
/ip dhcp-server add address-pool=vpls_pool disabled=no interface=vpls name=dhcp_vpls
```

Проверка:

`interface vpls bgp-vpls print` и `ip dhcp lease print`

![vpls]()
![ping]()
