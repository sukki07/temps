#! /bin/bash
DATE=$(date -d "-1 days" +"%Y/%m/%d")
CURRENT_PROD_S3="sz-db-dumps/${DATE}/mysql-daily"
CURRENT_PROD_S3_CHANGELOG_TABLE="sz-db-dumps/${DATE}/mysql-daily/inasra.changelog.sql.gz"
DB_SYNC_PARENT_DIR="/tmp/db_sync"
mkdir -p $DB_SYNC_PARENT_DIR
PREVIOUS_TIMESTAMP_DIR=$(ls -1 $DB_SYNC_PARENT_DIR | sort | tail -1)
PREVIOUS_GZIPPED_DIR=$DB_SYNC_PARENT_DIR/$PREVIOUS_TIMESTAMP_DIR/gzipped
PREVIOUS_GZIPPED_DIR="/tmp/db_sync/20161018040821"
CURRENT_TIMESTAMP=$(date +"%Y%m%d%H%M%S")

CURRENT_DIR=$DB_SYNC_PARENT_DIR/$CURRENT_TIMESTAMP
CURRENT_DIR="/tmp/db_sync/20161018044741"
CURRENT_GZIPPED_DIR=$CURRENT_DIR/gzipped
CURRENT_S3_COPIED_DIR=$CURRENT_DIR/s3_gzipped
CURRENT_S3_UNZIPPED_DIR=$CURRENT_DIR/s3_unzipped
mkdir -p $CURRENT_GZIPPED_DIR
mkdir -p $CURRENT_S3_COPIED_DIR
mkdir -p $CURRENT_S3_UNZIPPED_DIR
echo "copyting gzipped folder from previous to current"
#cp -r $PREVIOUS_GZIPPED_DIR $CURRENT_DIR

echo "copied gzipped from  $PREVIOUS_GZIPPED_DIR to $CURRENT_DIR"
aws s3 cp s3://$CURRENT_PROD_S3_CHANGELOG_TABLE $CURRENT_DIR/changelog.sql.gz
CURRENT_PROD_SCHEMA_NUMBER=$(gunzip -c $CURRENT_DIR/changelog.sql.gz | grep VALUES | tr '(' '\n' | tail -1 | cut -d\, -f1)
CURRENT_NON_PROD_SCHEMA_NUMBER=$(mysql -sN -udbuser -pdb123123 < /tmp/last_update.sql 2>/dev/null)
if (( $CURRENT_PROD_SCHEMA_NUMBER == $CURRENT_NON_PROD_SCHEMA_NUMBER ));then
	echo "schame is same as prod, going to download latest files from s3"
	#aws s3 cp s3://$CURRENT_PROD_S3 $CURRENT_S3_COPIED_DIR  --quiet --recursive --exclude "*.csv.gz"
	echo "s3 download complete"
	s3_files=`ls -1 $CURRENT_S3_COPIED_DIR`
	for file in $s3_files ;do
		prev_file=$CURRENT_GZIPPED_DIR/$file
		curr_file=$CURRENT_S3_COPIED_DIR/$file
		#echo "comparing $prev_file with $curr_file"
		if [[ -f $prev_file ]];then
			#echo "comparing crc for both the files "
			crc_prev_file=$(gzip -lv  $prev_file | grep -v crc | awk -F ' ' '{print $2}')
			crc_curr_file=$(gzip -lv  $curr_file | grep -v crc | awk -F ' ' '{print $2}')

			if [[ "$crc_curr_file" == "00000000" || "$crc_prev_file" == "00000000" ]];
			then
				echo "error $curr_file $crc_curr_file $prev_file $crc_prev_file"
				break
			fi


			if [[ "$crc_prev_file" != "$crc_curr_file" ]];then
				echo "mismatch $curr_file $crc_curr_file $prev_file $crc_prev_file"
				unzipped_file=$(echo $curr_file | awk -F'\\.gz' '{print $1}')
				pigz -dc $curr_file > $CURRENT_S3_UNZIPPED_DIR/$(basename $unzipped_file)
				echo "unzip done, will copy it to gzipped dir for next iteration to pick up"
				cp $curr_file $prev_file 
			fi
		else
			echo "could not find  $prev_file to compare with $curr_file ,ignoring it"
		fi
	done
	echo "files with changed crc have been unzipped , time to update mysql. hold on luke!"
	unzipped_files=`ls  -1 $CURRENT_S3_UNZIPPED_DIR`
	for unzipped_file in $unzipped_files;do
		echo "going to restore table $unzipped_file"
	done
elif (( $CURRENT_PROD_SCHEMA_NUMBER < $CURRENT_NON_PROD_SCHEMA_NUMBER ));then
	echo "schema has changed , not going to sync"
else
	echo "prod db is ahead of preprod,hell has broken loose! luke,notify lords"
fi
