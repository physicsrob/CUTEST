INCLUDE_DEBUG equ False
       if INCLUDE_DEBUG = True

; sleep 
; length, in a from 1-255
sleep: 
       mov d, a
       mvi e, 0
.sleep:
       nop
       nop
       nop
       nop
       nop
       nop
       nop
       nop
       nop
       nop
       nop
       nop
       nop
       nop
	dcx d
	mov a, d
	ora e
	jnz .sleep	
       ret

debug_print: macro str
	push psw
	push b
	push d
	push h
	jmp .prnt
.x:	db str
	db LF
	db 0
.prnt:	lxi h, .x
	call write_line
	mvi a, 250
	call sleep 
       pop h
	pop d
	pop b
	pop psw
	endm

; Reminder about PSW:
; bit 0 is carry
; bit 1 is always on
; bit 2 is parity
; bit 3 is always 0
; bit 4 is aux carry
; bit 5 is always 0
; bit 6 is zero bit
; bit 7 is sign bit
; 46h = Sign Bit, Parity Bit
; 86, 86, 
; 86, 86, err

debug_state:
	push psw
	push b
	push d
	push h
	push h
	push d
	push b
	push psw
	
	call write_crlf
	
	; Log APSW
	lxi h, reg_APSW_str
	call write_line
	pop h
	call write_hex_pair
	call write_crlf
	
       ; Log BC
	lxi h, reg_BC_str
	call write_line
	pop h
	call write_hex_pair
	call write_crlf
	
       ; Log DE
	lxi h, reg_DE_str
	call write_line
	pop h
	call write_hex_pair
	call write_crlf
       
       ; Log HL
	lxi h, reg_HL_str 
	call write_line
	pop h
	call write_hex_pair
	call write_crlf

       
       mvi a, 255
       call sleep 
	pop h
	pop d
	pop b
	pop psw
       ret

debug_a_psw:
	push psw
	push b
	push d
	push h
	push psw
	
	call write_crlf
	
	; Log APSW
	lxi h, reg_APSW_str
	call write_line
	pop h
	call write_hex_pair
	call write_crlf
	
	
	mvi a, 255
       call sleep 
	pop h
	pop d
	pop b
	pop psw
       ret

reg_APSW_str:
       db 'REG A PSW: '
       db 0

reg_BC_str:
       db 'REG BC: '
       db 0

reg_DE_str:
       db 'REG DE: '
       db 0

reg_HL_str:
       db 'REG HL: '
       db 0
       endif