if [ ! -d tmp ]; then
	mkdir tmp
fi


ca65 -I kernel -I shell -g os.s -o tmp/os.o &&
ld65 -C os.cfg tmp/os.o -o tmp/os.bin -Ln tmp/os.lbl
