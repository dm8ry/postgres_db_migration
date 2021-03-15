#!/bin/sh

#######################################################################
#
# Name: db_migration_script.sh
#
# Description: shell to migrate a postgres db from one host to another host
#
# Main steps:
#
# 1. check if directory to dump postgres dbs exists
# 2. check connectifity to source db
# 3. check the version of the source db
# 4. check size of the source db
# 5. get time estimation (not implemented yet)
# 6. check connectivity to destination db
# 7. get dump of the src db
# 8. create user and db in the dest db
# 9. check connectivity and a new user and db were created on the dest db
# 10. run pg_restore of the dump into the destination db newly created
# 11. post restore steps
# 12. run vacuumdb to analyze and vacuum newly imported db
# 13. list tables and num_of_rows on the newly imported db
#
# Parameters:
# 
# src_host - source database host
# src_port - source database port, default is 5432
#
# dest_host - destination database host
# dest_port - destination database port, default is 5432
#
# db_name - source database name
# db_pwd - source database pwd
#
# dest_db_superuser_user - destination database superuser user
# dest_db_superuser_pwd - destination database superuser pwd
#
# dest_db_name - destination database name 
# dest_db_pwd - destination database pwd
#
# dump_dir_name - name of local directory where db dumps will be kept
#
# is_to_run_vacuum_analyze - optional [ 0 - No / 1 - Yes ] - is to run vacuum analyze
# is_to_list_tables_nrows - optional [ 0 - No / 1 - Yes ] - is to list tables and corresponding number of rows
#
# Author: Dmitry
#
# Date: 09-Mar-2021
# 
#######################################################################


src_host="my_source_host"
src_port="5432"

dest_host="my_dest_host"
dest_port="5432"

db_name="my_db_name"
db_pwd="my_db_pwd"

dest_db_superuser_user="my_dest_super_user"
dest_db_superuser_pwd="my_dest_super_pwd"

dest_db_name="my_dest_db_name"
dest_db_pwd="my_dest_db_pwd"

dump_dir_name="postgres_my_dbs_dumps"

is_to_run_vacuum_analyze=1
is_to_list_tables_nrows=1


########################################################################
#
# check input parameters
#
########################################################################

if [ -z "$src_host" ]
then
      echo "Error! Parameter src_host is empty."
      echo " "
      exit 10
fi

if [ -z "$src_port" ]
then
      echo "Error! Parameter src_port is empty."
      echo " "
      exit 11
fi

if [ -z "$dest_host" ]
then
      echo "Error! Parameter dest_host is empty."
      echo " "
      exit 12
fi

if [ -z "$dest_port" ]
then
      echo "Error! Parameter dest_port is empty."
      echo " "
      exit 13
fi

if [ -z "$db_name" ]
then
      echo "Error! Parameter db_name is empty."
      echo " "
      exit 15
fi

if [ -z "$db_pwd" ]
then
      echo "Error! Parameter db_pwd is empty."
      echo " "
      exit 16
fi

if [ -z "$dest_db_superuser_user" ]
then
      echo "Error! Parameter dest_db_superuser_user is empty."
      echo " "
      exit 17
fi

if [ -z "$dest_db_superuser_pwd" ]
then
      echo "Error! Parameter dest_db_superuser_pwd is empty."
      echo " "
      exit 18
fi

if [ -z "$dest_db_name" ]
then
      echo "Error! Parameter dest_db_name is empty."
      echo " "
      exit 19
fi

if [ -z "$dest_db_pwd" ]
then
      echo "Error! Parameter dest_db_pwd is empty."
      echo " "
      exit 20
fi

if [ -z "$dump_dir_name" ]
then
      echo "Error! Parameter dump_dir_name is empty."
      echo " "
      exit 21
fi

if [ -z "$is_to_run_vacuum_analyze" ]
then
      echo "Error! Parameter is_to_run_vacuum_analyze is empty."
      echo " "
      exit 22
fi

if [ -z "$is_to_run_vacuum_analyze" ]
then
      echo "Error! Parameter is_to_run_vacuum_analyze is empty."
      echo " "
      exit 23
fi

if [ -z "$is_to_list_tables_nrows" ]
then
      echo "Error! Parameter is_to_list_tables_nrows is empty."
      echo " "
      exit 24
fi

if [ "$src_host" == "$dest_host" ]; then
    echo "Error! src_host and dest_host should be different."
    echo " "
    echo 14
fi

########################################################################
#
# begin
#
########################################################################

current_date_time="$(date +'%Y%m%d_%H%M%S')"

echo " "

echo "[$(date +'%Y%m%d_%H%M%S')]: begin"
echo " "

########################################################################
#
# check if directory to dump postgres dbs exists
#
########################################################################

if [ -d "./${dump_dir_name}" ] 
then
    echo "Check existance of dumps directory [${dump_dir_name}] is Ok." 
    echo " "
else
    echo "Error: directory to dump postgres backups ${dump_dir_name} does not exists."
    echo " "
    exit 5
fi

########################################################################
#
# check connectifity to source db
#
########################################################################

