	section COMMAND
	public	COMND, DISPT, register_command
pre    set $

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
	push d ; Store the pointer to the cmd
	
	; if STRINGS = TRUE ; Process help question mark
	; ldax	H
	; cpi	'?'
	; jnz	+
	; lxi	H, HELP
	; xthl
	; ret
	; endif


+:	call find_command
	jz error_handler ; Command not found
	pop d
	; HL points to command pointer
	jmp DISPT

; --- DISPT ---
; Dispatches to address stored in memory, pointed to by HL
; Desired contents of HL must be top of the stack
; DE not affected
; -------------
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
; Arguments:
;    DE - pointer to command string
; -------------------------------
find_command:
	; Load command string into registers	
	ldax d
	mov b, a 
	inx d
	ldax d
	mov e, a
	mov d, b
	; d now contains the first char
	; e now contains the second char
	
	lxi h, COMMAND_TAB
.loop:
	; Save h, we use it to keep track
	; of where in the command table we are.
	push h
	mov a, m ; load first byte

	; Check if first byte is null
	; if it is, that marks the end of the table
	ora a ; set flags
	jnz +

	; End of the table
	pop h ; fix the stack
	ret ; return zero
+:	
	inx h
	mov h, m ; high byte
	mov l, a ; AND LO, HL NOW COMPLETE

	; Load characters into B, C
	mov b, m
	inx h
	mov c, m
	
	pop h
	
	; Compare first char
	mov a, b
	cmp d
	jnz .not_match

	; Compare second char
	mov a, c
	cmp e
	jnz .not_match

	; Match!
	; HL is pointing at command tab
	; Point it at the command record
	call get_command_record
	; HL is now pointing to command record
	; Add 5 to skip the name

	mvi B, 0
	mvi C, 5
	dad b 
	
	; HL should now be pointing to the command pointer
	mvi a, 1
	cpi 2
	ret
	
.not_match:
	inx h
	inx h
	jmp .loop


; --- get_command_record ---
; Arguments:
;    HL - points to command record pointer
; Returns:
;    HL - points to command record
; Mutates: A
; -----------------------
get_command_record:
	mov	a, m ; low byte
	inx	h
	mov	h, m ; high byte
	mov	l, a ; AND LO, HL NOW COMPLETE
	ret


; --- register_command ---
; Registers a command.
; Command record must be pointed to by HL
; Command record format:
;    Name - 5 bytes, padded by spaces
;    Entry Point - 2 bytes
;    Help Strings - Any length null terminated
; ------------------------
register_command:
	lxi d, COMMAND_TAB
.loop:
	ldax d	; Load first byte of table
	inx d
	ora a
	jnz +
	ldax d	; Load second byte of table
	ora a	
+:
	inx d
	jnz .loop
	
	; Last two bytes of table were both null
	dcx d
	dcx d
	; Move command ptr into table
	xchg
	; HL now points to empty table spot
	; DE now points to command record
	mov m, e
	inx h
	mov m, d
	ret

; To modify the command table entry's, edit config/commands.asm
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
	cpi	'='	;A EQUAL WILL ALSO STOP US (AT NEXT CHAR)
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
	call hex_char_to_value
	jnc	error_handler	;NOT VALID HEXIDECIMAL VALUE
	add	L
	mov	L,A	;MOVE IT IN
	inx	D	;BUMP THE POINTER
	jmp	-

; ---- hex_chars_to_byte ----
; Convert a pair of chars in hex to a byte
; Arguments:
;	DE - pointer to bytes
; Returns:
;	A - hex value
;	No carry indicates error
;	DE incremented by two
; Mutates: A, B, C, DE
; ---------------------------
hex_chars_to_byte: \
	; Convert A hex -> value
	xchg
	mov a, m
	inx h
	mov b, m	
	inx h
	xchg
	call hex_char_to_value
	rnc

	; Shift value of A to the highest 4 bits
	rlc
	rlc
	rlc
	rlc
	
	; Store the top 4-bits in c
	mov c, a

	; Convert the next char to the lowest 4-bits
	mov a, b
	call hex_char_to_value
	rnc

	; Add back the highest 4 bits
	add c
	ret

; ---- hex_char_to_value ----
; Convert a signle char in hex to a value
; Arguments:
;	A - char
; Returns:
;	A - value
;	No carry indicates error
; ---------------------------
hex_char_to_value: \
	sui	'0'
	cpi	10		; If less than 10, return
	rc
	sui	'A'-'9'-1	; 7 chars between 9 and A 
	cpi	10H
	ret	
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




	MESSAGE "(CMD)  prev \{$ - pre}"
pre    set $
	include dump.asm
	MESSAGE "     prev \{$ - pre}"
pre    set $
	include entr.asm
	MESSAGE "     prev \{$ - pre}"
pre    set $
	include exec.asm
	MESSAGE "     prev \{$ - pre}"
pre    set $
	include cassette.asm
	MESSAGE "     prev \{$ - pre}"
pre    set $
	include set.asm
	MESSAGE "     prev \{$ - pre}"
pre    set $
	;include custom.asm
	; if STRINGS=TRUE
	; include help.asm
	; include inout.asm
	; include ihex.asm
	; endif
	endsection COMMAND

