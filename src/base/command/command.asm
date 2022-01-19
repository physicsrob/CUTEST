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
	push d ; Store the pointer to the cmd string

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
	; h points to current position in command_tab
	mov a, m
	cmp d
	inx h
	jnz +

	mov a, m
	cmp e
	jnz .not_match

	; Match!
	inx h
	; Force non-zero
	mvi a, 1
	ora a
	; hl now points to command pointer
	ret

+:
	; Not match
	; Check a to see if it's null (indicating end of table)
	ora a
	rz
	
	; not a match, not end of table
.not_match:
	inx h
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
; Command record must be pointed to by DE
; Command record format:
;    Name - 2 bytes, padded by spaces
;    Entry Point - 2 bytes
; ------------------------
register_command:
	lxi h, COMMAND_TAB
.loop:
	mov a, m
	inx h
	ora a
	jnz +
	ora m
+:
	inx h
	inx h
	inx h
	jnz .loop
	
	; Last entry of table was null
	dcx h
	dcx h
	dcx h
	dcx h

	; Copy record to table
	mvi b, 4
	call memcpy
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



builtin_cmd_tab:
	db 'DU'
	dw DUMP
	db 'EN'
	dw ENTER
	db 'SE'
	dw CSET
	db 'EX'
	dw EXEC
	db 'GE'    ;GET
	dw TLOAD
	db 'SA'    ;SAVE
	dw TSAVE
	db 'XE'    ;XEQ
	dw TXEQ
	db 'CA'    ;CAT
	dw TLIST
	db 0
	db 0

load_cmd_tab:
	lxi d, COMMAND_TAB

	; Swap D/H
	xchg
	; D=Ptr to new entries
	; H=Ptr to current table

	; Skip non null entries in command table
-:
	mov a, m
	inx h
	ora m
	dcx h ; Doesn't affect status
	; If zero, we're at the end of table and should continue
	jz +
	; Not zero, so we still need to skip entries
	inx h
	inx h
	inx h
	inx h
	jmp -

+:
	; H now points to first empty position of cmd table
	; Loop through copying

	xchg
	; H=Ptr to new entries
	; D=Ptr to firts open position in current table
.loop:
	mov a, m
	inx h
	ora m
	dcx h ; Doesn't affect status
	
	; Check if last two bytes were zero, end of copy
	rz 	
	; Otherwise, perform the copy for next 4 bytes
	mvi b, 4
-:
	mov a, m
	stax d
	inx h
	inx d
	dcr b
	jnz -
	jmp .loop
	
	
	include dump.asm
	include entr.asm
	include exec.asm
	include cassette.asm
	include set.asm
	
