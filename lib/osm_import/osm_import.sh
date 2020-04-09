#!/bin/bash

# Tou should have installes osmconver64, osmfilter and osm2pgsql. The first too need to be run from this folder

while getopts ":f:u:d:c:" opt; do
  case $opt in
    f) filepath="$OPTARG"
    ;;
    u) username="$OPTARG"
    ;;
    d) database="$OPTARG"
    ;;
    c) country="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

filename="$(basename -- $filepath)"
osmconvert64 $filepath -o=/tmp/$filename.o5m
osmfilter $filepath  --keep="shop= or amenity=" > shops_amenities.osm
osm2pgsql --hstore --username $username --database  $database shops_amenities.osm
rm /tmp/$filename.o5m

psql -U $username -d $database -f create_osm_points.sql > ../../db/files/$country.csv
