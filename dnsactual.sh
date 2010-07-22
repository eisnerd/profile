 ##############################################################################
 #
 #  application name: dnsactual
 #  other files: dnsactual.conf (keeps the last updated ip)
 #               dnsactual.log  (register date & time of the actualization)
 #  Author: Ernest Danton
 #  Date: 01/29/2007
 ##############################################################################

 if test -f /etc/freedns/dnsactual.conf
   then
   CacheIP=$(cat /etc/freedns/dnsactual.conf)
 fi
 #echo $CacheIP
 CurreIP=$(wget http://freedns.afraid.org/dynamic/check.php -o /dev/null -O /dev/stdout | grep Detected | cut -d : -f 2 | cut -d '<' -
f 1 | tr -d " ")
 #echo $CurreIP
 if [ "$CurreIP" = "$CacheIP" ]
 then
   # Both IP are equal
   echo "Update not required..."
 else
   # The IP has change
   echo "Updating http://free.afraid.org with " $CurreIP
   wget http://freedns.afraid.org/dynamic/update.php?xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -o /dev/null -O /dev/stdout
   echo `date`  "Updating log with IP " $CurreIP >> dnsactual.log
 fi
 rm -f /etc/freedns/dnsactual.conf
 echo $CurreIP > /etc/freedns/dnsactual.conf
