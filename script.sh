#!/bin/bash
#========================================================
#                  Bulk DNS Lookup
# Generates a CSV of DNS lookups from a list of domains.
#========================================================
#
#
#               --User Settings--
#
output_file_name='dns_lookup' # Output file name.
#
# IP address of the nameserver used for lookups:
ns1_ip='1.1.1.1'      # Cloudflare
ns2_ip='9.9.9.9'      # Quad9
ns3_ip='1.1.1.2'      # Cloudflare Malware
ns4_ip='94.140.14.49' # Aguard DNS
ns5_ip='45.90.28.61'  # NextDNS
#--------------------------------------------------------

#
#------- functions 
dnsBulkLookup() {
	# download the domain list
	# check if domains.txt exists
	if [ -f domains.txt ]; then
		echo "domains.txt found."
	else
		echo "domains.txt not found. downloading from anudeepND's github repo."
		sleep 2
		curl https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt -o domains.txt

		echo "cleaning up the downloaded file."
		sed -i '' -e 's/0.0.0.0 //' domains.txt              # delete the 0.0.0.0 form every line
		sed -i '' -e '/^[[:blank:]]*#/d;s/#.*//' domains.txt #delete comments
	fi
	#
	#
	#
	# count how many domains are in the list:
	number_of_loaded_domains=$(wc -l <domains.txt | xargs)
	#check if the file exists
	if [ ! -f domains.txt ]; then
		echo "File domains.txt does not exist."
		exit 1
	fi
	#check if the file is empty
	if [ $number_of_loaded_domains -eq 0 ]; then
		echo "File domains.txt is empty."
		exit 1
	fi
	#
	#
	counter = 0
	# Print number of domains in list:
	echo "Loaded $number_of_loaded_domains domains from domains.txt"
	sleep 1                                                      # Wait 1 second.
	echo "Domain name, $ns1_ip,$ns2_ip,$ns3_ip,$ns4_ip,$ns5_ip " # Start CSV
	echo "Tested Domain, Server 1 Response, Server 2 Response, Server 3 Response, Server 4 Response, Server 5 Response" >$output_file_name.csv
	sleep 0.5 # Wait 0.5 seconds.

	# run the loop on multiple threads

	for domain in $(# Start looping through domains
		cat domains.txt
	); do
		#calculate progress:
		counter=$((counter + 1))
		percentage=$((counter * 100 / number_of_loaded_domains))
		echo -en "[$counter/$number_of_loaded_domains|$percentage%] $domain\n" # Print domain name
		ip1=$(dig @$ns1_ip +short $domain | tail -n1)                          # IP address lookup DNS Server1
		ip2=$(dig @$ns2_ip +short $domain | tail -n1)                          # IP address lookup DNS server2
		ip3=$(dig @$ns3_ip +short $domain | tail -n1)                          # IP address lookup DNS server3
		ip4=$(dig @$ns4_ip +short $domain | tail -n1)                          # IP address lookup DNS server4
		ip5=$(dig @$ns5_ip +short $domain | tail -n1)                          # IP address lookup DNS server5
		echo -en "$domain,$ip1,$ip2,$ip3,$ip4,$ip5\n" >>$output_file_name.csv  # Write CSV
	done
	echo "Run finished. Check $output_file_name.csv for results" # Print finished message
}

dnsSpeed() {
	echo "Testing response times of DNS servers."
	echo "Pinging Servers..."
	#Test response time for DNS servers:
	#
	ping1=$(ping -c 4 $ns1_ip | tail -1 | awk '{print $4}' | cut -d '/' -f 2) # Ping DNS server1
	ping2=$(ping -c 4 $ns2_ip | tail -1 | awk '{print $4}' | cut -d '/' -f 2) # Ping DNS server2
	ping3=$(ping -c 4 $ns3_ip | tail -1 | awk '{print $4}' | cut -d '/' -f 2) # Ping DNS server3
	ping4=$(ping -c 4 $ns4_ip | tail -1 | awk '{print $4}' | cut -d '/' -f 2) # Ping DNS server4
	ping5=$(ping -c 4 $ns5_ip | tail -1 | awk '{print $4}' | cut -d '/' -f 2) # Ping DNS server5
	echo "Testing dig response times..."
	#
	# Test dig response times:
	#
	dig1=$(dig +time=1 +tries=10 google.com @$ns1_ip | awk '/Query time:/')# dig DNS server1
	dig2=$(dig +time=1 +tries=10 google.com @$ns2_ip | awk '/Query time:/') # dig DNS server2
	dig3=$(dig +time=1 +tries=10 google.com @$ns3_ip | awk '/Query time:/') # dig DNS server3
	dig4=$(dig +time=1 +tries=10 google.com @$ns4_ip | awk '/Query time:/') # dig DNS server4
	dig5=$(dig +time=1 +tries=10 google.com @$ns5_ip | awk '/Query time:/') # dig DNS server5
	echo "Testing nslookup response times..."
	#
	clear
	#print results:
	echo "------- Ping results:"
	echo "DNS server1: $ns1_ip, response time: $ping1 ms"
	echo "DNS server2: $ns2_ip, response time: $ping2 ms"
	echo "DNS server3: $ns3_ip, response time: $ping3 ms"
	echo "DNS server4: $ns4_ip, response time: $ping4 ms"
	echo "DNS server5: $ns5_ip, response time: $ping5 ms"
	#
	echo "------- Dig results:"
	echo "DNS server1: $ns1_ip$dig1"
	echo "DNS server2: $ns2_ip$dig2 "
	echo "DNS server3: $ns3_ip$dig3 "
	echo "DNS server4: $ns4_ip$dig4"
	echo "DNS server5: $ns5_ip$dig5"
}
#------------------------------------------------------
# Startup self-check
#check internet connection
if ping -c 1 -W 1 $ns1_ip >/dev/null 2>&1; then
	echo "Successfully started script."
else
	echo "Internet connection is down."
	exit 1
fi
# Give the user the option to test domains or test speed of the nameservers.
PS3='Please enter your choice: '
options=("Bulk DNS Lookup" "DNS Response Time Test" "Quit")
select opt in "${options[@]}"; do
	case $opt in
	"Bulk DNS Lookup")
		dnsBulkLookup
		;;
	"DNS Response Time Test")
		dnsSpeed
		;;
	"Quit")
		break
		;;
	*) echo "invalid option $REPLY" ;;
	esac
done