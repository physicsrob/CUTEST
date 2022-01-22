;
; in command
;
; This routine reads one byte from an IO port and displays
; the value to the output device.
;
in: \
	call	get_hex_arg	; Get IO port argument
	; get_hex_arg returns value in H/L
	; but since it's a single byte, the value should be in L

	; Now we setup a routine in the stack to perform
	; IN <port>
	; Why in the stack?  We have to write a literal value
	; for the port, and we can't do that in ROM, so we
	; have to find a reasonable place for the dynamically
	; constructed machine code

	; We want the stack to look like:
	; NOP
	; IN <port>
	; RET
	; <return address>

	; But of course, we must work backward

	; Store return address
	lxi d, .ret
	push d

	; Store <PORT> RET
	mvi h, RET_OPCODE
	; l already = port
	push h
	
	; Store NOOP IN
	mvi d, IN_OPCODE
	mvi e, NOOP_OPCODE
	push d

	; Now lets call it!
	lxi h, 0
	dad sp
	
	; Fix the stack
	pop d
	pop d
	pchl
	
.ret:
	push	psw
	call	write_crlf
	pop	psw
	call	write_hex	;OUTPUT ADDRESS
	call	write_crlf
	ret
	
out:
	; Now we setup a routine in the stack to perform
	; OUT <port>
	
	; We want the stack to look like:
	; NOP
	; OUT <port>
	; RET

	; But of course, we must work backward
	
	; Get IO port argument
	call	get_hex_arg	

	; Store <PORT> RET
	mvi h, RET_OPCODE ; l already = port
	push h
	
	; Get value
	call	get_hex_arg	
	mov	a, l

	; Store NOOP OUT
	mvi d, OUT_OPCODE
	mvi e, NOOP_OPCODE
	push d
	
	; Now lets call it!
	lxi h, 0
	dad sp
	
	; Fix the stack
	pop d
	pop d
	
	pchl
