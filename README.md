# Infraestrutura e Serviços de TI — Persistência de Dados com Docker

## Introdução

A persistência de dados é um conceito fundamental em ambientes containerizados, pois permite que informações importantes sejam mantidas mesmo após a remoção ou recriação de containers.

Por padrão, containers são considerados efêmeros. Isso significa que eles podem ser criados, executados, parados e removidos rapidamente. Porém, quando os dados são armazenados apenas dentro do sistema de arquivos interno do container, eles podem ser perdidos ao remover esse container.

Para resolver esse problema, o Docker oferece mecanismos de persistência, como Docker Volumes e Bind Mounts. Os volumes permitem armazenar dados fora do ciclo de vida do container, sendo gerenciados pelo próprio Docker. Já os Bind Mounts permitem montar diretórios do sistema operacional host diretamente dentro do container.

Nesta atividade, o objetivo é compreender e validar, na prática, diferentes formas de persistência de dados utilizando Docker. A atividade também envolve backup, restauração, compartilhamento de volumes entre containers e automação básica por meio de scripts Bash.

---

## Ambiente Utilizado

- Sistema Operacional: Ubuntu Linux
- Docker Engine: Docker version 28.2.2, build 28.2.2-0ubuntu1~24.04.1
- Docker Compose Plugin: Docker Compose version v5.1.1
- Hardware:
  - Processador: 4 núcleos
  - Memória RAM: 6144 MB
  - Armazenamento utilizado: 25 GB

## Desenvolvimento da Atividade
### Cenario 1

Antes do início da atividade, foram executados os comandos obrigatórios para validar o ambiente:

```bash
sudo docker --version
sudo docker compose version
sudo docker run hello-world
```

![Verificações iniciais](screenshots/cenario1/verificacoes-iniciais.png)

---

Criar e validar o volume.

```bash
sudo docker volume create mysql-prod-data
sudo docker volume ls
sudo docker volume inspect mysql-prod-data
```

![Volume Criado](screenshots/cenario1/volume-criado.png)

Criar e Validar container MySQL com o volume.

```bash
sudo docker run -d \
  --name mysql-prod \
  -e MYSQL_ROOT_PASSWORD=root123 \
  -e MYSQL_DATABASE=infra_db \
  -v mysql-prod-data:/var/lib/mysql \
  -p 3306:3306 \
  mysql:8.0
```

```bash
sudo docker ps
sudo docker logs mysql-prod
```

![Container Mysql](screenshots/cenario1/container-mysql.png)

Copiar script para dentro do container:

```bash
sudo docker cp mysql-init.sql mysql-prod:/mysql-init.sql
```

Executar o script de criacao e insercao de dados:

```bash
sudo docker exec -i mysql-prod mysql -uroot -proot123 < mysql-init.sql
```

Validar os dados:

```bash
sudo docker exec -it mysql-prod mysql -uroot -proot123 -e "USE infra_db; SELECT * FROM usuarios;"
```

![Dados Inseridos](screenshots/cenario1/dados-inseridos.png)

Remover container:

```bash
sudo docker stop mysql-prod
sudo docker rm mysql-prod
```

Confimar container removido:

```bash
sudo docker ps -a
```

![Container Removido](screenshots/cenario1/container-removido.png)

Recriar container usando o mesmo volume.

```bash
sudo docker run -d \
  --name mysql-prod \
  -e MYSQL_ROOT_PASSWORD=root123 \
  -e MYSQL_DATABASE=infra_db \
  -v mysql-prod-data:/var/lib/mysql \
  -p 3306:3306 \
  mysql:8.0
```

Validar os dados:

```bash
sudo docker exec -it mysql-prod mysql -uroot -proot123 -e "USE infra_db; SELECT * FROM usuarios;"
```

![Dados Persistidos](screenshots/cenario1/dados-persistidos.png)

---

### Cenario 2

Criando backup fisico e no mysqldump

```bash
docker run --rm \
  -v mysql-prod-data:/volume \
  -v $(pwd)/backups:/backup \
  alpine \
  tar czf /backup/mysql-prod-data-backup.tar.gz -C /volume .
```
```bash
docker exec mysql-prod mysqldump -uroot -proot123 infra_db > backups/infra_db_dump.sql
```

![Criando backup](screenshots/cenario2/criando-backup.png)

Simulando perca de dados, removendo container e volume

```bash
docker stop mysql-prod
docker rm mysql-prod
docker volume rm mysql-prod-data
```

![Removendo container e volume](screenshots/cenario2/removendo-volume-container.png)

Criando container e volume vazio e fazendo backup fisico

```bash
docker volume create mysql-prod-data

docker run --rm \
  -v mysql-prod-data:/volume \
  -v $(pwd)/backups:/backup \
  alpine \
  sh -c "tar xzf /backup/mysql-prod-data-backup.tar.gz -C /volume"

docker run -d \
  --name mysql-prod \
  -e MYSQL_ROOT_PASSWORD=root123 \
  -v mysql-prod-data:/var/lib/mysql \
  -p 3306:3306 \
  mysql:8.0
```

Validar dados
```bash
docker exec -it mysql-prod mysql -uroot -proot123 -e "USE infra_db; SELECT * FROM usuarios;"
```

![Criando backup fisico](screenshots/cenario2/criando-backup-fisico.png)

Criando container e volume vazio e fazendo backup mysqldump

```bash
docker stop mysql-prod
docker rm mysql-prod
docker volume rm mysql-prod-data
docker volume create mysql-prod-data

docker run -d \
  --name mysql-prod \
  -e MYSQL_ROOT_PASSWORD=root123 \
  -e MYSQL_DATABASE=infra_db \
  -v mysql-prod-data:/var/lib/mysql \
  -p 3306:3306 \
  mysql:8.0

docker exec -i mysql-prod mysql -uroot -proot123 infra_db < backups/infra_db_dump.sql
```

Validar dados
```bash
docker exec -it mysql-prod mysql -uroot -proot123 -e "USE infra_db; SELECT * FROM usuarios;"
```

![Criando backup mysqldump](screenshots/cenario2/criando-backup-mysqldump.png)

---

### Cenario 3

criando arquivo pelo terminal fora do docker

```bash
mkdir -p docker/dev-files

echo "Arquivo criado no host Ubuntu" > docker/dev-files/arquivo-host.txt
```

![criando-arquivo.png](screenshots/cenario3/criando-arquivo.png)

Conectando em um containere e criando um arquivo dentro dele

```bash
docker run -it --rm \
  --name bind-dev \
  -v $(pwd)/docker/dev-files:/app \
  ubuntu:22.04 \
  bash

ls -la /app
cat /app/arquivo-host.txt
echo "Arquivo criado dentro do container" > /app/arquivo-container.txt
exit
```

![arquivo-container.png](screenshots/cenario3/arquivo-container.png)

Validando os arquivos criados dentro do container e local

```bash
ls -la docker/dev-files
cat docker/dev-files/arquivo-container.txt
```

![validacao-de-arquivo.png](screenshots/cenario3/validacao-de-arquivo.png)