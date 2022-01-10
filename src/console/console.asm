; --- in_pseudo ---
; Read one character from the pseudoport in A
; Result is in A
; ----------------- 
in_pseudo:	\
	push	H	;SAVE HL FM ENTRY
	lxi	H,ITAB
ioprc:	ani	3	;KEEP REGISTER "A" TO FOUR VALUES
	rlc		;COMPUTE ENTRY ADDRESS
	add	L
	mov	L,A	;WE HAVE ADDRESS
	jmp	DISPT	;DISPATCH TO IT

; --- out_pseudo ---
; Output one character (in B) to the pseudoport in A
; ------------------
out_pseudo:	\
	push	H	;SAVE REGS
	lxi	H,OTAB	;POINT TO OUTPUT DISPATCH TABLE
	jmp	ioprc	;DISPATCH FOR PROPER PSUEDO PORT

; OUTPUT DEVICE TABLE
; Note, to change this table, update config/pseudoports.asm
OTAB:	equ $
	ifdef out_0
	dw out_0
	endif
	ifdef out_1
	dw out_1
	endif
	ifdef out_2
	dw out_2
	endif
	ifdef out_3
	dw out_3
	endif

; INPUT DEVICE TABLE
; Note, to change this table, update config/pseudoports.asm
ITAB:	equ $
	ifdef in_0
	dw in_0
	endif
	ifdef in_1
	dw in_1
	endif
	ifdef in_2
	dw in_2
	endif
	ifdef in_3
	dw in_3
	endif


; --- read_line ---
; This rouTINE reads a line from the current pseudoport.
;
;  C/R   TERMINATES THE SEQUENCE ERASING ALL CHARS TO THE
;        RIGHT OF THE CURSOR
;  L/F   TERMINATES THE SEQUENCE
;  ESC   RESETS TO COMMAND MODE.
;
;  Results stored in INLIN buffer
; ----------------
read_line:	\
	lxi	H,INLIN-1	; Pointer to char in front of input buffer
	mvi	M,7	;MAKE SURE IT IS "BELL" TO KEEP FM DEL'ING TOO FAR
	inx	H	;NOW PT TO INPUT BFR
	shld	INPTR	;SAVE AS STARTING PTR
	mvi	A,80	;NUMBER OF CHARS in LINE (MAX)

; set the buffer to a string of blanks (' ')
.reset_loop:	\
	mvi	M,' '	;BLANKS
	inx	H	;NEXT CHAR
	dcr	A	;FOR THIS COUNT
	jnz	.reset_loop	;ENTIRE LINE

read_loop:	\
	call_until_nz	SINP	; READ INPUT DEVICE
	if STRINGS = TRUE
	call	to_upper
	endif
	ani	7FH	;MAKE SURE NO X'80' BIT DURING CMND MODE
	jz	STRTD	;if EITHER MODE (OR CTL-@)
	mov	B,A
	cpi	CR	;IS IT CR?
	jz finish_line
+:	cpi	LF	;IS IT A LINEFEED
	jz	finish_line	;YES--TERMINATE LINE AS IS
	lhld	INPTR	;CRNT LINE PTR
	cpi	7FH	;DELETE CHR?
	jnz	+	;NO--OK
	mvi	B,BACKS	;REPLACE IT
	DCX	H	;BACK LINE PTR UP TOO
	mvi	A,'G'-40H	;SEE if A BELL
	cmp	M	;IS IT?
	jnz	++	;NO--OK
	mov	B,A	;YES--RING THE BELL THEN
+:		equ	$	;STORE CHAR in INPUT AREA
	mov	M,B	;PLACE CHAR INTO LINE
	inx	H	;NEXT CHAR
+:		equ	$	;SAVE NEW LINE PTR
	shld	INPTR	;SAVE PTR

	call	SOUT
	jmp	read_loop
finish_line:	\
	; Assume non-vdm input
	; set INPTR to beginning of input buffer (INLIN)
	lxi	H,INLIN	;ASSUME NON-VDM INPUT
	shld	INPTR	;ALSO RESET PTR FOR NOW
	xchg		;DE=addr
	ret

; --- To Upper Subroutine ---
; Makes character in A register upper case
; ---------------------------
	if STRINGS = TRUE
to_upper: \
	cpi	'a'
	rc		; Carry indicates A is less than 'a'
	cpi	'z' + 1
	rnc		; No carry means that A is less than or equal to z
	xri	20h	; Remove lower case bit
	ret
	endif
	
; --- Write Line Subroutine ---
; Prints a line to the current pseudoport
; HL should point to null terminated string
; -----------------------------
	if STRINGS = TRUE
write_line:
	mov	A, M
	ora	A
	rz	; Null -- RETURN
	cpi	LF
	jnz	+
	call	write_crlf
	jmp	.cont
+:	mov	B, A
	call	SOUT
.cont: \
	inx	H
	jmp write_line
	endif

write_crlf:	mvi	B,LF	;LINE FEED
	call	SOUT
	mvi	B,CR	;CARRIAGE RETURN
	call	SOUT
	lda	NUCNT	;GET COUNT OF NULLS TO OUTPUT
	mov	C,A	;SAVE COUNT in C
-:	dcr	C
	rm		;COUNTED DOWN PAST ZERO (MAX COUNT IS X'7F')
	xra	A	;HERE IS THE NULL
	call	write_a	;OUTPUT IT
	jmp	-	;LOOP FOR NUMBER OF NULLS
;
;    OUTPUT HL AS HEX 16 BIT VALUE
;
write_hex_pair:	\
	mov	A,H	;H FIRST
	call	write_hex
	mov	A,L	;THEN L FOLLOWED BY A SPACE
;
HBOUT:	call	write_hex
	call	SINP	;SEE if WE SHD ESCAPE FM DUMP
	jz	BOUT	;NO--add THE SPACE THEN
	ani	7FH	;MAKE SURE ITS CLEAR OF PARITY
	jz	COMND	;EITHER MODE (OR CTL-@)
	cpi	' '	;IS IT SPACE
	jnz	BOUT	;NO--IGNORE THE CHAR
WTLP1:	call	SINP	;ON SPACE, WAIT FOR ANY OTHER CHAR
	jz	WTLP1	;JUST LOOP AFTER A SPACE UNTIL ANY KEY PRESSED
BOUT:	mvi	B,' '
	jmp	SOUT	;PUT IT OUT
;
write_hex:	mov	C,A	;GET THE CHARACTER
	rrc
	rrc		;MOVE THE HIGH FOUR DOWN
	rrc
	rrc
	call	+	;PUT THEM OUT
	mov	A,C	;THIS TIME THE LOW FOUR
+:	ani	0FH	;FOUR ON THE FLOOR
	adi	48	;WE WORK WITH ASCII HERE
	cpi	58	;0-9?
	jc	write_a;YUP!
	adi	7	;MAKE IT A LETTER
write_a: \
	mov	B,A	;OUTPUT IT FROM REGISTER 'B'
	jmp	SOUT
