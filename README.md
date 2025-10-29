# Дипломная работа 

### Задача

Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в Yandex Cloud и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git.

### Инфраструктура

Для развёртки инфраструктуры используйте Terraform и Ansible.

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal - для этого достаточно при создании ВМ указать name=example, hostname=examle !!

Важно: используйте по-возможности минимальные конфигурации ВМ:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая.

Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Создайте Target Group, включите в неё две созданных ВМ.

Создайте Backend Group, настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте HTTP router. Путь укажите — /, backend group — созданную ранее.

Создайте Application load balancer для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт curl -v <публичный IP балансера>:80

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix.

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте Security Groups соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh. Эта вм будет реализовывать концепцию bastion host . Синоним "bastion host" - "Jump host". Подключение ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью ProxyCommand . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

# Выполнение дипломной работы

### Terraform

### Инфраструктура
1. Cкачивание Terraform
2. Распаковываем архив
3. Выдаем права на запуск
```
chmod 766 terraform
 ```
5. Проверяем работоспособность
```
./terraform -v
 ```
6. Создание файла конфигурации и выдача прав 
```
nano ~/.terraformrc
chmod 644 .terraformrc
 ```
7. Вносим данные, указанные в документации
```
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
 ```
8. В папке, в которой будет запускаться Terraform, создаем файл main.tf с следующим содежанием
```
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token = "токен"
  cloud_id  = "id облака"
  folder_id = "id папки"
}
 ```
9. Создать файл meta.yaml
```
users:
  - name: user
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ssh-rsa ***
 ```
10. Инициализация Terraform
```
./terraform init
 ```

# Развёртка Terraform
Подготовка .tf конфигов, после начинаем развертку из папки Terraform.

Запуск развертки
```
./terraform apply
 ```
![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%200.5.png)

Проверка результата в Yandex Cloud:

1. Одна сеть bastion-network
2. Две подсети bastion-internal-segment и bastion-external-segment
3. Балансировщик alb-lb с роутером web-servers-router

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%202.png)

6 виртуальных машин

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%202.png)

6 групп безопасности

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%203.png) 

Ежедневные снимки дисков по расписанию

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%205.png)


# Ansible

Установка и настройка ansible

устанавливаем ansible на локальном хосте где работали с terraform и настраиваем его на работу через bastion

файл конфигурации

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%206.png)

создаем файл hosts.ini c использованием FQDN имен серверов вместо ip

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%207.png)

проверяем доступность ВМ используя модуль ping

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/пинг.png)

# Установка NGINX и загрузка сайта

ставим nginx

запускаем playbook установки Nginx с созданием web страницы

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%208.png)

проверяем доступность сайта в браузере по публичному ip адресу Load Balancer

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%209.png)

делаем запрос curl -v 

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%2010.png)

# Мониторинг

установка Zabbix сервера

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png11.png)

Проверка доступности frontend zabbix сервера

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%2012.png)

установка Zabbix агентов на web сервера

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%2013.png)

Добавляем хосты используя FQDN имена в zabbix сервер и настраиваем дашборды

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%2014.png)

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%2015.png)

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%2016.png)

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%2017.png)

# Установка стека ELK для сбора логов

Установка Elasticsearch

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%2018.png)

# Установка Kibana

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%2019.png)

проверяем что Kibana работает

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%2020.png)


# Установка Filebeat

Устанавливаем Filebeat на web сервера

![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%2021.png)

Проверяем в Kibana что Filebeat доставляет логи в Elasticsearch
![alt text](https://github.com/Daark46/-Diploma1/blob/main/Png/png%2022.png)

# Балансировщик [Балансировщик](http://84.252.132.245/)
# Zabbix [Логин: Almin Пароль: zabbix](http://158.160.81.219/zabbix/)
# Kibana [Kibana](http://158.160.66.160:5601/app/home#/)
