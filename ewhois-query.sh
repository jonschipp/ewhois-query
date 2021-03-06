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
	-R  <file> Read html file from full path
	-O  <file> Write output to file
	
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
while getopts "ha:Dg:NO:r:R:w:" OPTION
do
     case $OPTION in
         a)
             QUERY="$OPTARG"
             TYPE="$OPTION"
	     URL="http://www.ewhois.com/adsense-id"
             ;;
         D)
             DELETE="1"
             ;;
         g)
             QUERY="$OPTARG"
             TYPE="$OPTION"
	     URL="http://www.ewhois.com/analytics-id"
             ;;
         h)
             usage
	     exit
	     ;;
         N)
             SKIP=1
	     ;;
	 O)
	     LOGFILE="$OPTARG"
	     exec > >(tee "$LOGFILE") 2>&1
	     ;;
         r) 
             QUERY="$OPTARG"
             TYPE="$OPTION"
	     URL="http://www.ewhois.com/ip-address"
             ;; 
	 R) 
	     SKIP=1
	     FPATH="$OPTARG"
	     ;;
	 w) 
             QUERY="$OPTARG"
             TYPE="$OPTION"
             URL="http://www.ewhois.com"
	     ;;
         \?)
             usage
             ;;
     esac
done

# test & call functions
if ! [[ $1 == -* ]]; then
usage
fi 
browsercheck 

if [ "$SKIP" != "1" ];then 
download 
fi

#if  [ ! -z "$FPATH" ]; then
#QUERY="$FPATH"
#fi

# meat
if [[ $TYPE == "w" ]]; then
echo -e "\n=== [Basic] ===\n" 
grep -o $QUERY ${QUERY}.html | head -1  | sed 's/\('"$QUERY"'\)/Domain Name: \1/'
grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' ${QUERY}.html | sed 's/\(.*\)/IP Address: \1/' | head -1
grep -o " Located near.*" ${QUERY}.html | sed  -e 's/^ //' -e 's/<\/div>//'
grep -o 'UA-[0-9]\{6\}' ${QUERY}.html | sed 's/^/Google Analytics ID: /'
grep -o "<strong>.*other sites sharing this ID" ${QUERY}.html | sed 's/<strong>//;s/<\/strong>//;s/^/ --> /'
grep -o '[1-2][0-9]\{3\}-[0-1][1-9]-[0-3][1-9]' ${QUERY}.html | sed 's/^/Last Updated: /' | head -1
echo -e "\n=== [Reverse IP Lookup] ===\n" 
grep -A 1 "Reverse IP Lookup" ${QUERY}.html | awk 'BEGIN { RS = "<span>" } { print $1 }' | sed '/^</d;s/<\/span>//'
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
echo
fi

if [[ $TYPE == "g" ]]; then
echo -e "\n=== [Reverse Google Analytics ID Lookup] ===\n" 
grep -o "<strong>.* Analytics ID" ${QUERY}.html | sed 's/<strong>//;s/<\/strong>//;s/^/ --> /;s/$/ '"$QUERY"'\n/'
sed 's/<\/span>/<\/span>\n/g' ${QUERY}.html | grep -o '<span>.*<\/span>' | \
sed '/Login/d;/Register/d;/Reverse/d;s/<span>//;s/<\/span>//'
echo
fi

if [[ $TYPE == "a" ]]; then
echo -e "\n=== [Reverse Google Adsense ID Lookup] ===\n" 
grep -o "<strong>.* AdSense ID" ${QUERY}.html | sed 's/<strong>//;s/<\/strong>//;s/^/ --> /;s/$/ '"$QUERY"'\n/'
sed 's/<\/span>/<\/span>\n/g' ${QUERY}.html | grep -o '<span>.*<\/span>' | \
sed '/Login/d;/Register/d;/Reverse/d;s/<span>//;s/<\/span>//'
echo
fi

# Cleanup
if [[ $DELETE == "1" ]]; then
for file in $(ls ${QUERY}.html*)
do
echo -e "\nRemoving:"
echo " --> $file"
rm ${QUERY}.html*
done
fi
