echo "reload cnf "
sh /docker-entrypoint.sh
maxadmin -pmariadb reload config
~                                     
