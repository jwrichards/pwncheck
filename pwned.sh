#!/bash/bin
die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "1 argument (email) required, $# provided" #check an argument
echo $1 | grep -E -q '@' || die "Email argument required, $1 provided"

#remove any files from prior runs that are lying around.
rm /Users/jrichards/Desktop/PwnChecker/raw.json
rm /Users/jrichards/Desktop/PwnChecker/formatted.json
rm /Users/jrichards/Desktop/PwnChecker/upload.json

#Check to see if DB exists:
DBEXISTS=curl 'http://localhost:5984/testpwn' | jq '.db_name'
[ ! -z $DBEXISTS ] || curl -X PUT 'http://jrichards:Mycouchisafuton.@localhost:5984/testpwn' #If DB does not exist, create new DB.

EMAILNAME="$1" #Turn argument into a variable

#set up the upload file with the right header from header file
cat /Users/jrichards/Desktop/PwnChecker/header > /Users/jrichards/Desktop/PwnChecker/upload.json
#Hit the haveibeenpwned api for results
curl 'https://haveibeenpwned.com/api/v2/breachedaccount/'"$EMAILNAME" | jq '.' > /Users/jrichards/Desktop/PwnChecker/raw.json
#display results
echo "Pwned email:"
echo $EMAILNAME
jq -r '.[].Name' /Users/jrichards/Desktop/PwnChecker/raw.json
#Take raw json and wrap it in the docs: header to use the bulk upload
jq  --arg ENAME $EMAILNAME 'map(. + {Email: $ENAME})' /Users/jrichards/Desktop/PwnChecker/raw.json >> /Users/jrichards/Desktop/PwnChecker/formatted.json
cat /Users/jrichards/Desktop/PwnChecker/formatted.json >> /Users/jrichards/Desktop/PwnChecker/upload.json
sed -i '$a }' /Users/jrichards/Desktop/PwnChecker/upload.json
#stuff it in the couchDB via the _bulk_docs 
curl -H "Content-Type: application/json" -d @$PWD/upload.json -X POST http://jrichards:Mycouchisafuton.@127.0.0.1:5984/testpwn/_bulk_docs