echo "Check connectivity to source db ${db_name} on host: ${src_host} port: ${src_port}"
echo " "

export PGPASSWORD="${db_pwd}"

src_db_connectivity=$(psql -h ${src_host} -p ${src_port} -U ${db_name} -d ${db_name} -t -c "select count(1) exists_or_not_exists from pg_database where datname='${db_name}'")

if [ -z "$src_db_connectivity" ]
then
  echo "Error: connectivity problem to src db ${db_name} on host: ${src_host} port: ${src_port}"
  echo " "
  exit 1
else
  echo "Connectivity to the src db ${db_name} on the host: ${src_host} port: ${src_port} is Ok"
  echo " "
fi

if [ $src_db_connectivity -ne 1 ]
then
  echo "Error: db ${db_name} doesnot exist on source Postgres DB instance host: ${src_host} port: ${src_port}"
  echo " "
  exit 2
else
  echo "The src db ${db_name} on the host: ${src_host} port: ${src_port} existance check is Ok"
  echo " "
fi

########################################################################
#
# check the version of the source db
#
########################################################################

echo "Get version of the source db ${db_name} on host: ${src_host} port: ${src_port}"
echo " "

export PGPASSWORD="${db_pwd}"

src_db_get_version=$(psql -h ${src_host} -p ${src_port} -U ${db_name} -d ${db_name} -t  << EOF
select version()
EOF
)

echo "Source DB version: $src_db_get_version"
echo " "


########################################################################
#
# check size of the source db
#
########################################################################

echo "Get size of the source db ${db_name} on host: ${src_host} port: ${src_port}"
echo " "

export PGPASSWORD="${db_pwd}"

src_db_get_size=$(psql -h ${src_host} -p ${src_port} -U ${db_name} -d ${db_name} -t  << EOF
select
datname,
'size in MB:' as t1,
round(pg_database_size(pg_database.datname)/1024/1024, 2) AS size_in_MB,
'size in GB:' as t2,
round(pg_database_size(pg_database.datname)/1024/1024/1024, 2) AS size_in_GB
from
pg_database
where datname='${db_name}'
EOF
)

echo "Source DB size: $src_db_get_size"
echo " "

########################################################################
#
# check connectivity to destination db
#
########################################################################


echo "Check connectivity to destination ${dest_db_name} on host: ${dest_host} port: ${dest_port}"
echo " "

export PGPASSWORD="${dest_db_superuser_pwd}"

dest_db_connectivity=$(psql -h ${dest_host} -p ${dest_port} -U ${dest_db_superuser_user} -d postgres -t -c "select count(1) exists_or_not_exists from pg_database where datname='${dest_db_name}'" )

if [ -z "$dest_db_connectivity" ]
then
  echo "Error: connectivity problem to dest db postgres on host: ${dest_host} port: ${dest_port}"
  echo " "
  exit 1
else
  echo "Connectivity to the dest db postgres on the host: ${dest_host} port: ${dest_port} is Ok"
  echo " "
fi

if [ $dest_db_connectivity -ne 0 ]
then
  echo "Error: db ${dest_db_name} exists on destination Postgres DB instance host: ${dest_host} port: ${dest_port}"
  echo " "
  exit 2
else
  echo "The destination db ${dest_db_name} on the host: ${dest_host} port: ${dest_port} not existance check is Ok"
  echo " "
fi

########################################################################
#
# get dump of the src db 
#
########################################################################

db_backup_directory_name="db_dump_dir_${current_date_time}_${db_name}"

echo "db_backup_directory_name: $db_backup_directory_name"
echo " "

db_backup_directory_with_relative_path="${dump_dir_name}/${db_backup_directory_name}"

echo "db_backup_directory_with_relative_path: $db_backup_directory_with_relative_path"
echo " "

mkdir ${db_backup_directory_with_relative_path}

echo "Directory ${db_backup_directory_with_relative_path} is created Ok"
echo " "


echo "[$(date +'%Y%m%d_%H%M%S')]: started export of db ${db_name} on host ${src_host} on port ${src_port} to directory ${db_backup_directory_name}"
echo " "

cd "${dump_dir_name}"

export PGPASSWORD="${db_pwd}"

pg_dump -F d -f ${db_backup_directory_name} --compress 0 -j 8 -h ${src_host} -p ${src_port} -U ${db_name}

echo "[$(date +'%Y%m%d_%H%M%S')]: finished export of db ${db_name} on host ${src_host} on port ${src_port} to directory ${db_backup_directory_name}"
echo " "

########################################################################
#
# create user and db in the dest db
#
########################################################################

echo "Create a new DB user ${dest_db_name} and a new DB ${dest_db_name} has been created on destination DB host: $dest_host"
echo " "

export PGPASSWORD="${dest_db_superuser_pwd}"

create_new_user_and_new_db=$(psql -h ${dest_host} -p ${dest_port} -U ${dest_db_superuser_user} -d postgres -t  << EOF

create user ${dest_db_name} with password '${dest_db_pwd}';

create database ${dest_db_name};

grant all privileges on database ${dest_db_name} to ${dest_db_name};

grant ${dest_db_name} to ${dest_db_superuser_user};

EOF
)

