#!/bin/bash

# Atualiza o sistema
echo "Atualizando o sistema..."
sudo apt update && sudo apt upgrade -y

# Instala dependências do sistema
echo "Instalando dependências..."
sudo apt install -y git curl build-essential

# Instala o MariaDB
echo "Instalando o MariaDB..."
sudo apt install -y mariadb-server
sudo mysql_secure_installation

# Configura o MariaDB
echo "Configurando o MariaDB..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS agenda_whatsapp;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'agenda_user'@'localhost' IDENTIFIED BY 'senha_segura';"
sudo mysql -e "GRANT ALL PRIVILEGES ON agenda_whatsapp.* TO 'agenda_user'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Cria as tabelas
echo "Criando tabelas..."
sudo mysql -e "USE agenda_whatsapp; CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    perfil ENUM('admin', 'supervisor', 'usuario') DEFAULT 'usuario',
    ativo BOOLEAN DEFAULT TRUE,
    nome_completo VARCHAR(100),
    telefone VARCHAR(20),
    endereco TEXT,
    foto_perfil VARCHAR(255),
    verification_token VARCHAR(100),
    email_verified BOOLEAN DEFAULT FALSE
);"

sudo mysql -e "USE agenda_whatsapp; CREATE TABLE IF NOT EXISTS faturas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    arquivo VARCHAR(255) NOT NULL,
    data_upload DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES usuarios(id)
);"

sudo mysql -e "USE agenda_whatsapp; CREATE TABLE IF NOT EXISTS codigos_verificacao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    codigo VARCHAR(6) NOT NULL,
    expiracao DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES usuarios(id)
);"

# Instala o Node.js
echo "Instalando o Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Instala o PM2
echo "Instalando o PM2..."
sudo npm install -g pm2

# Instala o Nginx
echo "Instalando o Nginx..."
sudo apt install -y nginx

# Configura o Nginx
echo "Configurando o Nginx..."
sudo bash -c 'cat > /etc/nginx/sites-available/agenda-whatsapp <<EOL
server {
    listen 80;
    server_name seu-dominio.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL'

# Habilita o site no Nginx
sudo ln -s /etc/nginx/sites-available/agenda-whatsapp /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Instala o Certbot (HTTPS)
echo "Instalando o Certbot..."
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d seu-dominio.com --non-interactive --agree-tos -m seu-email@dominio.com

# Clona o repositório do projeto
echo "Clonando o repositório..."
git clone https://github.com/seu-usuario/agenda-whatsapp.git
cd agenda-whatsapp

# Instala dependências do projeto
echo "Instalando dependências do projeto..."
npm install

# Cria a pasta de uploads
mkdir -p public/uploads

# Configura o arquivo .env
echo "Configurando o arquivo .env..."
cat <<EOL > .env
DB_HOST=localhost
DB_USER=agenda_user
DB_PASSWORD=senha_segura
DB_DATABASE=agenda_whatsapp
SMTP_HOST=smtp.seu-servidor.com
SMTP_PORT=587
SMTP_USER=seu-email@dominio.com
SMTP_PASSWORD=sua-senha
EVOLUTION_API_URL=https://api.evolution-api.com
EVOLUTION_API_TOKEN=seu_token_aqui
EVOLUTION_INSTANCE_NAME=sua_instancia_aqui
EOL

# Inicia o servidor com PM2
echo "Iniciando o servidor com PM2..."
pm2 start server.js --name "agenda-whatsapp"
pm2 startup
pm2 save

echo "Deploy concluído! Acesse http://seu-dominio.com"