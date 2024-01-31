#!/bin/bash

# Manual SnipeIT Backup
#
# SnipeIT instances running PHP 8.0+ have issues running artisan commands within the SnipeIT project directories.
# This script manually builds the backup file and zips it, as well as places it in the correct directory.
# Run this with a cron job or service to backup on a set schedule automatiaclly if issues with PHP arise.
# This seems to work without issue and restores everything correctly.
#
# Locate all files and pull them into a /tmp/directory
#       1. Main SnipeIT .sql file (mysqldump)
#       2. `/var/www/snipe-it/public/uploads/` Directory
#       3. `/var/www/snipe-it/storage/private_uploads` Directory
#       4. `/var/www/snipe-it/storage/oauth-private.key` & `oauth-public.key`
# Then run compression (.zip), everything else will be skipped.
# https://snipe-it.readme.io/docs/backups

temp_dir=$(mktemp -d) # temp dir

mkdir -p $temp_dir/db-dumps && mysqldump snipeit > $temp_dir/db-dumps/mysql-snipeit.sql # dump .sql file
mkdir -p $temp_dir/var/www/snipe-it/public && cp -r /var/www/snipe-it/public/uploads "$_" # copy uploads
mkdir -p $temp_dir/var/www/snipe-it/storage && cp -r /var/www/snipe-it/storage/private_uploads "$_" # copy private_uploads

cp -r /var/www/snipe-it/storage/oauth-private.key $temp_dir/var/www/snipe-it/storage # copy oauth private
cp -r /var/www/snipe-it/storage/oauth-public.key $temp_dir/var/www/snipe-it/storage # copy oauth public

cd $temp_dir && zip -r9 /var/www/snipe-it/storage/app/backups/snipe-it-cron-$(date +"%Y-%m-%d-%H-%M-%S").zip var/ db-dumps/ # compress

rm -rf $temp_dir # clean up