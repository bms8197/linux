#!/bin/sh

# cd to /etc folder
cd /etc

# define what countries to block
countries=(CN RU AT GE)

echo "Countries to block:"
echo "-----"
printf "%s " "${countries[@]}"
echo ""

sleep 3

for country in "${countries[@]}"
do

  # create ipset chain for each country
  ipset -N ${country,,} hash:net

  #remove old country list files
  rm -f ${country,,}.zone

  # get new country file
  wget -P . http://www.ipdeny.com/ipblocks/data/countries/${country,,}.zone

  # add ip ranges to ipset chain
  for i in $(cat /etc/${country,,}.zone ); do ipset -A ${country,,} $i; done

  # delete previous ipset iptables rule
  iptables -D INPUT -p tcp -m set --match-set ${country,,} src -j DROP

  # add iptables rule for ipset
  iptables -A INPUT -p tcp -m set --match-set ${country,,} src -j DROP

done
