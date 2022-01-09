all:
	asl -x -L -cpu 8080 src/cutest.asm -o cutest.p
	p2hex cutest.p
	
	#dd if=/dev/zero of=CUTER13.ROM count=2048 ibs=1
	#dd if=CUTER13.bin of=CUTER13.ROM conv=notrunc
	#objcopy --input-target=ihex --output-target=binary CUTER13.hex CUTER13.bin
	
