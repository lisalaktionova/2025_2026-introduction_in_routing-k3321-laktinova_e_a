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

![схема сети](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab3/img/scheme.png)

# Настройка роутеров

На примере R01.NY разберу настройку роутеров.

Создаем loopback мост (понадобится для ospf) и выдаем всем интерфейсам ip в их подсетях:

```
/interface bridge add name=loopback

/ip address add address=10.0.1.1/30 interface=ether2
/ip address add address=10.0.6.1/30 interface=ether3
/ip address add address=172.16.1.1/24 interface=loopback
```

Для конечных устройств поднимаем dhcp сервер:

```
/ip pool add name=pool ranges=172.16.1.2-172.16.1.254
/ip dhcp-server add name=dhcp interface=loopback address-pool=pool disabled=no
/ip dhcp-server network add address=172.16.1.0/24 gateway=172.16.1.1
```

Начинаем настройку ospf с того, что назначаем на loopback айпи, который будет уникальным router-id внутри ospf:

```
/ip address add address=1.1.1.1/32 interface=loopback
/routing ospf instance set default router-id=1.1.1.1
```

По умолчанию создается area `backbone`, добавляем в нее подсети, ведущие к роутерам и loopback.

```
/routing ospf network add network=10.0.1.0/30 area=backbone
/routing ospf network add network=10.0.6.0/30 area=backbone
/routing ospf network add network=1.1.1.1/32 area=backbone
```

Для настройки mpls включаю LDP протокол для распространения меток, назначаем transport-address, по которому будут обращаться соседи, и lsr-id как уникальный идентификатор роутера, по сути тот же router-id ospf'a. Добавляем интерфейсы, ведущие к другим роутерам, в LDP:

```
/mpls ldp set enabled=yes transport-address=1.1.1.1 lsr-id=1.1.1.1
/mpls ldp interface add interface=ether2
/mpls ldp interface add interface=ether3
```

Остаётся только настроить EoMPLS. Для этого создаем vpls интерфейс, указываем в качестве remote-peer ip loopback роутера в Спб и назначаем на обоих роутерах одинаковый cisco-style-id. Добавляем в loopback интерфейс, ведущий к конечному устройству и сам vpls:

```
/interface vpls add name=vpn remote-peer=4.4.4.4 disabled=no cisco-style=yes cisco-style-id=14
/interface bridge port add bridge=loopback interface=ether4
/interface bridge port add bridge=loopback interface=vpn
```

Смена имени устройства и админа/пароля:

```
/system identity set name=R01.NY
/user add name=lisa group=full password=12345
/user remove admin
```

# OSPF

Видно, что все маршруты подтянулись за счет использования ospf без статического прописывания каждого маршрута на всех роутеров:
![ospf](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab3/img/img_1.png)

# MPLS

Можно увидеть метки, которые будут назначены отправленным пакетам:
![mpls](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab3/img/mpls.png)

Проверим пинг пк:

![eompls](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab3/img/pc.png)

![ping](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab3/img/ping.png)
