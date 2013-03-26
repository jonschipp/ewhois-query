#!/bin/bash

usage()
{
cat <<EOF

Query the ewhois.com engine.
    
    * Whois Lookup
    * Reverse IP Lookup
    * Reverse Adsense ID Lookup
    * Reverse Google Analytics ID Lookup
     
      Query Options:

	-w  <dns>  Whois
        -r  <ip>   Reverse IP
	-a  <id>   Adsense ID
        -g  <id>   Analytics ID

      Processing Options:
	
	-D	   Delete files (cleanup)
	-N         Skip download, file exists
	-O  <dir>  Output to directory
	-R  <file> Read ewhois file
	
Usage: $0 <option> <query>
e.g. $0 -w google.com
EOF
}

browsercheck()
{
if command -v wget >/dev/null 2>&1; then
BROWSER="wget"
echo -e "\nWget installed ...using"
elif command -v curl >/dev/null 2>&1; then
BROWSER="curl"
echo -e "\nCurl installed ...using"
else
echo -e "\nERROR: Neither cURL or Wget are installed or are not in the \$PATH!\n"
exit 1
fi
}

download()
{
if [ $BROWSER == "curl" ]; then
curl -L -o ${QUERY}.html ${URL}/${QUERY} 2>/dev/null
fi

if [ $BROWSER == "wget" ]; then
wget -O ${QUERY}.html ${URL}/${QUERY} 2>/dev/null
fi
}

# option and argument handling
while getopts "ha:Dg:Nr:w:" OPTION
do
     case $OPTION in
         a)
             QUERY="$OPTARG"
             TYPE="$OPTION"
             ;;
         D)
             DELETE="1"
             ;;
         g)
             QUERY="$OPTARG"
             TYPE="$OPTION"
             ;;
         h)
             usage
	     exit
	     ;;
         N)
             SKIP=1
	     ;;
         r) 
             QUERY="$OPTARG"
             TYPE="$OPTION"
	     URL="http://www.ewhois.com/ip-address"
             ;; 
	 w) 
             QUERY="$OPTARG"
             TYPE="$OPTION"
             URL="http://www.ewhois.com"
	     ;;
         \?)
             exit 1
             ;;
     esac
done

# call functions
browsercheck 
#inputcheck

if [ "$SKIP" != "1" ];then 
download 
fi

# meat
if [[ $TYPE == "w" ]]; then
echo -e "\n=== [Basic] ===\n" 
grep -o $QUERY ${QUERY}.html | head -1  | sed 's/\('"$QUERY"'\)/Domain Name: \1/'
grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' ${QUERY}.html | sed 's/\(.*\)/IP Address: \1/' | head -1
grep -o '<span>.*<\/span> ' ${QUERY}.html | sed 's/<span>//;s/<\/span>//;s/^/Reverse IP Lookup: /' | sort | uniq
grep -o " Located near.*" ${QUERY}.html | sed  -e 's/^ //' -e 's/<\/div>//'
grep -o 'UA-[0-9]\{6\}' ${QUERY}.html | sed 's/^/Google Analytics ID: /'
grep -o "<strong>.*other sites sharing this ID" ${QUERY}.html | sed 's/<strong>//;s/<\/strong>//;s/^/ --> /'
grep -o '[1-2][0-9]\{3\}-[0-1][1-9]-[0-3][1-9]' ${QUERY}.html | sed 's/^/Last Updated: /' | head -1
awk -F "</*td>|</*tr>" 'BEGIN { RS = "</tr>"; print "\n=== [DNS] ===\n\nHost:\t\tType:\tTTL:\tData:" } ! /div/ && /'"$QUERY"'/ {print $3"\t", $5"\t", $7"\t", $9"\t" }' ${QUERY}.html
awk 'BEGIN { print "\n=== [Whois] ===\n" } /<pre>/,/<\/pre>/ { print }' ${QUERY}.html | sed -e '/<img/d' -e '/pre>/d'
fi

if [[ $TYPE == "r" ]]; then
echo -e "\n=== [Basic] ===\n" 
grep -o '<td><strong>[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}</strong></td>' ${QUERY}.html | sed -e 's/<td><strong>//;s/<\/strong><\/td>//;s/^/IP Address: /'
grep -A 2 "IP Location" ${QUERY}.html | grep -o '<strong>.*</strong>' | sed 's/<strong>//;s/<\/strong>//;s/^/IP Location: /'
echo -e "\n=== [Sites] ===\n" 
grep '<strong>.* sites hosted ' ${QUERY}.html | sed 's/<p>//g;s/<strong>//g;s/<\/strong>//g;s/<\/p>//;s/^[ \t]*//'
echo
sed 's/<\/span>/<\/span>\n/g' ${QUERY}.html | grep -o '<span>.*<\/span>' | sed '/Login/d;/Register/d;/Reverse IP Lookup/d;/<a href/d;s/<span>//;s/<\/span>//;s/^/Hosted: /'

	i=0
	for page in $(grep -o 'page\:[0-9]\{1,3\}' ${QUERY}.html | grep -v 'page:1' | sort | uniq)
	do
       		let i++
        	wget -O ${QUERY}.html${i} ${URL}/${QUERY}/${page}/
        	sed 's/<\/span>/<\/span>\n/g' ${QUERY}.html${i} | grep -o '<span>.*<\/span>' | sed '/Login/d;/Register/d;/Reverse IP Lookup/d;/<a href/d;s/<span>//;s/<\/span>//;s/^/Hosted: /'
	done

fi

# Cleanup
if [[ $DELETE == "1" ]]; then
echo -e "Removing: \n$(ls ${QUERY}.html*)"
rm ${QUERY}.html*
fi
