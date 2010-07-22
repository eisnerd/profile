for I; do
	i=`dirname "$I/snip"`
	j=`ls -1 "$i"|sed -n s/\\.urls$//p|head -1`
	if [ -z "$j" ]; then
		echo Nothing for $i
	elif [ -e "/media/1422-2717/Zork/nax/done/$j.asp" ]; then
		echo $i -- Original
		cp "/media/1422-2717/Zork/nax/done/$j.asp" /media/1422-2717/Zork/nax/
	else
		echo $i -\> $j
		if echo $i|grep -q ·; then
			echo "${i#*/}"
		else
			echo "${i%/*}"· "${i#*/}"
		fi > /media/1422-2717/Zork/nax/$j.asp
		cat "$i/snip" >> /media/1422-2717/Zork/nax/$j.asp
	fi
done

