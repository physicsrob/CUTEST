;
;
;
;
;      "SET" COMMAND
;
;   THIS ROUTINE GETS THE ASSOCIATED PARAMETER AND
;   DISPATCHES TO THE PROPER ROUTINE FOR setTING
;   MEMORY VALUES.
;
	PUBLIC CSET
CSET:	call	find_next_arg	;SCAN TO SECONDARY COMMAND
	jz	error_handler	;MUST HAVE AT LEAST SOMETHING!!
	
	; Check for question mark
	ldax	D
	cpi	'?'
	jnz +
	;
	; Set help triggered
	;
	; Load command pointer
	lxi d, SETHELP_CMD
	ldax d
	mov l, a
	ldax d
	mov h, a
	; Check if it's null
	ora l
	jz error_handler ; No help command loaded
	pchl ; Jump to it

+:	push	D	;SAVE SCAN ADDRESS
	call	get_hex_arg	;CONVERT FOLLOWING VALUE
	xthl		;HL=SAVED SCAN addr AND STACK=VALUE
	lxi	D,SETTAB	;SECONDARY COMMAND TABLE
	call	find_cmd	;TRY TO LOCATE IT
	jz	error_handler ; Not found
	inx	D	;Point DE to address of address we'll dispatch to
	xchg
	; HL now contains address of address to dispatch to
	; DE now contains address of command line string  
	jmp DISPT
;
;
;  THIS ROUTINE SETS THE TAPE SPEED
;
TASPD:	equ	$	;GET CONVERTED VALUE
	ora	A	;IS IT ZERO?
	jz	SETSP	;YES--THAT IS A PROPER SPEED
	mvi	A,32	;NO--SET SPEED PROPERLY THEN
SETSP:	sta	TSPD
	ret
;
;
	PUBLIC STSPD
STSPD:	equ	$	;VDM ESCAPE SEQUENCE COMES HERE
	mov	A,B	;GET CHAR FOR FOLLOWING DISPD
DISPD:	equ	$	;set DISPLAY SPEED
	sta	SPEED
	ret
;
;
SETIN:	equ	$	;set AN INPUT PSUEDO PORT
	sta	IPORT
	ret
;
;
SETOT:	equ	$	;set AN OUTPUT PSUEDO PORT
	sta	OPORT
	ret
;
;
SETCI:	equ	$	;DEFINE USER INPUT RTN addr
	shld	USER_INP_PTR
	ret
;
;
SETCO:	equ	$	;DEFINE USER OUTPUT RTN addr
	shld	USER_OUT_PTR
	ret
;
;
SETTY:	equ	$	;set TAPE HDR TYPE
	sta	HTYPE
	ret
;
;
SETXQ:	equ	$	;set TAPE-EXECUTE addDR FOR HDR
	shld	XEQAD
	ret
;
;
SETNU:	equ	$	;HERE TO set NUMBER OF NULLS
	sta	NUCNT	;THIS IS IT
	ret
;
;
SETCR:	equ	$	;set CRC TO BE NORMAL, OR IGNORE CRC ERRORS
	sta	IGNCR	;FF=IGNORE CRC ERRORS, ELSE=NORMAL
	ret

; SECONDARY COMMAND TABLE FOR SET COMMAND
SETTAB:	\
	db	'TA'	;set TAPE SPEED
	dw	TASPD
	db	'S='	;set DISPLAY SPEED
	dw	DISPD
	db	'I='	;set INPUT PORT
	dw	SETIN
	db	'O='	;set OUTPUT PORT
	dw	SETOT
	db	'CI'	;set CUSTOM DRIVER ADDRESS
	dw	SETCI
	db	'CO'	;set CUSTOM OUTPUT DRIVER ADDRESS
	dw	SETCO
	db	'XE'	;set HEADER XEQ ADDRESS
	dw	SETXQ
	db	'TY'	;set HEADER TYPE
	dw	SETTY
	db	'N='	;set NUMBER OF NULLS
	dw	SETNU
	db	'CR'	;set CRC (NORMAL OR IGNORE CRC ERRORS)
	dw	SETCR
	db	0	;END OF TABLE MARK


find_cmd:	\
	ldax	D	; Load first byte of table
	ora	A	;TEST FOR TABLE END
	rz		;NOT FOUND POST THAT AND RETURN
	push	H	;SAVE START OF SCAN ADDRESS
	cmp	M	;TEST FIRST CHR
	inx	D	; Does not affect status flags
	jnz	+	; Jump to + if we don't match
;
	inx	H
	ldax	D
	cmp	M	; Compare second char
	jnz	+	; Jump to + if we don't match
	
	; We found it!
	pop	H	;RETURN HL TO PT TO CHAR START
	ora	A	;FORCE TO NON-ZERO FLAG
	; HL now points to initial value
	; DE now points to second char of name  
	ret		;LET CALLER KNOW
;
;
+:	inx	D	;GO TO NEXT ENTRY
	inx	D
	inx	D
	pop	H	;GET BACK oriGINAL ADDRESS
	jmp	find_cmd	;CONTINUE SEARCH