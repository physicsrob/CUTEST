	
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

