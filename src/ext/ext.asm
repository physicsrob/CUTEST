       ORG EXT_ADDRESS

       ; Identify ourselves
       MOV B, B

       include strutil.asm
       include strings.asm

       ; Display Banner
	lxi	H, BANNER_STR
	call	write_line
