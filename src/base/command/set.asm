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
CSET:	call	find_next_arg	;SCAN TO SECONDARY COMMAND
	jz	error_handler	;MUST HAVE AT LEAST SOMETHING!!
	
+:	push	D ; Store address to key
	call	get_hex_arg ; Convert the set value
	; Set value is now stored into HL
	xthl
	; HL = Key address, Stack = Set value
	
	; Load key characters into B, C
	mov b, m
	inx h
	mov c, m

	lxi D, SET_TAB
	; Loop through table looking for match

.loop:	
	; Compare first char
	ldax d
	inx d
	cmp b
	jnz .not_match
	
	; Compare second char
	ldax d
	cmp c
	jnz .not_match

	; Match!
	inx d ; Skip past the 2nd char
	
	; Setup for setter call
	; We'll make it:
	;    top of stack: setter address
	;    HL - destination address 
	;    BC - value to set
	; and then return to dispatch there

	; Pop the stack (set value) into b
	pop b

	; Load setter address
	ldax d
	mov l, a
	inx d
	ldax d
	mov h, a
	inx d
	
	push h ; Put setter address on stack
	
	; Load destination address
	ldax d
	mov l, a
	inx d
	ldax d
	mov h, a
	inx d

	ret ; Dispatch to setter


.not_match:
	; Increment D by 5 (we already incremented 1)
	inx d
	inx d
	inx d
	inx d
	inx d
	
	; Check for end of table
	ldax d
	ora a ; set flags
	jz error_handler ; command not found
	
	; Not end of table -- keep going
	jmp .loop
	



SET_TAB:	\
	db 'TA' ; set tape speed 
	dw tape_speed_setter
	dw TSPD

	db 'S=' ; set VDM speed
	dw byte_setter
	dw SPEED

	db 'I=' ; set input port
	dw byte_setter
	dw IPORT

	db 'O=' ; set output port 
	dw byte_setter
	dw OPORT

	db 'XE' ; set header XEQ address
	dw word_setter
	dw XEQAD

	db 'TY' ; set header type
	dw byte_setter
	dw HTYPE

	db 'N=' ; set number of nulls
	dw byte_setter
	dw NUCNT
	
	db 'CR' ; set CRC check 
	dw byte_setter
	dw IGNCR 

	db	0	;END OF TABLE MARK

; --- word_setter ---
; Called by set dispatch.
; Arguments:
;    HL - address of variable to change
;    BC - value to set
; -------------------	
word_setter:
	mov m, c
	inx h
	mov m, b
	ret
	
; --- byte_setter ---
; Called by set dispatch.
; Arguments:
;    HL - address of variable to change
;    BC - value to set
; -------------------	
byte_setter:
	mov m, c
	ret

; --- tape_speed_setter ---
; Called by set dispatch.
; Arguments:
;    HL - address of variable to change
;    BC - value to set
; -------------------	
tape_speed_setter:
	xra a
	ora C
       jz + 
	; If tape speed is non-zero, store 32
	mvi m, 32
	ret
+:
	; If tape speed is zero, store zero
	mvi m, 0
	ret
