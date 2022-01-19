CUSET:	equ	$	;TRY TO set/CLEAR CUSTOM ROUTINE addr
	call	NAME0	;GET A NAME (S/B 2 CHARS OR MORE)
	lxi	H,COMND	;PT HERE in CASE addr NOT GIVEN
	call	GET_OPT_HEX_ARG	;GET OPTIONAL OPERAND if ANY
	push	H	;SAVE THAT VALUE (if ANY)
	lxi	H,THEAD	;PT TO NAME
	call	find_custom_cmd	;SEE if NAME IS KNOWN in CUST TABLE
	jz	CUSE2	;NO--PROCEED TO KNOW IT
	dcx	D	;DE PT TO 1ST CHAR OF NAME in TBL
	mvi	M,0	;(HL CAME BACK PT'ING TO THEAD)  CLR THIS NAME
CUSE2:	equ	$	;ENTER NEW ONE in TBL
	mov	A,M	;GET 1ST CHAR OF NAME
	stax	D	;PUT NAME INTO TABLE
	inx	D
	inx	H
	mov	A,M	;GET 2ND CHAR OF NAME
	stax	D	;NAME IS NOW POSTED
	inx	D	;PT TO 1ST BYTE OF addr
	pop	H	;RESTORE SAVED RTN addr
	xchg		;DE=RTN addr, HL=THIS CU ENTRY
	mov	M,E	;LO BYTE
	inx	H
	mov	M,D	;AND HI BYTE
	ret		;ALL DONE