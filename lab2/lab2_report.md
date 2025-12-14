# header
- University: [ITMO University](https://itmo.ru/ru/)
- Faculty: [FICT](https://fict.itmo.ru)
- Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)
- Year: 2025/2026
- Group: K3321
- Author: Laktionova Elizaveta Artemovna
- Lab: Lab2
- Date of create: 12.12.2025
- Date of finished: 15.12.2025

# 0. prepare
Лабораторная работа выполнялась в виртуальной машине VMware Workstation.

Конфигурация лабы:

![Схема](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab2/img/conf.png)

Схема сети:

![схема сети](https://github.com/lisalaktionova/2025_2026-introduction_in_routing-k3321-laktinova_e_a/blob/main/lab2/img/diagram.png)

# 1. Настройка сетевого оборудования

Разберем пример с Берлинским роутером.

Назначаем ip адреса интерфейсам, ведущим к другим роутерам:

```
/ip address add address=172.21.21.1/30 interface=ether2
/ip address add address=172.21.21.1/30 interface=ether3
```

Назначаем ip адрес интерфейсу, ведущему к ПК:

```
/ip address add address=10.0.3.1/24 interface=ether4
```

Задаем пул адресов и сеть для dhcp сервера и поднимаем его:

```
/ip pool add name=pool ranges=10.0.3.2-10.0.3.254
/ip dhcp-server add name=dhcp interface=ether4 address-pool=pool disabled=no
/ip dhcp-server network add address=10.0.3.0/24 gateway=10.0.3.1
```

Прописываем статические маршруты к двум другим подсетям с ПК:

```
/ip route add dst-address=10.0.1.0/24 gateway=172.21.21.2
/ip route add dst-address=10.0.2.0/24 gateway=172.21.21.2
```

Меняем название, юзера, пароль:

```
/system identity set name=R01.BRL
/user add name=agonek group=full password=******
/user remove admin

```

С остальными роутерами по аналогии. R.01.FRT:

```
/ip address add address=192.168.2.2/30 interface=ether2
/ip address add address=192.168.3.2/30 interface=ether3
/ip address add address=10.0.2.1/24 interface=ether4
/ip pool add name=pool ranges=10.0.2.2-10.0.2.254
/ip dhcp-server add name=dhcp interface=ether4 address-pool=pool disabled=no
/ip dhcp-server network add address=10.0.2.0/24 gateway=10.0.2.1
/ip route add dst-address=10.0.1.0/24 gateway=192.168.3.1
/ip route add dst-address=10.0.3.0/24 gateway=192.168.2.1
/system identity set name=R01.FRT
/user add name=agonek group=full password=******
/user remove admin

```

R.01.MSK:

```
/ip address add address=192.168.1.2/30 interface=ether2
/ip address add address=192.168.3.1/30 interface=ether3
/ip address add address=10.0.1.1/24 interface=ether4
/ip pool add name=pool ranges=10.0.1.2-10.0.1.254
/ip dhcp-server add name=dhcp interface=ether4 address-pool=pool disabled=no
/ip route add dst-address=10.0.3.0/24 gateway=192.168.1.1
/ip route add dst-address=10.0.2.0/24 gateway=192.168.3.2
/ip dhcp-server network add address=10.0.1.0/24 gateway=10.0.1.1
/system identity set name=R01.MSK
/user add name=agonek group=full password=******
/user remove admin
```

# 2. Настройка ПК

Всё, что требуется на ПК, я указала в `exec` в `clab.yaml`, а именно:

- поднятие dhcp сервера: `udhcpc -i eth1`
- два роута к другим подсетям с ПК: `ip route add 10.0.x.0/24 via 10.0.3.1 dev eth1`

# 3. Проверка сети

Использованные команды:

- `/ip dhcp-server lease print` - подтверждение выдачи ip ПК
- `ip route print` - вывод заданных маршрутов

Пинг роутеров между собой на примере R.01.BRL:

![ping роутеров](img/img2.png)

Пинг ПК между собой на примере PC1:

![ping пк](img/img3.png)
