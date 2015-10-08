#!/bin/bash

USUARIO='peduser'
SENHA='S3nh4PR4t40c4r'
USUARIO_WEB='www-data'
DOCROOT="/usr/share/nginx/html"

# Atualizando o servidor
sudo apt-get update && sudo apt-get -qy upgrade

# Instalando os principais servicos
sudo apt-get -qy install nginx-full php5-fpm php5-cli php5-mcrypt git mysql-server php5-mysql php5-curl php5-imagick php5-intl php5-memcache php-pear php5-dev php5-xdebug mcrypt phpmyadmin curl nano
# Ira pedir a senha do root para o MySQL - Fornecer a senha e salva-la
sudo mysql_install_db
sudo mysql_secure_installation
# 1 - Ira pedir a senha do root
# 2 - Perguntar se quer alterar. N~ao vejo sentido, visto que acabou de setar ela. Responder n
# 3 - Pede para remover o acesso Anonimo ao MySQL. Responder Y
# 4 - Pede para bloquear o acesso utilizando a conta root. Responder Y
# 5 - Pede para bloquear o acesso utilizando a conta root. Responder Y
# 6 - Pede para remover o banco de teste e o acesso a ele. Responder Y
# 7 - Pede para dar um reload nas permissoes do MySQL. Responder Y

# Cria um usuario para o mysql. Assim n~ao precisamos usar o root
# Vai pedir a senha do root do MySql
echo "Digite a senha do root do MySQL"
mysql -uroot -p -e "GRANT ALL ON *.* TO '"$USUARIO"'@'localhost' IDENTIFIED BY '"$SENHA"';"

# Otimizando o servidor nginx
# antes vamos fazer um backup do arquivo original
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.original
# Agora ja podemos apagar o arquivo
sudo rm -f /etc/nginx/nginx.conf
# Verifica o num de processadores da maquina
NUM_PROC=`grep ^processor /proc/cpuinfo | wc -l`
((WORKER_PROCESS = $NUM_PROC * 1024))

# Ajusta configucaç~oes no arquivo /etc/php5/fpm/pool.d/www.conf
sed -e 's/pm = dynamic/pm = ondemand/' /etc/php5/fpm/pool.d/www.conf | sudo tee /etc/php5/fpm/pool.d/www.conf &> /dev/null
sed -e 's/pm.max_children = 5/pm.max_children = 20/' /etc/php5/fpm/pool.d/www.conf | sudo tee /etc/php5/fpm/pool.d/www.conf &> /dev/null
sed -e 's/;catch_workers_output = yes/catch_workers_output = yes/' /etc/php5/fpm/pool.d/www.conf | sudo tee /etc/php5/fpm/pool.d/www.conf &> /dev/null
sed -e 's/listen = \/var\/run\/php5-fpm.sock/listen = \/var\/run\/php5-fpm\/php5-fpm.sock/' /etc/php5/fpm/pool.d/www.conf | sudo tee /etc/php5/fpm/pool.d/www.conf &> /dev/null

# Ajusta configucaç~oes no arquivo /etc/php5/fpm/php.ini
sed -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php5/fpm/php.ini | sudo tee /etc/php5/fpm/php.ini &> /dev/null

# Ajusta configucaç~oes no arquivo /etc/php5/fpm/php-fpm.conf
sed -e 's/;log_level = notice/log_level = warning/' /etc/php5/fpm/php-fpm.conf | sudo tee /etc/php5/fpm/php-fpm.conf &> /dev/null
sed -e 's/;emergency_restart_threshold = 0/emergency_restart_threshold = 10/' /etc/php5/fpm/php-fpm.conf | sudo tee /etc/php5/fpm/php-fpm.conf &> /dev/null
sed -e 's/;emergency_restart_interval = 0/emergency_restart_interval = 1m/' /etc/php5/fpm/php-fpm.conf | sudo tee /etc/php5/fpm/php-fpm.conf &> /dev/null
sed -e 's/;process_control_timeout = 0/process_control_timeout = 10s/' /etc/php5/fpm/php-fpm.conf | sudo tee /etc/php5/fpm/php-fpm.conf &> /dev/null

# Cria pastas para o socket e para o cahce
test -e /var/run/php5-fpm || sudo install -m 755 -o $USUARIO_WEB -g $USUARIO_WEB -d /var/run/php5-fpm
test -e /var/cache/nginx || sudo install -m 755 -o $USUARIO_WEB -g $USUARIO_WEB -d /var/cache/nginx

