db_migration_script.sh

Description: shell to migrate a postgres db from one host to another host

Main steps:

 1. check if directory to dump postgres dbs exists
 2. check connectifity to source db
 3. check the version of the source db
 4. check size of the source db
 5. get time estimation 
 6. check connectivity to destination db
 7. get dump of the src db
 8. create user and db in the dest db
 9. check connectivity and a new user and db were created on the dest db
 10. run pg_restore of the dump into the destination db newly created
 11. post restore steps
 12. run vacuumdb to analyze and vacuum newly imported db
 13. list tables and num_of_rows on the newly imported db

Parameters:

 src_host - source database host
 src_port - source database port, default is 5432

 dest_host - destination database host
 dest_port - destination database port, default is 5432

 db_name - source database name
 db_pwd - source database pwd

 dest_db_superuser_user - destination database superuser user
 dest_db_superuser_pwd - destination database superuser pwd

 dest_db_name - destination database name
 dest_db_pwd - destination database pwd

 dump_dir_name - name of local directory where db dumps will be kept

 is_to_run_vacuum_analyze - optional [ 0 - No / 1 - Yes ] - is to run vacuum analyze
 is_to_list_tables_nrows - optional [ 0 - No / 1 - Yes ] - is to list tables and corresponding number of rows

How to run:

 ./run_db_migration_script.sh

