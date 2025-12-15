# header

- University: [ITMO University](https://itmo.ru/ru/)
- Faculty: [FICT](https://fict.itmo.ru)
- Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)
- Year: 2025/2026
- Group: K3321
- Author: Laktionova Elizaveta Artemovna
- Lab: Lab3
- Date of create: 14.12.2025
- Date of finished: 15.12.2025

# main part
Конфигурация лабы:

![Схема](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab3/img/conf.png)

Схема сети:

![схема сети](img/img1.png)

# Настройка роутеров

На примере R01.NY разберу настройку роутеров.

Создаю loopback мост (понадобится для ospf) и выдаю всем интерфейсам ip в их подсетях:

```
/interface bridge add name=loopback

/ip address add address=10.0.1.1/30 interface=ether2
/ip address add address=10.0.6.1/30 interface=ether3
/ip address add address=172.16.1.1/24 interface=loopback
```

Для конечных устройств поднимаю dhcp сервер:

```
/ip pool add name=pool ranges=172.16.1.2-172.16.1.254
/ip dhcp-server add name=dhcp interface=loopback address-pool=pool disabled=no
/ip dhcp-server network add address=172.16.1.0/24 gateway=172.16.1.1
```

Начинаю настройку ospf с того, что назначаю на loopback айпи, который будет уникальным router-id внутри ospf:

```
/ip address add address=1.1.1.1/32 interface=loopback
/routing ospf instance set default router-id=1.1.1.1
```

По умолчанию создается area `backbone`, добавляю в нее подсети, ведущие к роутерам и loopback.

```
/routing ospf network add network=10.0.1.0/30 area=backbone
/routing ospf network add network=10.0.6.0/30 area=backbone
/routing ospf network add network=1.1.1.1/32 area=backbone
```

Для настройки mpls включаю LDP протокол для распространения меток, назначаю transport-address, по которому будут обращаться соседи, и lsr-id как уникальный идентификатор роутера, по сути тот же router-id ospf'a. Добавляю интерфейсы, ведущие к другим роутерам, в LDP:

```
/mpls ldp set enabled=yes transport-address=1.1.1.1 lsr-id=1.1.1.1
/mpls ldp interface add interface=ether2
/mpls ldp interface add interface=ether3
```

Остаётся только настроить EoMPLS. Для этого создаю vpls интерфейс, указываю в качестве remote-peer ip loopback роутера в Спб и назначаю на обоих роутерах одинаковый cisco-style-id. Добавляю в loopback интерфейс, ведущий к конечному устройству и сам vpls:

```
/interface vpls add name=vpn remote-peer=4.4.4.4 disabled=no cisco-style=yes cisco-style-id=14
/interface bridge port add bridge=loopback interface=ether4
/interface bridge port add bridge=loopback interface=vpn
```

Ну и привычная смена имени устройства и админа/пароля:

```
/system identity set name=R01.NY
/user add name=agonek group=full password=******
/user remove admin
```

# OSPF

Видно, что все маршруты подтянулись за счет использования ospf без статического прописывания каждого маршрута на всех роутеров:
![ospf](img/img2.png)

# MPLS

Можно увидеть метки, которые будут назначены отправленным пакетам:
![mpls](img/img3.png)

С помощью traceroute можно увидеть как работает ospf и mpls:
![ospf-mpls](img/img4.png)

# EoMPLS

Проверим настройку EoMPLS и пинг пк:

![eompls](img/img5.png)

![ping](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab3/img/ping.png)
