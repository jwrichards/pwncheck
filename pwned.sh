#!/bash/bin

rm /Users/jrichards/Desktop/PwnChecker/raw.json
rm /Users/jrichards/Desktop/PwnChecker/formatted.json
rm /Users/jrichards/Desktop/PwnChecker/upload.json
if [ -z "$1" ] #check for argument
then
  echo 'Requires email argument. Format pwned <email>'
  exit 1 #terminate and indicate error if no email address found
fi
  EMAILNAME="$1"

cat /Users/jrichards/Desktop/PwnChecker/header > /Users/jrichards/Desktop/PwnChecker/upload.json
curl 'https://haveibeenpwned.com/api/v2/breachedaccount/'"$EMAILNAME" | jq '.' > /Users/jrichards/Desktop/PwnChecker/raw.json
#cat /Users/jrichards/Desktop/PwnChecker/beenpwned.json >> /Users/jrichards/Desktop/PwnChecker/formatted.json
echo "Pwned email:"
echo $EMAILNAME
jq -r '.[].Name' /Users/jrichards/Desktop/PwnChecker/raw.json
jq  --arg ENAME $EMAILNAME 'map(. + {Email: $ENAME})' /Users/jrichards/Desktop/PwnChecker/raw.json >> /Users/jrichards/Desktop/PwnChecker/formatted.json
cat /Users/jrichards/Desktop/PwnChecker/formatted.json >> /Users/jrichards/Desktop/PwnChecker/upload.json
sed -i '$a }' /Users/jrichards/Desktop/PwnChecker/upload.json
curl -H "Content-Type: application/json" -d @$PWD/upload.json -X POST http://jrichards:Mycouchisafuton.@127.0.0.1:5984/testpwn/_bulk_docs