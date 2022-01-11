	section COMMAND
	public	COMND, DISPT

; ------------------------------------------------------ 
;
;            =--  COMMAND MODE  --=
; This is the main loop of cutest.  We get and process 
; commands forever.
;  
; ------------------------------------------------------ 
COMND:	lxi	SP,TOP_OF_STACK	;set STACK POINTER
	call	write_prompt		;PUT PROMPT ON SCREEN
	call	read_line	;INIT TO GET COMMAND LINE
	call	process_command	;PROCESS THE LINE
	jmp	COMND		;OVER AND OVER

; --- Process Command ---
; process_command takes the contents of the string
; contained in de, looks up the appropriate command
; and dispatches to the appropriate address.
; -----------------------
process_command:	\
	lxi	H,START		;PREP SO THAT HL WILL PT TO CUTER LATER
	push	H			;PLACE PTR TO CUTER ON STACK FOR LATER DISPT
	call	find_non_blank	;SCAN PAST BLANKS
	jz	error_handler		;NO COMMAND?
	xchg				;HL HAS FIRST CHR
	
	if STRINGS = TRUE ; Process help question mark
	ldax	H
	cpi	'?'
	jnz	+
	lxi	H, HELP
	xthl
	ret
	endif

+:	lxi	D,CMDTAB	;POINT TO COMMAND TABLE
	call	find_cmd	;SEE if in PRIMARY TABLE
	CZ	find_custom_cmd	;TRY CUSTOM ONLY if NOT PRIMARY COMMAND
; **** DROP THRU TO DISP0 ***


;
; THIS ROUTINE DISPTACHES TO THE addr AT CONTENTS OF HL.
; Assumed that previous HL was pushed to the stack, and
; we restore the previous value before calling the routine.
;
DISP0:	equ	$	;HERE TO EITHER DISPATCH OR DO ERROR
	jz	error_handler		;NOT in EITHER TABLE
	inx	D	;PT DE TO addr OF RTN
	xchg		;HL=addr OF addr OF RTN
