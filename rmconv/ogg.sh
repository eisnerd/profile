sh ~/bin/rmconv/wav-1.sh $*; sh ~/bin/rmconv/wav-2.sh 0.15 $*
for i; do oggenc -q 6 $i.wav; rm $i.wav; done

