#!/bin/bash -x
root="${1%*.asp}"
doc="$root.asp"
screen -X title "`realpath \"$doc\"|sed \"s_.*/Zork/nax[^/]*/batches/\([^/]*\).*_\1 ${root##*/}_\"`"
kind=`head -2 "$doc" |grep -c "^<doc>$"`
echo Beginning $root \($doc\)
conversion='sed_fat_from_xml'
title=$(if [ $kind = 0 ]; then tr \\n \  < "$doc"|sed "s_.*<title>\(.*\) - Naxos Music Library</title>.*_\1_"; else head -1 "$doc"; fi|$conversion)
echo -n $title
#if (find {~/Music,/media}/Zork/nax/ /green/eisd/second/* /green/eisd/*/{,Music/}nax /green/eisd/darkstar/eisd/Music/nax -maxdepth 1 -iname "$title"; find /net/sd -name $root\\.\*)|grep -q .; then
cid="`grep 'name="cid"' \"$doc\"|sed 's_.*content="\([^"]*\)".*_\1_'`"
if
	if [ -z "$use_cid" ]; then
		find {{~/Music,/media}/Zork,/backup/Music}/nax/ /green/eisd/second/* /green/eisd/*/{,Music/}nax /green/eisd/darkstar/eisd/Music/nax -maxdepth 1 -iname "$title"|grep -q .
	else
		[ -z "$cid" -o -e "/green/eisd/second/bycid/$cid.asp" ]
	fi
then
	echo done
	mkdir -p done
	mv "$doc" done
	exit
#elif find /net/sd -name ${root##*/}\\.\*|grep -q .; then
#	echo done
#	mkdir -p lost/sd
#	mv "$doc" lost/sd
#	exit
else
#	mv "$doc" lost
	echo NEW
fi

tmp="$root"
mkdir -p "$tmp" &&
if [ -s "$title" ]; then cp -a "$title"/* "$tmp"; fi &&
cp -a tree_q02.xq dl "$tmp" &&
pushd "$tmp" &&
touch "title.$title" &&
(
#if [ "${doc%*.snip}" = "$doc" ]; then
if [ $kind = 0 ]; then
echo "<doc>"
grep \\\(streamw\\?\\.asp\\\|selectMemberTracks\\\) "`dirs -l +1`/$doc" |sed "s_\(<input[^/]*\)>_\1 />_g"|sed s/\\xC2\\xA0/\ /g|sed "s_\<br */\?_br/_g"|sed "s_[ \t]*\([^ ].*\)_<line>\1</line>_"|tr -d |sed "s/&nbsp;/ /g"|sed "s/2\.0&/2.0&amp;/g"
#grep \\\(streamw\\?\\.asp\\\|selectMemberTracks\\\) "`dirs -l +1`/$doc" |sed "/<input/s_>_>_g"|sed s/\\xC2\\xA0/\ /g|sed "s_\<br_br_g"|sed "s_[ \t]*\([^ ].*\)_<line>\1</line>_"|tr -d 
|sed "s/&nbsp;/ /g"|sed "s/2\.0&/2.0&amp;/g"
#grep \\\(streamw\\?\\.asp\\\|selectMemberTracks\\\) "`dirs -l +1`/$doc" |sed "/<input/s_>_ />_g" |sed s/\\xC2\\xA0/\ /g|sed "s_\<br_br/_g"|sed "s_[ \t]*\([^ ].*\)_<line>\1</line>_"
#grep \\\(streamw\\?\\.asp\\\|\<title\>\\\|selectMemberTracks\\\) dsch-violin-palmer.asp |sed s/\\xC2\\xA0/\ /g|sed "s_\<br_br/_g"|sed "s_[ \t]*\([^ ].*\)_<line>\1</line>_"
echo "</doc>"
#grep streamw\\?\\.asp dsch-violin-palmer.asp |sed s/\\xC2\\xA0/\ /g|sed "s_ \?<br.\?>\([^<]*\)<a[^>]*>\(.*\)</a>_\2; \1_g"|sed "s_[ \t]*\([^ ].*\)_\1_"|sed "s/^.\{4\}//"|sed "s_</a>.-_ -_"|less
else
	tail -n+2 "`dirs -l +1`/$doc"
fi
)>snip &&
galax-run tree_q02.xq -context-item snip -language xqueryp|sed "s/ __ /\"/g"|sed "s/&amp;/\&/g"|sed "s/&apos;/'/g"|sed "s/&gt;/>/g" |sed "s/&nbsp;/ /g"|sed 's/&quot;/"/g'|sed "s/ \+;\([^ ]\)/; \1/g"|grep -v "res>" >get
base="`basename \"$root\"`"
cat get|grep -v eyeD3|bash -s -x "$base." 2>&1|tee log &&
rm "title.$title" &&
grep ^file get |sed "s/^.*\(http:.*\)\"  |\.\/dl.*/\1/" > "$base.urls" &&
grep ^\ \ mv get |sed "s/^.*[^\\]\"\(\([^\"]\|\\\"\)*\)\"\ *$/\1/" > "$base.lst" &&
popd &&
if [ -n "$cid" -a -e "$title" ]; then title="$title $cid"; fi &&
mkdir -p "$title" &&
mv "$tmp/"* "$title" &&
rm -r "$tmp" &&
mkdir -p done &&
mv "$doc" done &&
[ -n "$cid" ] && ln -sf "`realpath \"done/$base.asp\"`" "/green/eisd/second/bycid/$cid.asp"
#mv "$root{.asp, Files}" done &&
echo Finished $root \($doc\)
echo
