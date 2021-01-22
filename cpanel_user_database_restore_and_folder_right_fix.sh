#!/bin/bash
HOME_DIR='/home/'
DATABASE_DIR='/var/lib/mysql/'
USER=$1

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White
NC='\033[0m'              # No Color

if [ "${EUID}" -ne 0 ]
  then printf "${Red}[ERROR]${NC} Must be run as root\n"
  exit 1
fi

if [ -z "${USER}" ];then
printf "${Blue}[Usage]${NC} $0 <CpanelUsername>\n"
exit 0
fi

if [ ! -d "$HOME_DIR$USER" ];then
printf "${Red}[ERROR]${NC} USER $USER not exists or incorrect home directory ($HOME_DIR)\n"
exit 1
fi


database_fix(){

  for database in $databases_list
  do
  printf "${Yellow}[RESORATION]${NC} ${database}..."

  mysqldump ${database} > ${database}.sql 

  mysqadmin drop ${database} -f > /dev/null

  # https://www.basezap.com/create-databases-and-users-command-line-whm-server/
  # add databases with the same names using cpanel API
  uapi --user=${USER} Mysql create_database name=${database}

  mysql ${databases} < ${database}.sql 

  rm -f ${database}.sql

  printf "${Green}[DONE]${NC}\n"
  done
}

rights_fix() {

  printf "${Green}[DONE]${NC} Databases was restored\n"
  printf "${Yellow}[ACTION]${NC} starting rights restoration\n"
  printf "${Yellow}[ACTION]${NC} chmod restoration..."
  cd ${HOME_DIR}${USER}
  find . -type d -exec chmod 755 {} \;
  find . -type f -exec chmod 644 {} \; 
  printf "${Green}[DONE]${NC}\n"
  printf "${Yellow}[ACTION]${NC} chown restoration..."
  chown -R ${USER}: ./ ; chown .nobody .htpasswds/ ; chown .nobody public_html/ ; chown .mail etc/
  chmod 750 public_html
  cd - > /dev/null
  printf "${Green}[DONE]${NC}\n"

}



command_list=" find mysqldump uapi"
error_flag=0
for command_name in ${command_list}
do
if command -v ${command_name} &> /dev/null
then
  printf "${Green}[COMMAND]${NC} ${command_name}.... ok\n"
else
  printf "${Red}[COMMAND]${NC} ${command_name}.... not found\n"
  error_flag=1
fi
done

if [ ${error_flag} -eq 1 ]; then
printf "${Red}[ERROR]${NC} Something missing. Please install missing tools\n"
exit 1
fi

databases_list=$(find $DATABASE_DIR -name "${USER}_*" -printf "%f\n") # find all user DB`s
if [ ! -z "${databases_list}" ];then
  printf "${Blue}[INFO]${NC} Databases:\n"
  printf "${databases_list}\n"
  printf "${Purple}[QUESTION]${NC} Was found for user ${USER}. Restore it? YES/NO\n"
  while [ 1 ]
  do
    read USER_ANSWER
    if [[ $USER_ANSWER = 'NO' || $USER_ANSWER = 'no' || $USER_ANSWER = 'n' ]]; then
        printf "[EXIT] Nothing to do.\n"
        break
    elif [[ $USER_ANSWER = 'YES' || $USER_ANSWER = 'yes' || $USER_ANSWER = 'y' ]]; then
        database_fix
        break
    else
        printf "${Red}[BAD INPUT]${NC} Type only YES or NO\n"
    fi
  done
else
  printf "${Blue}[INFO]${NC} databases for ${USER} was not found\n"
fi



printf "${Purple}[QUESTION]${NC} Do fix right for ${USER} ? YES/NO\n"
while [ 1 ]
do
  read USER_ANSWER
  if [[ $USER_ANSWER = 'NO' || $USER_ANSWER = 'no' || $USER_ANSWER = 'n' ]]; then
      printf "[EXIT] Nothing to do.\n"
      break
  elif [[ $USER_ANSWER = 'YES' || $USER_ANSWER = 'yes' || $USER_ANSWER = 'y' ]]; then
      rights_fix
      break
  else
      printf "${Red}[BAD INPUT]${NC} Type only YES or NO\n"
  fi
done
