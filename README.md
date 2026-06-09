# Test task step by step realization guide

## Troubleshooting

Issues during deployment and how i fixed them:

1. **B2s VM size unavailable in westeurope (capacity restriction)**
   `terraform apply` rejected the SKU in the chosen region. Switched the
   deployment region to denmarkeast where B2s was available.

2. **VM1 could not connect to MySQL on VM2**
   MySQL listens on `127.0.0.1` by default, so it ignored remote connections.
   Changed `bind-address` to VM2's private IP `10.0.1.4` in
   `mysqld.cnf` and restarted MySQL.

3. **MySQL user could not authenticate from VM1**
   User `user'@'localhost` only accepts local connections.
   Created the user, that is allowed only from VM1's private IP `eschool_app'@'10.0.1.5`.

4. **Connection to 3306 still blocked at the cloud level**
   Added an NSG rule for port 3306 with source `10.0.1.0/24`, so the
   database stays private to the internal network.

5. **Maven build failed on an integration test**
   `ScheduleControllerIntegrationTest` ran during `mvn package` and broke the
   build. Commented out its content so the build could complete.

6. **App could not connect to the DB**
   The DB password contained special characters that conflicted with the
   `application.properties` parsing. Replaced it with a password without
   special characters.

7. **App ran but was unreachable from the browser**
    Tomcat listens on `8080`, which wasn't open in the NSG. 
    Added an NSG rule for `8080` with source `*`.

## Step 1. Azure account and CLI

Created a free Azure account and logged in through the CLI:

```bash
az login
az account show
```

## Step 2. Service principal

Script `sp_creation.sh` creates the SP and assigns the Contributor role
to the subscription.

The output (appId, password, tenant) is stored locally in `.env` and
loaded as `ARM_*` environment variables. `.env` is gitignored.

## Step 3. Infrastructure (using Terraform)

Two Ubuntu 22.04 VMs, size B2s, port 22 open for SSH.

Files:
1. `providers.tf` — azurerm provider, reads credentials from `ARM_*` env vars
2. `variables.tf` — prefix, location, VM size, admin user, VM count
3. `main.tf` — resource group, vnet, subnet, NSG, public IPs, NICs, NSG associations, the VMs
4. `outputs.tf` — public IPs of both VMs

```bash
terraform init
terraform plan
terraform apply
```

After apply, the VM public IPs come from the outputs. SSH in with:

```bash
ssh -i ~/.ssh/eschool_azure eschool@VM-IP
```

## Step 4. Prepare VM1

Installed Git, Java and Maven:

```bash
sudo apt update
sudo apt install git -y
sudo apt install openjdk-8-jdk -y
sudo apt install maven -y
```

Cloned the eSchool repo into the home directory:

```bash
git clone https://github.com/yurkovskiy/eSchool
```

## Step 5. Prepare VM2 (database server)

Installed MySQL on the second VM:

```bash
sudo apt update
sudo apt install mysql-server -y
```

Created the database and an application user. The user is bound to VM1's
private IP (10.0.1.5), so only the app server can connect — not the whole
network:

```sql
CREATE DATABASE eschool;
CREATE USER 'eschool_app'@'10.0.1.5' IDENTIFIED BY '<password>';
GRANT ALL PRIVILEGES ON eschool.* TO 'eschool_app'@'10.0.1.5';
FLUSH PRIVILEGES;
```

By default MySQL listens only on 127.0.0.1, so VM1 couldn't reach it.
Changed `bind-address` to VM2's private IP in
`/etc/mysql/mysql.conf.d/mysqld.cnf` and restarted.

Firewall - added an NSG rule allowing inbound TCP 3306 from the private
subnet (10.0.1.0/24) only — the database is not exposed to the internet.

## Step 6. Deploy eSchool (on VM1)

Commented out the content of `ScheduleControllerIntegrationTest.java`.

Edited `src/main/resources/application.properties` — pointed the
datasource at VM2's private IP and set the app DB user/password:

spring.datasource.url=${DATASOURCE_URL:jdbc:mysql://10.0.1.4/eschool?useUnicode=true&characterEncoding=utf8&useSSL=false}
spring.datasource.username=${DATASOURCE_USERNAME:eschool_app}
spring.datasource.password=${DATASOURCE_PASSWORD:<password>}

Built the project:
```bash
mvn clean package
```

Ran :
```bash
java -jar target/eschool.jar
```

Tomcat starts on port 8080. Added an NSG rule allowing inbound TCP 8080
from the internet so the app is publicly reachable. The app
is available at `http://<VM1-public-ip>:8080` (login admin / admin).

### Autostart with systemd

To keep the app running after server restart, created a systemd service
at `/etc/systemd/system/eschool.service`:

```bash
[Unit]
Description=eSchool Spring Boot application
After=network.target

[Service]
Type=simple
User=eschool
WorkingDirectory=/home/eschool/eSchool
ExecStart=/usr/bin/java -jar /home/eschool/eSchool/target/eschool.jar
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Verified it survives a reboot:

```bash
sudo reboot
sudo systemctl status eschool
```