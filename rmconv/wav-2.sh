for i; do if [ $i != $1 ];
	then mv $i.wav .tmp.wav; sox -v $1 .tmp.wav $i.wav; rm .tmp.wav;
	fi; done

	