# Vamos colocar esta pasta /var/run/php5-fpm para ser persistente ao boot
TEXTO='# php5-fpm - The PHP FastCGI Process Manager\n
\n
start on runlevel [2345]\n
stop on runlevel [016]\n
\n
pre-start script\n
\ttest -e /var/run/php5-fpm || install -m 755 -o '$USUARIO_WEB' -g '$USUARIO_WEB' -d /var/run/php5-fpm\n
\t/usr/lib/php5/php5-fpm-checkconf\n
end script\n
\n
respawn\n
exec /usr/sbin/php5-fpm --nodaemonize --fpm-config /etc/php5/fpm/php-fpm.conf'

echo -e $TEXTO | sudo tee /etc/init/php5-fpm.conf &> /dev/null

# Cria o arquivo de configuraç~ao do Nginx

TEXTO='user '$USUARIO_WEB';\n
worker_processes  '$NUM_PROC';\n
pid /run/nginx.pid;\n
\n
events {\n
\tworker_connections  '$WORKER_PROCESS';\n
\tmulti_accept on;\n
}\n
\n
worker_rlimit_nofile 40000;\n
\n
http {\n
\tinclude\t/etc/nginx/mime.types;\n
\tdefault_type\tapplication/octet-stream;\n
\n
\terror_log /var/log/nginx/error.log error;\n
\taccess_log /var/log/nginx/access.log;\n
\n
\tclient_body_timeout\t3m;\n
\tclient_header_buffer_size\t1k;\n
\tclient_body_buffer_size\t16K;\n
\tclient_max_body_size\t32m;\n
\tlarge_client_header_buffers\t4 4k;\n
\tsend_timeout\t3m;\n
\n
\tgzip\ton;\n
\tgzip_static on;\n
\tgzip_disable "msie6";\n
\tgzip_http_version 1.1;\n
\tgzip_vary on;\n
\tgzip_comp_level\t3;\n
\tgzip_min_length\t1024;\n
\tgzip_proxied\texpired no-cache no-store private auth;\n
\tgzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript text/x-js;\n
\tgzip_buffers\t16 8k;\n
\n
\toutput_buffers\t1 32k;\n
\tpostpone_output\t1460;\n
\tsendfile\ton;\n
\ttcp_nopush\ton;\n
\ttcp_nodelay\ton;\n
\tkeepalive_timeout\t75 20;\n
\ttypes_hash_max_size\t2048;\n
\tserver_tokens\toff;\n
\n
\tfastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=microcache:10m max_size=1000m inactive=60m;\n
\n
\tinclude /etc/nginx/conf.d/*.conf;\n
\tinclude /etc/nginx/sites-enabled/*;\n
}'

echo -e $TEXTO | sudo tee /etc/nginx/nginx.conf &> /dev/null

# Cria o arquivo de configuraç~ao do site padrao - Deve servir de modelo para todos os outros sites
# Alterar no arquivo @@@@@@ para o nome do site
# Tambem configura o acesso para o phpmyadmin para o pasta /adminmysql neste servidor

TEXTO='server {\n
\tlisten 80;\n
\tlisten [::]:80 ipv6only=on;\n
\n
\tserver_name     @@@@@@;\n
\n
\troot '$DOCROOT';\n
\tindex index.php index.html index.htm;\n
\n
\terror_log /var/log/nginx/error.log error;\n
\taccess_log /var/log/nginx/access.log;\n
\n
\tlocation / {\n
\t\ttry_files $uri $uri/ /index.php?$query_string;\n
\t}\n
\n
\tlocation ~* \.(jpg|jpeg|gif|png|ico|xml)$ {\n
\t\taccess_log      off;\n
\t\tlog_not_found   off;\n
\t\texpires\t 30d;\n
\t}\n
\n
\tlocation ~ .php$ {\n
\n
\t\tset $no_cache "";\n
\t\tif ($request_method !~ ^(GET|HEAD)$) {\n
\t\t    set $no_cache "1";\n
\t\t}\n
\t\tif ($no_cache = "1") {\n
\t\t\tadd_header Set-Cookie "_mcnc=1; Max-Age=2; Path=/";\n
\t\t\tadd_header X-Microcachable "0";\n
\t\t}\n
\t\tif ($http_cookie ~* "_mcnc") {\n
\t\t\tset $no_cache "1";\n
\t\t}\n
\t\tfastcgi_no_cache $no_cache;\n
\t\tfastcgi_cache_bypass $no_cache;\n
\t\tfastcgi_cache microcache;\n
\t\tfastcgi_cache_key $scheme$host$request_uri$request_method;\n
\t\tfastcgi_cache_valid 200 301 302 10m;\n
\t\tfastcgi_cache_use_stale updating error timeout invalid_header http_500;\n
\t\tfastcgi_pass_header Set-Cookie;\n
\t\tfastcgi_pass_header Cookie;\n
\t\tfastcgi_ignore_headers Cache-Control Expires Set-Cookie;\n
\n
\t\tfastcgi_pass unix:/var/run/php5-fpm/php5-fpm.sock;\n
\t\tfastcgi_split_path_info ^(.+\.php)(/.+)$;\n
\t\tfastcgi_index index.php;\n
\n
\t\tfastcgi_param   SCRIPT_FILENAME $document_root$fastcgi_script_name;\n
\t\tfastcgi_param   SCRIPT_NAME     $fastcgi_script_name;\n
\n
\t\tfastcgi_buffer_size     128k;\n
\t\tfastcgi_buffers         256     16k;\n
\t\tfastcgi_busy_buffers_size       256k;\n
\t\tfastcgi_temp_file_write_size    256k;\n
\t\tfastcgi_read_timeout 240;\n
\n
\t\tinclude fastcgi_params;\n
\t}\n
\tlocation /adminmysql {\n
\n
\t\talias /usr/share/phpmyadmin;\n
\n
\t\tindex index.php;\n
\n
\t\tlocation ~* ^.+.(jpg|jpeg|gif|css|png|js|ico|xml)$ {\n
\t\t\taccess_log        off;\n
\t\t\texpires           360d;\n
\t\t}\n
\n
\t\tlocation ~ /\.ht {\n
\t\t\tdeny  all;\n
\t\t}\n
\n
\t\tlocation ~ /(libraries|setup/frames|setup/libs) {\n
\t\t\tdeny all;\n
\t\t\treturn 404;\n
\t\t}\n
\n
\t\tlocation ~ \.php$ {\n
\t\t\tfastcgi_pass unix:/var/run/php5-fpm/php5-fpm.sock;\n
\t\t\tfastcgi_index index.php;\n
\t\t\tfastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\n
\t\t\tinclude /etc/nginx/fastcgi_params;\n
\t\t}\n
\t}\n
}'

echo -e $TEXTO | sudo tee /etc/nginx/sites-available/site-padrao &> /dev/null

# Criando arquivo modelo para os sites de projetos
sudo ln -s /etc/nginx/sites-available/site-padrao /etc/nginx/sites-enabled/site-padrao
# Removendo o arquivo instalado por padrao
sudo rm -f /etc/nginx/sites-enabled/default
# Habilitando o modulo MCrypt
sudo php5enmod mcrypt && sudo service php5-fpm restart

# Instalando o Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Download do TS Server para Linux 64
cd ~ && wget -crnd http://dl.4players.de/ts/releases/3.0.11.4/teamspeak3-server_linux-amd64-3.0.11.4.tar.gz
# Adiciona o usuario que vai executar o TeamSpeak
sudo useradd -M -r -s /usr/sbin/nologin teamspeak
# Descompactando a pasta em /opt
sudo tar -zxf teamspeak3-server_linux-amd64-3.0.11.4.tar.gz -C /opt
# Renomeando para apenas teamspeak
sudo mv /opt/teamspeak3-server_linux-amd64 /opt/teamspeak
# Configurando o dono da pasta owner = teamspeak
sudo chown -R teamspeak.teamspeak /opt/teamspeak
# Criando o link para o script de inicializaçao do server
sudo ln -s /opt/teamspeak/ts3server_startscript.sh /etc/init.d/teamspeak
# Colocando para iniciar no boot
sudo update-rc.d teamspeak defaults
# Iniciando o server e salvando a senha ADM no arquivo teamspeak.txt - Importante salver este arquivo em algum lugar seguro
sudo service teamspeak start &> ~/teamspeak.txt

#
# # Instalando servidor SSH
sudo apt-get install -qy openssh-server
# # Fazendo backup do arquivo de configuraçao original
sudo mv /etc/ssh/sshd_config /etc/ssh/sshd_config.original
#
# # Configurando o SSH Server
TEXTO='Port 22\n
PermitRootLogin no\n
PermitEmptyPasswords no\n
Protocol 2\n
\n
HostKey /etc/ssh/ssh_host_rsa_key\n
HostKey /etc/ssh/ssh_host_dsa_key\n
HostKey /etc/ssh/ssh_host_ecdsa_key\n
HostKey /etc/ssh/ssh_host_ed25519_key\n
\n
UsePrivilegeSeparation yes\n
\n
KeyRegenerationInterval 3600\n
ServerKeyBits 1024\n
\n
SyslogFacility AUTH\n
LogLevel INFO\n
\n
Banner none\n
PrintLastLog yes\n
# AllowGroups ssh\n
LoginGraceTime 120\n
StrictModes yes\n
\n
RSAAuthentication yes\n
PubkeyAuthentication yes\n
AuthorizedKeysFile %h/.ssh/authorized_keys\n
\n
IgnoreRHosts yes\n
RhostsRSAAuthentication no\n
HostbasedAuthentication no\n
IgnoreUserKnownHosts no\n
\n
ChallengeResponseAuthentication no\n
X11Forwarding yes\n
X11DisplayOffset 10\n
PrintMotd no\n
TCPKeepAlive yes\n
AcceptEnv LANG LC_*\n
\n
Subsystem sftp /usr/lib/openssh/sftp-server\n
\n
UsePAM yes\n'

echo -e $TEXTO | sudo tee /etc/ssh/sshd_config &> /dev/null
# Isso deve ser feito manualmente. Vai que você está conectado via ssh?
# sudo service ssh restart

# # Instalando servidor Git - Gogs - http://gogs.io/docs/installation/install_from_packages.html
wget -qO - https://deb.packager.io/key | sudo apt-key add -
echo "deb https://deb.packager.io/gh/pkgr/gogs trusty pkgr" | sudo tee /etc/apt/sources.list.d/gogs.list
sudo apt-get update
sudo apt-get -qy install gogs

# # Alterar no arquivo @@@@@@ para o nome do site adequado

TEXTO='server {\n
\tlisten\t\t80;\n
\tserver_name\t@@@@@@;\n
\n
\tlocation / {\n
\t\tproxy_pass	http://localhost:3000;\n
\t}\n
}'

echo -e $TEXTO | sudo tee /etc/nginx/sites-available/gogs &> /dev/null

# # Habilitando o site
sudo ln -s /etc/nginx/sites-available/gogs /etc/nginx/sites-enabled/gogs
# # Criando a base de dados Gogs - Vai pedir a senha do root do MySql
echo "Digite a senha do root do MySQL"
mysql -uroot -p -e "create database if not exists gogs"

#
# # Vamos aumentar a segurança do servidor
# # Criando usuario para manutencao - NAO VAMOS USAR O ROOT
# # Nome do usuario = 
echo "Vamos criar o usuário $USUARIO"
sudo useradd -G www-data,sudo,adm,ssh -s /bin/bash -m $USUARIO
# # Vamos definir uma senha para ele
echo "Agora digite a senha deste usuário."
sudo passwd $USUARIO

# Cria o arquivo .env.modelo para ser usado por qualquer projeto laravel
TEXTO='APP_ENV=local\n
APP_DEBUG=false\n
APP_KEY=YourSecretKeyGoesHere!\n
\n
DB_HOST=localhost\n
DB_DATABASE=\n
DB_USERNAME='$USUARIO'\n
DB_PASSWORD='$SENHA'\n
\n
CACHE_DRIVER=file\n
SESSION_DRIVER=file\n
QUEUE_DRIVER=sync\n
\n
MAIL_DRIVER=smtp\n
MAIL_HOST=smtp.mailgun.org\n
MAIL_PORT=587\n
MAIL_USERNAME=\n
MAIL_PASSWORD=\n
MAIL_TO=\n'
echo -e $TEXTO | sudo tee /usr/share/nginx/.env.modelo &> /dev/null

# Instalar o gitstats para retirar relatorios do GIT
sudo apt-get install gnuplot-nox
cd /opt
sudo git clone git://github.com/hoxu/gitstats.git
#
# # Inserir algumas configuracoes para firewall e proteçao de ataques
# echo -e '\nnet.ipv4.conf.all.accept_redirects = 0\n' | sudo tee -a /etc/sysctl.conf &> /dev/null