echo "create_new_user_and_new_db: $create_new_user_and_new_db"

echo "A new DB user ${dest_db_name} and a new DB ${dest_db_name} has been created on destination DB host: $dest_host"
echo " "

########################################################################
#
# check connectivity and a new user and db were created on the dest db
#
########################################################################

echo "Check connectivity to the new user ${dest_db_name} and to the new created destination db ${dest_db_name} on host: ${dest_host} port: ${dest_port}"
echo " "

export PGPASSWORD="${dest_db_pwd}"

dest_db_connectivity=$(psql -h ${dest_host} -p ${dest_port} -U ${dest_db_name} -d ${dest_db_name} -t -c "select count(1) exists_or_not_exists from pg_database where datname='${dest_db_name}'")

if [ -z "$dest_db_connectivity" ]
then
  echo "Error: connectivity problem to dest db ${dest_db_name} on host: ${dest_host} port: ${dest_port}"
  echo " "
  exit 1
else
  echo "Connectivity to the dest db ${dest_db_name} on the host: ${dest_host} port: ${dest_port} is Ok"
  echo " "
fi

if [ $dest_db_connectivity -ne 1 ]
then
  echo "Error: db ${dest_db_name} doesnot exist on destination Postgres DB instance host: ${dest_host} port: ${dest_port}"
  echo " "
  exit 2
else
  echo "The destination db ${dest_db_name} on the host: ${dest_host} port: ${dest_port} existance check is Ok"
  echo " "
fi

########################################################################
#
# run pg_restore of the dump into the destination db newly created
#
########################################################################

echo "Restore the dbdump to destination DB instance. User ${dest_db_name}. Destination DB: ${dest_db_name}, host: ${dest_host}, port: ${dest_port}"
echo " "

echo "[$(date +'%Y%m%d_%H%M%S')]: started import"
echo " "

export PGPASSWORD="${dest_db_pwd}"

pg_restore -F d -j 8 -h ${dest_host} --no-owner --no-privileges --role=${dest_db_name} -U ${dest_db_name} -d ${dest_db_name} ${db_backup_directory_name}

echo "[$(date +'%Y%m%d_%H%M%S')]: ended import"
echo " "

########################################################################
#
# post restore steps                                   
#
########################################################################

echo "Post-restore steps to destination DB instance. User ${dest_db_name}. Destination DB: ${dest_db_name}, host: ${dest_host}, port: ${dest_port}"
echo " "

export PGPASSWORD="${dest_db_superuser_pwd}"

post_restore_steps_new_db=$(psql -h ${dest_host} -p ${dest_port} -U ${dest_db_superuser_user} -d postgres -t  << EOF

alter database ${dest_db_name} owner to ${dest_db_name};

revoke connect on database ${dest_db_name} from public;

revoke temporary on database ${dest_db_name} from public;

\l ${dest_db_name}

EOF
)

echo "$post_restore_steps_new_db"
echo " "


########################################################################
#
# run vacuumdb to analyze and vacuum newly imported db
#
########################################################################

if [ $is_to_run_vacuum_analyze -eq 1 ]
then
  echo "According to input parameter it will be run vacuum and analyze statistics on destination DB ${dest_db_name}, host: ${dest_host}, port: ${dest_port}"
  export PGPASSWORD="${dest_db_pwd}"
  vacuumdb -h ${dest_host} -p ${dest_port} -U ${dest_db_name} -j 4 -z ${dest_db_name}
  echo " "
else
  echo "According to input parameter it will not be run vacuum and analyze statistics on destination DB ${dest_db_name}, host: ${dest_host}, port: ${dest_port}"
  echo " "
fi

########################################################################
#
# list tables and num_of_rows on the newly imported db
#
########################################################################

if [ $is_to_list_tables_nrows -eq 1 ]
then
  echo "According to input parameter it will be listed tables and their num of rows on destination DB ${dest_db_name}, host: ${dest_host}, port: ${dest_port}"
  echo " "

  export PGPASSWORD="${dest_db_pwd}"

  list_tables_and_num_of_rows=$(psql -h ${dest_host} -p ${dest_port} -U ${dest_db_name} -d ${dest_db_name} -t  << EOF

  select n.nspname as table_schema,
         c.relname as table_name,
         c.reltuples as rows
  from pg_class c
   join pg_namespace n on n.oid = c.relnamespace
  where c.relkind = 'r'
        and n.nspname not in ('information_schema','pg_catalog')
   order by c.reltuples desc;

EOF
)

  echo "$list_tables_and_num_of_rows"
  echo " "
else
  echo "According to input parameter it will not be listed tables and their num of rows on destination DB ${dest_db_name}, host: ${dest_host}, port: ${dest_port}"
  echo " "
fi


########################################################################
#
# the end
#
########################################################################

echo "[$(date +'%Y%m%d_%H%M%S')]: end"
echo " "


