#!/bash/bin

rm /Users/jrichards/Desktop/PwnChecker/beenpwned.json
if [ -z "$1" ]
then
  echo "Potentially pwned positronic mail:"
  read EMAILNAME
else
  EMAILNAME="$1"
fi

cat /Users/jrichards/Desktop/PwnChecker/header > /Users/jrichards/Desktop/PwnChecker/beenpwned.json
curl 'https://haveibeenpwned.com/api/v2/breachedaccount/'"$EMAILNAME" | jq '.' >> /Users/jrichards/Desktop/PwnChecker/beenpwned.json
echo "Pwned email:"
echo $EMAILNAME
jq -r '.[].Name' /Users/jrichards/Desktop/PwnChecker/beenpwned.json
sed -i '$a }' /Users/jrichards/Desktop/PwnChecker/beenpwned.json
curl -H "Content-Type: application/json" -d @$PWD/beenpwned.json -X POST http://jrichards:Mycouchisafuton.@127.0.0.1:5984/testpwn/_bulk_docs
