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
	ifdef PSEUDOPORT_0_DPORT
	dw out_0
	endif
	ifdef PSEUDOPORT_1_DPORT
	dw out_1
	endif
	ifdef PSEUDOPORT_2_DPORT
	dw out_2
	endif
	ifdef PSEUDOPORT_3_DPORT
	dw out_3
	endif

in_0	input_routine 0
in_1	input_routine 1
in_2	input_routine 2
in_3	input_routine 3

out_0	output_routine 0
out_1	output_routine 1
out_2	output_routine 2
out_3	output_routine 3

; INPUT DEVICE TABLE
; Note, to change this table, update config/pseudoports.asm
ITAB:	equ $
	ifdef PSEUDOPORT_0_DPORT
	dw in_0
	endif
	ifdef PSEUDOPORT_1_DPORT
	dw in_1
	endif
	ifdef PSEUDOPORT_2_DPORT
	dw in_2
	endif
	ifdef PSEUDOPORT_3_DPORT
	dw in_3
	endif


; --- read_line ---
; This routine reads a line from the current pseudoport.
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

	lxi D, 80 ; Numer of chars to rset to space
	mvi B, ' '
	call memset
	;lxi H, INLIN+79
	;mvi m, 0

read_loop:	\
	call_until_nz	SINP	; READ INPUT DEVICE
	call	to_upper

	; Check for restart characters
	; which is 80 hex
	escape_key_test
	jz	startup_d

	; Check for CR or LF, in either case finish the line
	mov B,A
	cpi CR	;IS IT CR?
	jz .finish_line
	cpi LF	;IS IT A LINEFEED
	jz .finish_line	;YES--TERMINATE LINE AS IS

	; Not CR/LF, Not restart
	; Set HL to current line pointer
	lhld	INPTR

	; Check if current key is delete
	; We support three delete keys:
	; '_' (5FH), ascii del (7FH), ascii backspace (8H)
	; 7FH is handled by to_upper converting it to 5FH
	cpi 5FH
	jz .is_delete
	
	cpi 8H
	jz .is_delete
	

.store_char:
	mov M,B ;PLACE CHAR INTO LINE
	inx H	;NEX@T CHAR

.save_ptr:
	shld	INPTR	;SAVE PTR
	call	SOUT
	jmp	read_loop

.is_delete:
	; Current key is delete
	; We'll display the special BACKS character
	; instead of the delete char
	dcx	H	;BACK LINE PTR UP TOO
	
	; Check to see if we've delete too far
	mvi	A, 7	; See if HL is pointing at the bell char
	cmp	M
	jz	read_line ; If so, start over

.del_char:	
	; If not, let's whipe out the character from the buf 
	mvi m, ' '
	mvi B, BACKS
	jmp .save_ptr

.finish_line:	\
	; Assume non-vdm input
	; set INPTR to beginning of input buffer (INLIN)
	lxi	H,INLIN	;ASSUME NON-VDM INPUT
	shld	INPTR	;ALSO RESET PTR FOR NOW
	xchg		;DE=addr
	ret

; --- To Upper Subroutine ---
; Makes character in A register upper case
; ---------------------------
to_upper: \
	cpi	'a'
	rc		; Carry indicates A is less than 'a'
	
	; Note, we "upper case" 7B, 7C, 7D, 7E, and 7F
	; shifting them to 5B, 5C, 5D, 5E, and 5F
	; This converts delete to '_', which is desirable
	; so we can treat '_' and delete the same.
	; This could be undone by uncommenting these lines:
	; cpi	'z' + 1
	; rnc		; No carry means that A is less than or equal to z
	xri	20h	; Remove lower case bit
	
	ret
	
write_crlf:
	mvi	B,LF	;LINE FEED
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

; --- Write Hex Byte Pair ---
; This routine writes the contents of HL in hex to the
; current pseudoport.
; ---------------------------
write_hex_pair:	\
	mov	A,H	;H FIRST
	call	write_hex
	mov	A,L	;THEN L FOLLOWED BY A SPACE

; --- Write Hex Byte ---
; This routine writes the contents of A in hex to the
; current pseudoport.
; Mutates: A, B, C, PSW
; ---------------------------
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
	; Drops through to write_a

; --- Write A ---
; Thie routine is just like SOUT, but the character
; to be written comes from A instead of B.
; ----------------
write_a: \
	mov	B,A	;OUTPUT IT FROM REGISTER 'B'
	jmp	SOUT
