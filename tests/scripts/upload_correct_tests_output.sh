#!/bin/bash
set -eu

# Always run this script with current directory set to
# directory where this script is,
# i.e. tests/scripts/ inside pasdoc sources.
#
# This script uploads to
# [http://pasdoc.sourceforge.net/correct_tests_output/]
# current output of tests generated in ../$1/.
# This means that you're accepting current output of tests
# (for this output format) as "correct".
#
# Option "$1" is the name of output format (as for pasdoc's
# --format option), this says which subdirectory of ../tests/
# should be uploaded.
#
# Option "$2" is your username on sourceforge.
# Note that you will be asked (more than once) for your password
# unless you configured your ssh keys, which is recommended.
#
# After uploading it calls ./download_correct_tests_output.sh "$1"
# This way it checks that files were correctly uploaded
# and also sets your local version of ../correct_output/ directory
# to the correct state.
# So after calling this script successfully, directories
# ../$1/ and ../correct_output/$1/ are always equal.
#
# Precisely what files are uploaded:
# - $1.tar.gz -- archived contents of ../$1/
#   Easily downloadable, e.g. by download_correct_tests_output.
# - $1 directory -- copy of ../$1/
#   Easy to browse, so we can e.g. make links from pasdoc's wiki
#   page ProjectsUsingPasDoc to this.
# - $1.timestamp -- current date/time, your username (taken from $2)
#   to make this information easy available.
#   (to be able to always answer the question "who and when uploaded this ?")
#
# Note: after uploading, it sets group of uploaded files
# to `pasdoc' and makes them writeable by the group.
# This is done in order to allow other pasdoc developers
# to also execute this script, overriding files uploaded by you.
#
# Requisites: uploading is done using `scp' command.
# Also `ssh' command is used by ./ssh_chmod_writeable_by_pasdoc.sh
# to set group/permissions.

# Parse options
FORMAT="$1"
SF_USERNAME="$2"

# Prepare clean TEMP_PATH
TEMP_PATH=upload_correct_tests_output_tmp/
rm -Rf "$TEMP_PATH"
mkdir "$TEMP_PATH"

# Prepare tar.gz archive
ARCHIVE_FILENAME_NONDIR="$FORMAT.tar.gz"
ARCHIVE_FILENAME="$TEMP_PATH""$ARCHIVE_FILENAME_NONDIR"
echo "Creating $ARCHIVE_FILENAME_NONDIR ..."
# Note: We temporary jump to ../, this way we can pack files using 
# "$FORMAT"/ instead of ../"$FORMAT"/. Some tar versions would
# strip "../" automatically, but some would not.
cd ../
tar czf scripts/"$ARCHIVE_FILENAME" "$FORMAT"/
cd scripts/

# Prepare timestamp file
TIMESTAMP_FILENAME_NONDIR="$FORMAT.timestamp"
TIMESTAMP_FILENAME="$TEMP_PATH""$TIMESTAMP_FILENAME_NONDIR"
echo "Creating $TIMESTAMP_FILENAME_NONDIR ..."
date '+%F %T' > "$TIMESTAMP_FILENAME"
echo "$SF_USERNAME" >> "$TIMESTAMP_FILENAME"

# Do the actual uploading to the server

echo "Uploading ..."

SF_PATH=/home/groups/p/pa/pasdoc/htdocs/correct_tests_output/
SF_CONNECT="$SF_USERNAME"@shell.sourceforge.net:"$SF_PATH"

scp "$ARCHIVE_FILENAME" "$SF_CONNECT"
scp "$TIMESTAMP_FILENAME" "$SF_CONNECT"

# I could do here simple
#   scp -r ../"$FORMAT"/ "$SF_CONNECT"
# but this requires uploading all files unpacked.
# It's much quickier to just log to server and untar there uploaded archive.
ssh -l "$SF_USERNAME" shell.sourceforge.net <<EOF
  cd "$SF_PATH"
  tar xzf "$ARCHIVE_FILENAME_NONDIR"
EOF

./ssh_chmod_writeable_by_pasdoc.sh "$SF_USERNAME" "$SF_PATH"

# Clean temp dir
rm -Rf upload_correct_tests_output_tmp/

./download_correct_tests_output.sh "$FORMAT"