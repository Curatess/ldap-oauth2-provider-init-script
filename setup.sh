#!/bin/sh

# WELCOME
echo ''
echo "This is the setup script for the LDAP/Active Directory OAuth2 Provider. Press enter to continue..."; read dummypause;
echo "This script will have you enter some settings, and then download and start up a Docker container running the OAuth2 Provider."; read dummypause;
echo "Before we start you'll need to do three things..."; read dummypause;
echo ''
echo "1) Install git (apt-get install git)"; read dummypause;
echo ''
echo "2) Download and install Docker Engine"; read dummypause;
echo ''
echo "3) Download and install Docker Compose (https://docs.docker.com/engine/installation/)."; read dummypause;
echo ''
echo "If you've got Docker Engine and Docker Compose installed, let's configure a few settings. See the README for more information on these settings."; read dummypause;


# LDAP SETTINGS
echo "Enter the Hostname or IP address for your LDAP server (Ex: subdomain.domain.domain)."
read -p "Hostname: " host_name
echo ''
echo "Enter the common name (CN) of the group on your LDAP server for this application to search through for users (Ex: OAuth)."
read -p "Group CN: " cn
echo ''
echo "Enter the dummy account Active Directory distinguishedName (Ex: CN=Joe Schmo,OU=DummyAccounts,DC=corp,DC=com)."
read -p "distinguishedName: " ldap_username

enter_password()
{
  ldap_password='pass'
  ldap_password_confirmation='word'
  while [ $ldap_password != $ldap_password_confirmation ]
  do
    echo ''
    echo "Enter the user's corresponding password."
    stty -echo
    read -p "Password: " ldap_password
    stty echo
    echo ''
    echo "Type the password again to confirm:"
    echo ''
    stty -echo
    read -p "Password Confirm: " ldap_password_confirmation
    stty echo

    if [ $ldap_password != $ldap_password_confirmation ]
    then
      echo ''
      echo "The passwords don't match, please enter again"
    fi

  done
}

enter_password


# SSL SETTINGS
echo ''
echo "That's all for the LDAP settings. Let's move on to SSL settings..."; read dummypause;
echo "Enter an admin email address--used to obtain an SSL certificate with Let's Encrypt."
read -p "Email Address: " admin_email
echo ''
echo "Enter the domain name associated with the server running this OAuth2 Provider The SSL certificate will verify this domain."
read -p "Domain name: " domain_name


# JWT SETTING
echo ''
echo "Next, enter the JSON Web Token secret."
read -p "JWT Secret: " jwt_secret



# WRITE SETTINGS TO FILE
sudo mkdir -p /var/ldap-oauth2-provider-settings/cert
sudo chmod 777 /var/ldap-oauth2-provider-settings
sudo chmod 777 /var/ldap-oauth2-provider-settings/cert

if [ ! -e /var/ldap-oauth2-provider-settings/settings.yml ]
then
sudo touch /var/ldap-oauth2-provider-settings/settings.yml
fi

if [ ! -e /var/ldap-oauth2-provider-settings/cert/privkey.pem ]
then
sudo touch /var/ldap-oauth2-provider-settings/cert/privkey.pem
fi

if [ ! -e /var/ldap-oauth2-provider-settings/cert/cert.pem ]
then
sudo touch /var/ldap-oauth2-provider-settings/cert/cert.pem
fi

if [ ! -e /var/ldap-oauth2-provider-settings/cert/chain.pem ]
then
sudo touch /var/ldap-oauth2-provider-settings/cert/chain.pem
fi

if [ ! -e /var/ldap-oauth2-provider-settings/cert/fullchain.pem ]
then
sudo touch /var/ldap-oauth2-provider-settings/cert/fullchain.pem
fi


sudo chmod 777 /var/ldap-oauth2-provider-settings/settings.yml
sudo chmod 777 /var/ldap-oauth2-provider-settings/cert/privkey.pem
sudo chmod 777 /var/ldap-oauth2-provider-settings/cert/cert.pem
sudo chmod 777 /var/ldap-oauth2-provider-settings/cert/chain.pem
sudo chmod 777 /var/ldap-oauth2-provider-settings/cert/fullchain.pem




