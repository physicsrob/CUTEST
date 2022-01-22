	
; --- Write Line Subroutine ---
; Prints a line to the current pseudoport
; HL should point to null terminated string
; -----------------------------
write_line:
	mov	A, M
	ora	A
	rz	; NULL -- RETURN
	cpi	LF
	jnz	+
	call	write_crlf
	jmp	.cont
+:	mov	B, A
	call	SOUT
.cont: \
	inx	H
	jmp write_line


; --- memcmp ---
; Compare two strings (for B chars)
;
; Arguments:
;    HL - str1
;    DE - str2
;    B - length 
; Returns:
;    Non zero if strings don't match
;    Zero if strings are the same
; --------------
memcmp:
	ldax d
	cmp m
	rnz ; Return non-zero if the strings dont match
	inx d
	inx h
	dcr b
	;call debug_state
	jnz memcmp
	ret

	
