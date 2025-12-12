# header
- University: [ITMO University](https://itmo.ru/ru/)
- Faculty: [FICT](https://fict.itmo.ru)
- Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)
- Year: 2025/2026
- Group: K3321
- Author: Laktionova Elizaveta Artemovna
- Lab: Lab1
- Date of create: 10.11.2025
- Date of finished: 12.12.2025

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
[lisa@R.01] > /export
# dec/12/2025 13:38:58 by RouterOS 6.47.9
# software id = 
#
#
#
/interface ethernet
set [ find default-name=ether1 ] disable-running-check=no
set [ find default-name=ether2 ] disable-running-check=no
/interface vlan
add interface=ether2 name=VLAN10 vlan-id=10
add interface=ether2 name=VLAN20 vlan-id=20
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip pool
add name=POOL_VLAN10 ranges=10.10.10.2-10.10.10.100
add name=POOL_VLAN20 ranges=10.10.20.2-10.10.20.100
/ip dhcp-server
add address-pool=POOL_VLAN10 disabled=no interface=VLAN10 name=DHCP_VLAN10
add address-pool=POOL_VLAN20 disabled=no interface=VLAN20 name=DHCP_VLAN20
/ip address
add address=172.31.255.30/30 interface=ether1 network=172.31.255.28
add address=10.10.10.1/24 interface=VLAN10 network=10.10.10.0
add address=10.10.20.1/24 interface=VLAN20 network=10.10.20.0
/ip dhcp-client
add disabled=no interface=ether1
/ip dhcp-server network
add address=10.10.10.0/24 gateway=10.10.10.1
add address=10.10.20.0/24 gateway=10.10.20.1
/system identity
set name=R.01
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
[lisa@SW01.L3.01] > /export
# dec/12/2025 13:46:19 by RouterOS 6.47.9
# software id = 
#
#
#
/interface bridge
add name=bridge0 vlan-filtering=yes
/interface ethernet
set [ find default-name=ether1 ] disable-running-check=no
set [ find default-name=ether2 ] disable-running-check=no
set [ find default-name=ether3 ] disable-running-check=no
set [ find default-name=ether4 ] disable-running-check=no
/interface vlan
add interface=bridge0 name=vlan10 vlan-id=10
add interface=bridge0 name=vlan20 vlan-id=20
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/interface bridge port
add bridge=bridge0 interface=ether2
add bridge=bridge0 interface=ether3
add bridge=bridge0 interface=ether4
/interface bridge vlan
add bridge=bridge0 tagged=bridge0,ether2,ether3 vlan-ids=10
add bridge=bridge0 tagged=bridge0,ether2,ether4 vlan-ids=20
/ip address
add address=172.31.255.30/30 interface=ether1 network=172.31.255.28
/ip dhcp-client
add disabled=no interface=ether1
add disabled=no interface=vlan10
add disabled=no interface=vlan20
/system identity
set name=SW01.L3.01
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

```
[lisa@SW02.L3.01] > /export
# dec/12/2025 13:59:35 by RouterOS 6.47.9
# software id = 
#
#
#
/interface bridge
add name=bridge0 vlan-filtering=yes
/interface ethernet
set [ find default-name=ether1 ] disable-running-check=no
set [ find default-name=ether2 ] disable-running-check=no
set [ find default-name=ether3 ] disable-running-check=no
/interface vlan
add interface=bridge0 name=vlan10 vlan-id=10
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/interface bridge port
add bridge=bridge0 interface=ether2
add bridge=bridge0 interface=ether3 pvid=10
/interface bridge vlan
add bridge=bridge0 tagged=bridge0,ether2 untagged=ether3 vlan-ids=10
/ip address
add address=172.31.255.30/30 interface=ether1 network=172.31.255.28
/ip dhcp-client
add disabled=no interface=ether1
add disabled=no interface=vlan10
/system identity
set name=SW02.L3.01
```

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

Экспорт конфигурации:

```
@SW02.L3.02] > /export
# dec/12/2025 14:01:33 by RouterOS 6.47.9
# software id = 
#
#
#
/interface bridge
add name=bridge0 vlan-filtering=yes
/interface ethernet
set [ find default-name=ether1 ] disable-running-check=no
set [ find default-name=ether2 ] disable-running-check=no
set [ find default-name=ether3 ] disable-running-check=no
/interface vlan
add interface=bridge0 name=vlan20 vlan-id=20
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/interface bridge port
add bridge=bridge0 interface=ether2
add bridge=bridge0 interface=ether3 pvid=20
/interface bridge vlan
add bridge=bridge0 tagged=bridge0,ether2 untagged=ether3 vlan-ids=20
/ip address
add address=172.31.255.30/30 interface=ether1 network=172.31.255.28
/ip dhcp-client
add disabled=no interface=ether1
add disabled=no interface=vlan20
/system identity
set name=SW02.L3.02
```

# 2.  Схема связи, пинги, проверка выдачи ip

![Схема](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab1/img/scheme.png)

ip, выданные dhcp серверами и попробуем пропинговать оба пк с роутера:

![Пинг](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab1/img/ip_dhcp.png)

Проверки:

![Пинг](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab1/img/checking.png)

Пинг между PC1 и PC2, между PC1 и PC2, PC1 и свои шлюзом, PC2 и своим шлюзом:

![Пинг](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab1/img/checking_2.png)
