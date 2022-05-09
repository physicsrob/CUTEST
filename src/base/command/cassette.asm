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

	; Get name from command line and store in THEAD
	call	NAME0
	
	; Get and save start address to stack
	call	get_hex_arg	;GET START ADDRESS
	push	H 
	
	; Get end address 
	call	get_hex_arg	;GET END addr (REQUIRED)
	
	; Put end address in stack, and pull start address back to HL
	xthl

	; Save start address on stack
	push	H

	; Start address is now the top of the stack and also in HL

	
	; We supports overwriting the start address when saving
	; to tape.  This allows you to specify where the saved
	; file will be loaded to.
	; GET_OPT_HEX_ARG will leave HL put if there's nothing
	; else on the command line.
	call	GET_OPT_HEX_ARG

	; HL now contains the start address or the overwritten start address
	; Save it.
	shld	LOADR	;EITHER ACTUAL START, OR OVERRIDE INTO HDR

	; Note: I think we could get rid of this pop and the corresponding push?
	; It doesn't seem like we're manipulating HL in between.
	pop	H	; Restore HL to start address
	
	; Pop the end address to DE. 
	pop	D	;DE=END addr

	; Put start address back onto stack
	push	H
	
	; Move lower byte of end address (DE) into accumulator
	mov	A,E	;SIZE=END-START+1
	
	; Subtract lower byte of start address (HL) from accumulator
	sub	L
	
	; Accumulator now has the lower byte of END-START
	; Store it in L
	mov	L,A

	; Move the upper byte of end address (DE) into accumulator
	mov	A,D

	; Subtract off the carry bit if we had a carry previously
	sbi	0	;THIS EQUALS A "SBB H"

	; Subtract the upper byte of the start address (HL)  from the accumulator
	sub	H	;THIS IS NEEDED
	
	; Store result of upper byte subtraction in H (we already stored the lower byte subtraction in L)
	mov	H,A

	; Add 1, because Size = End - Start + 1
	inx	H

	; Store the size into BLOCL
	shld	BLOCK	;STORE THE SIZE
	
	; Push size onto stack
	push	H	;SAVE AS THE BLOCK SIZE
;
	; Point H to THEAD, where we copied the name
	lxi	H,THEAD	;PT TO HEADER TO WRITE
	
	; Write the header
	call	write_header	;TURN TAPE ON, THEN WRITE HEADER

	pop	D	;GET BACK THE SIZE
	pop	H	;AND GET BACK THE ACTUAL START ADDRESS
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

