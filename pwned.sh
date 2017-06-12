#!/usr/local/bin/bash
die () {
    echo >&2 "$@"
    exit 1
}

cleanFile () {
	[ ! -e $RUNPATH/$1 ] || rm $RUNPATH/$1
	echo "Cleaned up $1"
}

RUNPATH=/usr/local/bin/pwncheck

[ "$#" -eq 1 ] || die "1 argument (email) required, $# provided" #check an argument
echo $1 | grep -E -q '@' || die "Email argument required, $1 provided"

#Directory exists, OR create it.
[ -d $RUNPATH ] || mkdir $RUNPATH

#File doesn't exist, OR remove any files from prior runs that are lying around.
cleanFile raw.json
cleanFile formatted.json
cleanFile upload.json

#Make Header file, since we don't want to assume things
echo '{' > $RUNPATH/header
echo '  "docs":' >> $RUNPATH/header

#Check to see if DB exists:
DBEXISTS=$(curl 'http://localhost:5984/testpwn' | jq '.db_name')
echo "Database: $DBEXISTS"
[ ! $DBEXISTS = "null" ] || curl -X PUT 'http://jrichards:Mycouchisafuton.@localhost:5984/testpwn' #If DB does not exist, create new DB.
DBEXISTS=$(curl 'http://localhost:5984/testpwn' | jq '.db_name')
[ ! $DBEXISTS = "null" ] || die "Database doesn't exist and creation failed. Giving up on life now" #Repeat DB lifecheck - if it fails again, exit with errors.

EMAILNAME="$1" #Turn argument into a variable

#set up the upload file with the right header from header file
cat $RUNPATH/header > $RUNPATH/upload.json
#Hit the haveibeenpwned api for results
curl 'https://haveibeenpwned.com/api/v2/breachedaccount/'"$EMAILNAME" | jq '.' > $RUNPATH/raw.json
[ -s $RUNPATH/raw.json ] || die "No results for $EMAILNAME" #Tests to make sure results were received.
#display results
echo "Pwned email:"
echo $EMAILNAME
jq -r '.[].Name' $RUNPATH/raw.json
#Take raw json and wrap it in the docs: header to use the bulk upload
jq  --arg ENAME $EMAILNAME 'map(. + {Email: $ENAME})' $RUNPATH/raw.json >> $RUNPATH/upload.json
#cat $RUNPATH/formatted.json >> $RUNPATH/upload.json
sed -i '$a }' $RUNPATH/upload.json #put the footer on upload.json to use the bulk upload
#stuff it in the couchDB via the _bulk_docs 
curl -H "Content-Type: application/json" -d @$RUNPATH/upload.json -X POST http://jrichards:Mycouchisafuton.@127.0.0.1:5984/testpwn/_bulk_docs