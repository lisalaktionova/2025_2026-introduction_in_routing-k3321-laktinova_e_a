# header
- University: [ITMO University](https://itmo.ru/ru/)
- Faculty: [FICT](https://fict.itmo.ru)
- Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)
- Year: 2025/2026
- Group: K3321
- Author: Laktionova Elizaveta Artemovna
- Lab: Lab1
- Date of create: 10.11.2025
- Date of finished: 01.12.2025

# 0. prepare
Лабораторная работа выполнялась в виртуальной машине VMware Workstation.

Конфигурация лабы:

![Схема](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab1/img/conf.png)

Выделили mgmt сеть для доступа к устройствам, выдали им ip адреса. В image указаны используемые образы, а в kind типы того, что запускается, linux - контейнер.

# 1. Настройка сетевого оборудования

## Роутер

R.01 - создаем `VLAN10`, `VLAN20`, выдаём интерфейсам ip. Выделяем диапазоны и поднимаем dhcp сервера, настраиваем их сети и шлюзы. Для каждого сетевого устройства также прописаны создание нового пользователя и смена имени:
```
interface vlan add name=VLAN10 interface=ether2 vlan-id=10
/interface vlan add name=VLAN20 interface=ether2 vlan-id=20
/ip address add address=10.10.10.1/24 interface=VLAN10
/ip address add address=10.10.20.1/24 interface=VLAN20
/ip pool add name=POOL_VLAN10 ranges=10.10.10.2-10.10.10.100
/ip pool add name=POOL_VLAN20 ranges=10.10.20.2-10.10.20.100
/ip dhcp-server add name=DHCP_VLAN10 interface=VLAN10 address-pool=POOL_VLAN10 disabled=no
/ip dhcp-server add name=DHCP_VLAN20 interface=VLAN20 address-pool=POOL_VLAN20 disabled=no
/ip dhcp-server network add address=10.10.10.0/24 gateway=10.10.10.1
/ip dhcp-server network add address=10.10.20.0/24 gateway=10.10.20.1
/system identity set name=R.01
/user add name=lisa group=full password=12345
/user remove admin

```

Проверка конфигурации:

```
# Проверка конфигурации
ip addr show
ip link show type vlan
ps aux | grep dnsmasq
```
## Центральный свитч

SW01.L3.01 - объединяем порты в мост, прописываем trunk порты. Получаем ip через dhcp клиентов:
```
/interface bridge add name=bridge0 vlan-filtering=yes
/interface bridge port add bridge=bridge0 interface=ether2
/interface bridge port add bridge=bridge0 interface=ether3
/interface bridge port add bridge=bridge0 interface=ether4
/interface bridge vlan add bridge=bridge0 vlan-ids=10 tagged=bridge0,ether2,ether3
/interface bridge vlan add bridge=bridge0 vlan-ids=20 tagged=bridge0,ether2,ether4
/interface vlan add name=vlan10 interface=bridge0 vlan-id=10
/interface vlan add name=vlan20 interface=bridge0 vlan-id=20
/ip dhcp-client add interface=vlan10
/ip dhcp-client add interface=vlan20
/ip dhcp-client enable numbers=1
/ip dhcp-client enable numbers=2
/system identity set name=SW01.L3.01
/user add name=lisa group=full password=12345
/user remove admin

```

Проверка конфигурации:

```
bridge vlan show
bridge link show
```

## Промежуточные свитчи

SW02.L3.01 - аналогично с центральным свитчом, но теперь появляются access порты для пк (pvid нужен для привязки нетегированного трафика от пк к vlan10):
```
/interface bridge add name=bridge0 vlan-filtering=yes
/interface bridge port add bridge=bridge0 interface=ether2
/interface bridge port add bridge=bridge0 interface=ether3
/interface bridge vlan add bridge=bridge0 vlan-ids=10 tagged=bridge0,ether2 untagged=ether3
/interface bridge port set pvid=10 numbers=1
/interface vlan add name=vlan10 interface=bridge0 vlan-id=10
/ip dhcp-client add interface=vlan10
/ip dhcp-client enable numbers=1
/system identity set name=SW02.L3.01
/user add name=lisa group=full password=12345
/user remove admin

```

Экспорт конфигурации:

SW02.L3.02 - аналогично SW02.L3.01 за исключениям изменения номера `VLAN`:
```
/interface bridge add name=bridge0 vlan-filtering=yes
/interface bridge port add bridge=bridge0 interface=ether2
/interface bridge port add bridge=bridge0 interface=ether3
/interface bridge vlan add bridge=bridge0 vlan-ids=20 tagged=bridge0,ether2 untagged=ether3
/interface bridge port set pvid=20 numbers=1
/interface vlan add name=vlan20 interface=bridge0 vlan-id=20
/ip dhcp-client add interface=vlan20
/ip dhcp-client enable numbers=1
/system identity set name=SW02.L3.02
/user add name=lisa group=full password=12345
/user remove admin

```

# 2. Получение ip от dhcp-серверов на пк

PC1 - получаем ip от роутера, прописываем маршрут от одной сети к другой:
```
# Получение IP через DHCP
udhcpc -i eth1 -n -q

# Результат:
# udhcpc: started, v1.36.1
# udhcpc: broadcasting discover
# udhcpc: broadcasting select for 10.10.10.103, server 10.10.10.1
# udhcpc: lease of 10.10.10.103 obtained from 10.10.10.1, lease time 3600

# Проверка IP-адреса
ip addr show eth1
# 46: eth1@if45: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9500 qdisc noqueue state UP 
#     inet 10.10.10.103/24 brd 10.10.10.255 scope global eth1

# Добавление маршрута к VLAN 20
ip route add 10.10.20.0/24 via 10.10.10.1
```
PC2:
Аналогично PC1, за исключением роута
```
# Получение IP через DHCP
udhcpc -i eth1 -n -q

# Настройка статического IP (если DHCP не сработал)
ip addr add 10.10.20.20/24 dev eth1
ip route add default via 10.10.20.1

# Добавление маршрута к VLAN 10
ip route add 10.10.10.0/24 via 10.10.20.1
```

# 3.  Схема связи, пинги, проверка выдачи ip

![Схема](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab1/%D0%A1%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA%20%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0%202025-12-01%20171519.png)

Проверки:

![Пинг](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab1/%D0%A1%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA%20%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0%202025-12-01%20170848.png)

Пинг между PC1 и PC2:

![Пинг](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab1/%D0%A1%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA%20%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0%202025-12-01%20174519.png)

# ?. Полезные ссылки

- [mikrotik vlan doc](https://help.mikrotik.com/docs/spaces/ROS/pages/28606465/Bridge+VLAN+Table)
- [containerlab mikrotik ethers doc](https://containerlab.dev/manual/kinds/vr-ros/#__tabbed_1_1)