DISPT:	equ	$	;DISPATCH
	mov	A,M	;LOW BYTE
	inx	H
	mov	H,M	;HI BYTE
	mov	L,A	;AND LO, HL NOW COMPLETE
	xthl		;HL RESTORED AND ADDR ON STACK
	mov	A,L	;ALWAYS PASS L in "A" (PRIMARILY FOR SET'S)
	
	; This following ret is a bit confusing since 
	; we're not RETURNing from a Subroutine. Instead,
	; we're jumping to the dispatch ADDRESS which is
	; now top of the stack and HL is now the value
	; pushed to the stack before calling dispatch
	ret		;OFF TO ROUTINE

; --- Find Command Subroutine ---
;
;   This routine searches through a table, pointed to
;  by DE, for a double character match of the string
;  point to by HL. if no match is found the scan ends
;  with the zero flag set, else non-zero set.
;
;  find_custom_cmd -- Search through CUSTOM_COMMAND_TAB
;  find_cmd -- Search through table loaded in DE
; -------------------------------
find_custom_cmd:	\
	lxi	D,CUSTOM_COMMAND_TAB	
find_cmd:	\
	ldax	D	; Load
	ora	A	;TEST FOR TABLE END
	rz		;NOT FOUND POST THAT AND RETURN
	push	H	;SAVE START OF SCAN ADDRESS
	cmp	M	;TEST FIRST CHR
	inx	D
	jnz	+	
;
	inx	H
	ldax	D
	cmp	M	;NOW SECOND CHARACTER
	jnz	+	;GOODNESS
;
	pop	H	;RETURN HL TO PT TO CHAR START
	ora	A	;FORCE TO NON-ZERO FLAG
	ret		;LET callER KNOW
;
;
+:	inx	D	;GO TO NEXT ENTRY
	inx	D
	inx	D
	pop	H	;GET BACK ORIGINAL ADDRESS
	jmp	find_cmd	;CONTINUE SEARCH


; COMMAND TABLE
; To modify the command table entry's, edit config/commands.asm
CMDTAB: \
	get_comtab_entry 0
	get_comtab_entry 1
	get_comtab_entry 2
	get_comtab_entry 3
	get_comtab_entry 4
	get_comtab_entry 5
	get_comtab_entry 6
	get_comtab_entry 7
	get_comtab_entry 8
	get_comtab_entry 9
	get_comtab_entry 10
	get_comtab_entry 11
	get_comtab_entry 12
	get_comtab_entry 13
	get_comtab_entry 14
	get_comtab_entry 15
	db	0

; --- write_prompt ---
; output a crlf followed by a prompt
; --------------------
write_prompt: \
	call	write_crlf
	mvi	B,'>'	;THE PROMPT 
	call	SOUT	;PUT IT ON THE SCREEN
	mvi	B,' '	;SPACE
	jmp	SOUT	;PUT IT ON THE SCREEN

; --- find_next_arg ---
; This routine will scan until it find the first blank character,
; and then once a blank character is identified, it will continue
; to scan until a non-blank is identified.  This is the first
; character of the next argument in the command.
; Arguments:
;	DE - set to input buffer
; Returns:
;	zero flag set if it was unable to find another argument
;	zero flag not set if found another argu
; Returns non-zero if it has found another argument.
; 	The address of the argument will be loaded in DE 
; --------------------
find_next_arg:	\
	mvi	C,12	;MAXIMUM COMMAND STRING
-:	ldax	D
	cpi	BLANK
	jz	find_non_blank	;GOT A BLANK NOW SCAN PAST IT
	inx	D
	cpi	'='	;A equAL WILL ALSO STOP US (AT NEXT CHAR)
	jz	find_non_blank	;FOUND, DE PT TO NEXT CHAR
	dcr	C	;NO MORE THAN TWELVE
	jnz	-
	ret		;GO BACK WITH ZERO FLAG set
;
;
;  SCAN PAST UP TO 10 BLANK POSITIONS LOOKING FOR
; A NON BLANK CHARACTER.
;
find_non_blank:	\
	mvi	C,10	;SCAN TO FIRST NON BLANK CHR WITHin 10
find_non_blank1:	\
	ldax	D	;GET NEXT CHARACTER
	cpi	SPACE
	rnz		;WE'RE PAST THEM
	inx	D	;NEXT SCAN ADDRESS
	dcr	C
	rz		;COMMAND ERROR
	jmp	find_non_blank1	;KEEP LOOPING
;
; get_hex_arg
; This routine find the next argument, converts it from hex,
; and stores the results IN HL.  On error we call the error handler.
; Arguments:
;   DE - Pointer to input buffer
; RETURNs:
;   Hex value stored into H/L
get_hex_arg:	\
	call	find_next_arg
	jz	error_handler

; --- hex_str_to_hl ---
; This routine converts ascii digits into binary following
; a standard hex conversion.  The scan stops when an ascii
; space is encountered.  Errors get sent to error_handler.
; Arguments:
;    DE - Pointer to string
; Returns:
;    Hex valued into H/L
; -------------------
hex_str_to_hl: \
	lxi	H,0	;CLEAR H & L
-:	ldax	D	;GET CHARACTER
	cpi	20H	;IS IT A SPACE?
	rz		;if SO
	cpi	'/'
	rz
	cpi	':'
	rz

	; dad H adds HL to HL, thus shifting left one bit	
	; We shift left four bits.
	dad	H
	dad	H
	dad	H
	dad	H
	call	+	;DO THE CONVERSION
	jnc	error_handler	;NOT VALID HEXIDECIMAL VALUE
	add	L
	mov	L,A	;movE IT IN
	inx	D	;BUMP THE POINTER
	jmp	-
;
+:	SUI	48	;REMOVE ASCII BIAS
	cpi	10
	RC		;if LESS THAN 9
	SUI	7	;IT'S A LETTER??
	cpi	10H
	ret		;WITH TEST in HAND
;
; GET_OPT_HEX_ARG
; THIS ROUTINE WILL SEE if A FIELD (OPERAND) IS PRESENT.
; if NOT, THEN HL WILL REMAIN AS THEY WERE ON ENTRY.
; if IT WAS PRESENT, THEN HL=THAT VALUE in HEX.
;
GET_OPT_HEX_ARG: \
	call	find_next_arg	;SEE if FIELD IS PRESENT
	rz		;RETURN LEAVING HL AS THEY WERE ON ENTRY
	call	hex_str_to_hl	;FIELD IS THERE, GO GET IT
	ret		;HL= EITHER OPTIONAL FIELD (HEX), OR AS IT WAS
	
; ---Error Handler Subroutine ---
; Both of these labels are for handling a command syntax error.
; 
; error_handler_DE - de contains pointer to the syntax error
; error_handler_HL - hl contains pointer to the syntax error
;
; -------------------------------
error_handler:	\
	call	write_crlf
	mvi	B,'?'	;set UP THE ????
	call	SOUT	;INDICATE INPUT NOT VALID
	jmp	COMND	;NOW READY FOR NEXT INPUT




	include dump.asm
	include entr.asm
	include exec.asm
	include cassette.asm
	include set.asm
	include custom.asm
	if STRINGS=TRUE
	include help.asm
	endif
	endsection COMMAND

