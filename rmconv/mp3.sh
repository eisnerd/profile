sh ~/bin/rmconv/wav-1.sh $*; sh ~/bin/rmconv/wav-2.sh 0.25 $*
for i; do lame -h -V=4 --vbr-new $i.wav $i.mp3; rm $i.wav; done
