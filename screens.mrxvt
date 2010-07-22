n=`/usr/bin/screen -ls | grep -c Detached`
if [ $n -eq 0 ]
then
	echo " -ip 0 -profile0.e \"/usr/bin/screen -q -A -a -U\""
else

echo -n " -ip `seq -s, 0 $((n-1))`"

N=0
#for i in `ls -1 /var/run/screen/S-eisd/`
for i in `/usr/bin/screen -ls |/bin/grep Detached|/usr/bin/cut -f 2`
do
	echo -n " -profile$N.e \"/usr/bin/screen -q -a -r $i\""
	(( N++ ))
done
#echo -n " ++NewTab \"/usr/bin/screen -R\" "
fi
