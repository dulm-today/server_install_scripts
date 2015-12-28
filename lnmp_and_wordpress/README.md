# server_install_scripts    
A serise of shell scripts used to install lnmp and wordpress    
    
usage:   
   git clone ...    
   su    
   chmod u+x lnmp.sh     
   ./lnmp.sh password_of_mysql password_of_wordpress     
    
info:    
  add group www, mysql    
  add user www.nginx  www.php  mysql.mysql    
  create database wordpress    
  update user set password=password('$password_of_mysql') where user = 'root'    
  grant all on wordpress.* to wordpress@localhost by identified by 'password_of_wordpress'    
  delete from user where user = ''    
  mysql_data_path: /home/mysql    
  wordpress_path: /home/www/blog    
