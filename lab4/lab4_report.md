# header

- University: [ITMO University](https://itmo.ru/ru/)
- Faculty: [FICT](https://fict.itmo.ru)
- Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)
- Year: 2025/2026
- Group: K3321
- Author: Laktionova Elizaveta Artemovna
- Lab: Lab4
- Date of create: 14.12.2025
- Date of finished: 29.12.2025

# Общая часть

Схема сети:

![схема сети](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab4/img/%D1%81%D1%85%D0%B5%D0%BC%D0%B0.png)

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

![](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab4/img/check1.png)

![](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab4/img/check2.png)

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

![](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab4/img/check3.png)

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

![](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab4/img/check_ping1.png)

# Часть 2

Реализовали услугу VPLS (Virtual Private LAN Service) поверх MPLS с использованием BGP-signaling.
На PE-маршрутизаторах была удалена конфигурация VRF, после чего был создан мост bridge vpls, в который включён интерфейс, ведущий к конечному устройству. Таким образом, клиентские сегменты сети были объединены на канальном уровне (L2), без использования маршрутизации между ними.

Для работы VPLS были настроены следующие параметры Route Distinguisher (RD), Import / Export Route Targets (RT)и Site-ID, уникальный для каждого PE-маршрутизатора.

Каждому PE-маршрутизатору был назначен IP-адрес на интерфейсе vpls. Этот адрес используется исключительно для служебных и диагностических целей, так как передача клиентского трафика осуществляется на втором уровне модели OSI.

IP-адреса конечным устройствам задаются статически, все они находятся в одной подсети 172.16.1.0/24, что позволяет обеспечить их прозрачное взаимодействие через VPLS-домен.

Пример конфигурации VPLS на PE-маршрутизаторе
```
/interface bridge add name=vpls
/interface bridge port add bridge=vpls interface=ether1

/ip address add address=10.10.255.11/24 interface=vpls

/interface vpls bgp-vpls add \
  bridge=vpls \
  route-distinguisher=65123:11 \
  import-route-targets=65123:11 \
  export-route-targets=65123:11 \
  site-id=11
```

Проверка:

`interface vpls bgp-vpls print`

![](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab4/img/vpls.png)
![ping](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab4/img/ping_2.png)
