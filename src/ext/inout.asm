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
	mov a, l
	sta .in + 1
.in:	in 0h	; The port will get overwritten above	
	push	psw
	call	write_crlf
	pop	psw
	call	write_hex	;OUTPUT ADDRESS
	call	write_crlf
	ret
	
out: \
	call	get_hex_arg	; Get IO port argument
	mov	a, l
	sta	.out + 1
	call	get_hex_arg	; Get value
	mov	a, l
.out:	out 0h ; The port will get overwritten
	ret
	