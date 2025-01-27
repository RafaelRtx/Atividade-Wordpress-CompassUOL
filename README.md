# Atividade de Wordpress e Docker na AWS CompassUOL
## **Resumo do Projeto**
Este projeto consiste no deploy de uma aplicação Wordpress utilizando serviços da AWS, incluindo:
- **Docker** para gerenciar os containers.
- **RDS** para o banco de dados MySQL.
- **EFS** para armazenamento de arquivos estáticos do Wordpress.
- **Load Balancer (CLB)** para distribuir o tráfego.
- **Auto Scaling Group** para escalabilidade automática.

---

## **Arquitetura do Projeto**

![Arquitetura do Projeto](img/diagrama.png)

---

## **Passo-a-Passo**

### **1. Criar uma Instância EC2 com Docker via User Data**

#### **Script de User Data**
Configure o script abaixo para instalar e configurar Docker automaticamente na inicialização:

```bash
#!/bin/bash
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/2.17.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### **Etapas no Console AWS:**
1. Vá para o serviço **EC2** e clique em **Launch Instance**.
2. Escolha uma AMI (Amazon Linux 2).
3. Configure o tamanho da instância (e.g., `t2.micro`).
4. No campo “Advanced Details”, cole o script acima no campo **User Data**.
5. Finalize a criação da instância.

---

### **2. Criar Banco de Dados MySQL no RDS**
1. Acesse o serviço **RDS** no console AWS.
2. Clique em **Create Database** e configure:
   - **Engine:** MySQL.
   - **Instance Class:** `db.t2.micro`.
   - **DB Name:** `wordpress`.
   - **Username:** `admin`.
   - **Password:** `password`.
3. Configure as sub-redes e finalize a criação.
4. Copie o endpoint do banco de dados para usar na configuração do Wordpress.

---

### **3. Configurar o Docker Compose para Wordpress**

#### **Arquivo `docker-compose.yml`**
Na instância EC2, crie o arquivo `docker-compose.yml` com o seguinte conteúdo:

```yaml
version: '3.7'

services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: <RDS_ENDPOINT>
      WORDPRESS_DB_USER: <DB_USER>
      WORDPRESS_DB_PASSWORD: <DB_PASSWORD>
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wordpress_data:/var/www/html

volumes:
  wordpress_data:
    driver: local
```

Substitua os valores `<RDS_ENDPOINT>`, `<DB_USER>` e `<DB_PASSWORD>` com as informações do banco de dados.

#### **Executar o Docker Compose**
1. Suba o container com o comando:
   ```bash
   docker-compose up -d
   ```
2. Verifique se o container está rodando:
   ```bash
   docker ps
   ```

---

### **4. Configurar o EFS para Arquivos Estáticos**

#### **Configuração do EFS**
1. No console AWS, vá para **Elastic File System (EFS)** e clique em **Create File System**.
2. Configure permissões e sub-redes para permitir acesso à instância EC2.

#### **Montar o EFS na Instância EC2**
1. Instale os utilitários EFS:
   ```bash
   sudo yum install -y amazon-efs-utils
   ```
2. Monte o EFS:
   ```bash
   sudo mkdir -p /mnt/efs
   sudo mount -t efs <EFS_ID>:/ /mnt/efs
   ```

#### **Atualizar o `docker-compose.yml` para usar o EFS**

```yaml
volumes:
  wordpress_data:
    driver_opts:
      type: "nfs"
      o: "addr=<EFS_ENDPOINT>,rw"
      device: ":/"
```

Substitua `<EFS_ENDPOINT>` pelo endpoint do sistema de arquivos.

---

### **5. Configurar o Load Balancer**

1. Vá para **Load Balancers** no console AWS e clique em **Create Load Balancer**.
2. Escolha o **Classic Load Balancer**.
3. Configure o listener na porta 80 e adicione a instância EC2 ao target group.
4. Finalize a criação.

---

### **6. Configurar o Auto Scaling Group**

#### **Criar um Launch Template**
1. Vá para **Launch Templates** no console AWS e clique em **Create Launch Template**.
2. Configure:
   - **Name:** `wordpress-launch-template`.
   - **User Data:** Adicione o mesmo script `user_data.sh` para configurar Docker.

#### **Criar o Auto Scaling Group**
1. Vá para **Auto Scaling Groups** e clique em **Create Auto Scaling Group**.
2. Configure:
   - **Launch Template:** Selecione o template criado anteriormente.
   - **Desired Capacity:** 2.
   - **Minimum Capacity:** 1.
   - **Maximum Capacity:** 3.
3. Integre o grupo ao Load Balancer criado anteriormente.

---

### **7. Testar o Ambiente**
1. Acesse o DNS público do Load Balancer:
   ```
   http://<LOAD_BALANCER_DNS>
   ```
2. Complete a configuração inicial do Wordpress.
3. Verifique o Auto Scaling ajustando a carga na aplicação.

---

## **Comandos Úteis**

### **Verificar Containers Docker**
```bash
docker ps
```

### **Verificar Logs do Container**
```bash
docker logs wordpress
```

### **Testar Montagem do EFS**
```bash
ls /mnt/efs
```

---

## **Conclusão**
Este projeto integra serviços da AWS para criar um ambiente escalável e robusto para aplicações Wordpress. Certifique-se de monitorar o uso de recursos e ajustar as configurações conforme necessário para otimizar custos e desempenho.
