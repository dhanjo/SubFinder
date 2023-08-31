#!/bin/bash


while getopts "d:s" opt; do
    case $opt in
        d) domain="$OPTARG";;
        s) silent="True";;
    esac
done

shift $((OPTIND-1))

current_date=$(date +"%Y-%m-%d")

wayback() {
	[ "$silent" == True ] && curl -sk "http://web.archive.org/cdx/search/cdx?url=*.$domain&output=txt&fl=original&collapse=urlkey&page=" | awk -F/ '{gsub(/:.*/, "", $3); print $3}' | sort -u | anew subenum-$domain.txt  || {
		[[ ${PARALLEL} == True ]]
		curl -sk "http://web.archive.org/cdx/search/cdx?url=*.$domain&output=txt&fl=original&collapse=urlkey&page=" | awk -F/ '{gsub(/:.*/, "", $3); print $3}' | sort -u > tmp-wayback-$domain
		[[ ${PARALLEL} == True ]] || kill ${PID} 2>/dev/null
		echo -e "$bold[*] WayBackMachine$end: $(wc -l < tmp-wayback-$domain)"
	}
}

crt() {
	[ "$silent" == True ] && curl -sk "https://crt.sh/?q=%.$domain&output=json" | tr ',' '\n' | awk -F'"' '/name_value/ {gsub(/\*\./, "", $4); gsub(/\\n/,"\n",$4);print $4}' | anew subenum-$domain.txt || {
		[[ ${PARALLEL} == True ]]
		curl -sk "https://crt.sh/?q=%.$domain&output=json" | tr ',' '\n' | awk -F'"' '/name_value/ {gsub(/\*\./, "", $4); gsub(/\\n/,"\n",$4);print $4}' | sort -u > tmp-crt-$domain
		[[ ${PARALLEL} == True ]] || kill ${PID} 2>/dev/null
		echo -e "$bold[*] crt.sh$end: $(wc -l < tmp-crt-$domain)" 
	}
}

Findomain() {
	[ "$silent" == True ] && findomain -t $domain -q 2>/dev/null | anew subenum-$domain.txt || {
		[[ ${PARALLEL} == True ]]
		findomain -t $domain -u tmp-findomain-$domain &>/dev/null
		[[ ${PARALLEL} == True ]] || kill ${PID} 2>/dev/null
		echo -e "$bold[*] Findomain$end: $(wc -l tmp-findomain-$domain 2>/dev/null | awk '{print $1}')"
	}
}

Subfinder() {
	[ "$silent" == True ] && subfinder -all -silent -d $domain 2>/dev/null | anew subenum-$domain.txt || {
		[[ ${PARALLEL} == True ]]
		subfinder -all -silent -d $domain 1> tmp-subfinder-$domain 2>/dev/null
		[[ ${PARALLEL} == True ]] || kill ${PID} 2>/dev/null
		echo -e "$bold[*] SubFinder$end: $(wc -l < tmp-subfinder-$domain)"
	}
}

Assetfinder() {
	[ "$silent" == True ] && assetfinder --subs-only $domain | anew subenum-$domain.txt || {
		[[ ${PARALLEL} == True ]]
		assetfinder --subs-only $domain > tmp-assetfinder-$domain
		kill ${PID} 2>/dev/null
		echo -e "$bold[*] AssetFinder$end: $(wc -l < tmp-assetfinder-$domain)"
	}
}


main() {
    wayback
    crt
    Findomain
    Subfinder
    Assetfinder

    # Combine temporary files into a single file
    sort tmp-wayback-$domain tmp-crt-$domain tmp-findomain-$domain tmp-subfinder-$domain tmp-assetfinder-$domain | uniq -i > subenum-$domain-$current_date.txt
    echo "Combined output saved to subenum-$domain.txt"
    # Clean up temporary files
    rm tmp-wayback-$domain tmp-crt-$domain tmp-findomain-$domain tmp-subfinder-$domain tmp-assetfinder-$domain

	# Running HTTPROBE to get active websites.
	sort subenum-$domain-$current_date.txt | httprobe > httprobe-$domain-$current_date.txt
	echo "[*] HTTPROBE scanned file is httprobe-$domain-$current_date.txt"
}

# Call the main function
main
