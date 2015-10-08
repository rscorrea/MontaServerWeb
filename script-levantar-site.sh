#!/bin/bash

<<COMMENT
	Desenvolvido por: Rafael Correa - ra.sa.correa@gmail.com

	Este script é para facilitar o processo de colocação de um site no ar clonando de um repositório.
	Vou adotar que o servidor web utiizado é o Nginx e que os sites foram desenvolvidos com Laravel.

	Será considerado que suas configurações básicas, como rede e conexão a internet, estão funcionando.
	As primeiras variáveis determinam pasta DOCROOT e o arquivo que servirá de modelo para o site.

	Forma de utilização:
		Baixe este script para sua pasta home. Ex: /home/`printenv LOGNAME`
		De permissão de execução para o script. Ex: chmod 755 ~/script-levantar-site.sh
		Execute o script. Ex: ~/script-levantar-site.sh
		Em alguns momentos o script precisará ter poderes de root. Para isso, informe sua senha de login quando for solicitado.
		Siga as instruções na tela.
COMMENT

# Variaveis para execução
USUARIO=`printenv LOGNAME`
USUARIO_WEB='www-data'
COMPOSER='/usr/local/bin/composer'
DOCROOT="/usr/share/nginx/"
ENV=$DOCROOT'/.env.modelo'
SITES_AVAILABLE="/etc/nginx/sites-available/"
SITES_ENABLED="/etc/nginx/sites-enabled/"
SITE_MODELO=$SITES_AVAILABLE'site-padrao'
#String do arquivo modelo que será substituida pelo site. SERVER_NAME
STRING_MODELO='@@@@@@'

test -e $DOCROOT || sudo install -m 755 -o $USUARIO_WEB -g $USUARIO_WEB -d $DOCROOT

if [ $# -ne 3 ];	then
	echo -e "UTILIZAÇÃO: ./script-levantar-site.sh \$REPOSITORIO \$SITE \$NOME_PASTA_DESTINO"
	exit 1
else
	cd $DOCROOT
	sudo -u $USUARIO_WEB git clone -q $1 $3 &> /dev/null
	if [ $? ]; then
		echo "Erro ao clonar o repositorio $1"
		exit 1
	else
		cd $3
		sudo -u $USUARIO_WEB cp $ENV ./.env
		sudo -u $USUARIO_WEB $COMPOSER -q install &>> ~/composer.log
		KEY=`sudo -u $USUARIO_WEB php artisan key:generate | sed 's/\[//g' | sed 's/\]//g' | awk '{ print $3 }'`
		sed -e 's/APP_KEY=YourSecretKeyGoesHere!/APP_KEY='$KEY'/' .env | sudo -u $USUARIO_WEB tee .env &> /dev/null
		cd $SITES_AVAILABLE
		sudo cp $SITE_MODELO $2
		DIR_TRATADO=$(echo -e $DOCROOT | sed 's/\//\\\//g')
		sed -e 's/root '$DIR_TRATADO';/root '$DIR_TRATADO'\/'$3';/' $2 | sudo tee $2 &> /dev/null
		sed -e 's/'$STRING_MODELO'/'$2'/' $2 | sudo tee $2 &> /dev/null
		sudo ln -s $SITES_AVAILABLE''$2 $SITES_ENABLED''$2
		echo "Verifique o arquivo .env criado. Ele precisa de mais algumas informações. Após isso, execute suas migrate"
		echo "Quase tudo OK. Voce ainda precisa dar reload no Nginx."
	fi
fi