# OVERWRITE PLACEHOLDER PATH IN LDAP-OAuth2-Provider
init_script_path=`pwd`
escaped_path=$(printf '%s\n' $init_script_path | sudo sed 's:[\/&]:\\&:g;$!s/$/\\/')
sudo sed -i.bu "s/placeholder_init_path/$escaped_path/g" LDAP-OAuth2-Provider

## SET UP INIT SCRIPT
sudo mkdir -p /etc/init.d && sudo cp "LDAP-OAuth2-Provider" "/etc/init.d/LDAP-OAuth2-Provider"
sudo chmod 755 /etc/init.d/LDAP-OAuth2-Provider
sudo update-rc.d LDAP-OAuth2-Provider defaults
sudo chmod 755 docker-compose-init
sudo chmod 755 write-init-process-to-log

volume_mount_path='/var/ldap-oauth2-provider-settings'


write_settings ()
{
  sudo echo "ldap_settings:" > /var/ldap-oauth2-provider-settings/settings.yml
  sudo echo "  ldap_hostname: $host_name" >> /var/ldap-oauth2-provider-settings/settings.yml
  sudo echo "  ldap_group_cn: $cn" >> /var/ldap-oauth2-provider-settings/settings.yml
  sudo echo "  ldap_username: $ldap_username" >> /var/ldap-oauth2-provider-settings/settings.yml
  sudo echo "  ldap_password: $ldap_password" >> /var/ldap-oauth2-provider-settings/settings.yml
  sudo echo "  ssl_email: $admin_email" >> /var/ldap-oauth2-provider-settings/settings.yml
  sudo echo "  ssl_domain: $domain_name" >> /var/ldap-oauth2-provider-settings/settings.yml
  sudo echo "  jwt_secret: $jwt_secret" >> /var/ldap-oauth2-provider-settings/settings.yml
}



# EXIT AND RUN SCRIPT
yes_answer ()
{

  # STORE VOLUME MOUNT PATH IN ENV FILE
  sudo touch .env
  sudo chmod 777 .env
  sudo echo "VOLUMEMOUNTPATH=$volume_mount_path" > .env
  sudo echo "SSLDOMAIN=$domain_name" >> .env
  sudo echo "SECRET_KEY_BASE=`openssl rand -base64 32`" >> .env

  write_settings

  echo ''
  echo "Next, Docker will build the container and run the application. Press enter to continue with the installation. It may take several minutes."; read dummypause;
  sudo touch /var/log/LDAP-OAuth2-Provider.log
  sudo chmod 777 /var/log/LDAP-OAuth2-Provider.log
  sudo docker-compose build
  return 0
}



no_answer ()
{
  echo ''
  echo "Change a setting by typing its number"
  echo "1 - Hostname: $host_name"
  echo "2 - LDAP Group CN: $cn"
  echo "3 - LDAP DN: $ldap_username"
  echo "4 - SSL Email Address: $admin_email"
  echo "5 - SSL Domain: $domain_name"
  echo "6 - JWT Secret: $jwt_secret"

  echo ''
  read -p "Setting number: " setting_choice

  echo ''
  echo "What would you like to set #$setting_choice to?"

  echo ''
  read -p "New value: " new_setting
  case $setting_choice in
    1)
    host_name=$new_setting
    ;;
    2)
    cn=$new_setting
    ;;
    3)
    ldap_username=$new_setting
    ;;
    4)
    admin_email=$new_setting
    ;;
    5)
    domain_name=$new_setting
    ;;
    6)
    jwt_secret=$new_setting
    ;;
  esac
  write_settings
  settings_confirmation
}



settings_confirmation ()
{
    while true; do
        echo ''
        grep -v '^  ldap_password' /var/ldap-oauth2-provider-settings/settings.yml
        echo ''
        echo "Are these settings correct? [y/n]"
        read -p "$* [y/n]: " yn
        case $yn in
            [Yy]*) yes_answer && return 0;;
            [Nn]*) no_answer && return 0;;
        esac
    done
}



write_settings

## CHECK SETTINGS
echo ''
echo "These are your settings."

settings_confirmation
