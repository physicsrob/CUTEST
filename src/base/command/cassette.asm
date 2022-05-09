;
;
;
;   THIS ROUTINE PROCESSES THE XEQ AND GET COMMANDS
;
;
TXEQ:	db	3EH	;THIS BEGINS "mvi" OF THE "xra" FOLLOWING
TLOAD:	xra	A	;A=0 TLOAD, A=AF (#0) THEN XEQ
	push	PSW	;SAVE FLAG TO SAY WHETHER LOAD OR XEQ
	lxi	H,DHEAD	;PLACE DUMMY HDR HERE FOR COMPARES
	call	NAME	; Load name argument into DHEAD
	lxi	H,0	;ASSUME LOAD ADDR NOT GIVEN
	call	GET_OPT_HEX_ARG	;HL EITHER =0, OR OVERRIDE LOAD addr
;
	xchg		;PUT ADDRESS IN DE
	lxi	H,DHEAD	; Point to name argument previously loaded
	mov	A,M	;GET 1ST CHAR OF NAME
	ora	A	;IS THERE A NAME?
	jnz	+ ;YES--LOOK FOR IT
	lxi	H,THEAD	;PT TO SAME HDR TO LOAD NEXT FILE
	; So at this point
	; H = DHEAD which is loaded with the argument name if specified
	; H = THEAD which is uninitialized if the argument name is not specified 
+:
	call	cassette_read_block	;READ IN THE TAPE
	jc	TAERR	;TAPE ERROR?
;
	call	print_header	;PUT OUT THE HEADER PARAMETERS
	pop	PSW	;RESTORE FLAG SAYING WHETHER IT WAS LOAD OR XEQ
	ora	A
	rz		;AUTO XEQ NOT WANTED
	lda	HTYPE	;CHECK TYPE
	ora	A	;SET FLAGS
	jm	TAERR	;TYPE IS NON XEQ
	lda	THEAD+5
	ora	A
	jnz	TAERR	;THE BYTE MUST BE ZERO FOR AUTO XEQ
	lhld	XEQAD	;GET THE TAPE ADDRESS
	jmp	EXEC1	;AND GO OFF TO IT
;
;
;
;   THIS ROUTINE IS USED TO SAVE PROGRAMS AND DATA ON
;   THE CASSETTE UNIT.
;
;
TSAVE:	equ	$	;SAVE MEMORY IMAGE TO TAPE
	call	NAME0	;GET NAME AND UNIT
	call	get_hex_arg	;GET START ADDRESS
	push	H	;SAVE START addr FOR SIZE COMPUTATION LATER
	call	get_hex_arg	;GET END addr (REQUIRED)
	xthl		;HL=START addr NOW, STACK=END addr
	push	H	;STACK =START FOLLOWED BY END
	call	GET_OPT_HEX_ARG	;SEE if retRIEVE FROM addr
	shld	LOADR	;EITHER ACTUAL START, OR OVERRIDE INTO HDR
	pop	H	;;HL=START addr
	pop	D	;DE=END addr
	push	H	;PUT START BACK ONTO STACK
	mov	A,E	;SIZE=END-START+1
	sub	L
	mov	L,A
	mov	A,D
	sbi	0	;THIS EQUALS A "SBB H"
	sub	H	;THIS IS NEEDED
	mov	H,A
	inx	H
	shld	BLOCK	;STORE THE SIZE
	push	H	;SAVE AS THE BLOCK SIZE
;
	lxi	H,THEAD	;PT TO HEADER TO WRITE
	call	write_header	;TURN TAPE ON, THEN WRITE HEADER
	pop	D	;GET BACK THE SIZE
	pop	H	;AND GET BACK THE ACTUAL START addr
	jmp	WTAP1	;WRITE THE BLK (W/EXTRA push)
;
;   OUTPUT ERROR AND HEADER
;
TAERR:	call	write_crlf
	mvi	D,6
	lxi	H,ERrm
	call	NLOOP	;OUTPUT ERROR
	call	print_header	;THEN THE HEADER
	jmp	COMN1
;
ERrm:	db	'ERROR '

;
;
;              CAT COMMAND
;
;   THIS ROUTINE READS HEADERS FROM THE TAPE AND OUTPUTS
;   THEM TO THE OUTPUT DEVICE.  IT CONTINUES UNTIL THE
;   MODE KEY IS DEPRESSED.
;
TLIST:	equ	$	;PRODUCE A LIST OF FILES ON A TAPE
	call	write_crlf	;START ON A FRESH LINE
;
;
LLIST:	mvi	B,1
	call	tape_on	;TURN ON THE TAPE
LIST1:	call	read_header
	jc	COMN1	;TURN OFF THE TAPE UNIT
	jnz	LIST1
	call	print_header	;OUTPUT THE HEADER
	jmp	LLIST

;
;   THIS ROUTINE OUTPUTS THE NAME AND PARAMETERS OF
;   THEAD TO THE OUTPUT DEVICE.
;
;
print_header:	
	mvi	D,8
	lxi	H,THEAD-1  ;POINT TO THE HEADER
	call	NLOOP	;OUTPUT THE HEADER
	call	BOUT	;ANOTHER BLANK
	lhld	LOADR	;NOW THE LOAD ADDRESS
	call	write_hex_pair	;PUT IT OUT
	lhld	BLOCK	;AND THE BLOCK SIZE
	call	write_hex_pair
	jmp	write_crlf	;DO THE CRLF AND RETURN
;
;
NLOOP:	mov	A,M	;GET CHARACTER
	ora	A
	jnz	CHRLI	;IF IT ISN'T A ZERO
	mvi	A,' '	;SPACE OTHERWISE
CHRLI:	equ	$	;CHAR IS OK TO SEND
	call	write_a	;OUTPUT IT FROM A REG
	inx	H
	dcr	D
	jnz	NLOOP
	ret

