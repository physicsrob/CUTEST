       PUBLIC inhex

inhex_port: db 0
inhex_sum: db 0
finish_msg: \
       db LF
       db 'DONE'
       db LF
       db 0
error_msg: \
       db LF
       db 'ERROR'
       db LF
       db 0


inhex: \
	call	get_hex_arg   ; get pseudoport arg
	; get_hex_arg returns value in H/L
	; but since it's a single byte, the value should be in L
       mov a, l
       lxi H, inhex_port
       mov m, a

       call write_crlf      
 -:    
       mvi B, '.'
       call sout
       call read_ihex_line
       call process_ihex_line
       jnz -
       ; Either error or EOF here

       ; Error
       jc ihex_error

       ; End of file
       jmp ihex_end_of_file

ihex_end_of_file:
       lxi h, finish_msg
       jmp write_line

ihex_error:
       lxi h, error_msg
       jmp write_line

       
next_val:
       push b
       call hex_chars_to_byte
       pop b
       
       ; Update sum
       push psw
       push h
       lxi h, inhex_sum
       add m
       sta inhex_sum
       pop h
       pop psw

       ret


;--- process_ihex_line ---
; Process one line of ihex file
; Arguments:
;    INLIN - contents of line to process
; Returns:
;      Carry bit set if error
;      Zero bit set if end of file
; Mutates: Everything 
;-------------------------
process_ihex_line:
       lxi D, INLIN

       ; Reset checksum
       lxi h, inhex_sum
       mvi m, 0
       
       ; Read byte count, store in reg C
       call next_val 
       mov C, a
       inr c

       ; Read address MSB
       call next_val 
       mov H, a
       
       ; Read address LSB
       call next_val 
       mov L, a

       ; Read type       
       call next_val 
       cpi 1 ; EOF
       
 ;      jnz +
       rz
       ;ret       

       cpi 0 ; data
       jz .loop
       ; Error - we only support EOF and data lines (ihex line type 0 and 1)
       mvi A, 1Ch
       call write_hex
       stc
       ret
       
       ; Read byte
.loop  call next_val 

       ; If we're the last byte, skip storing
       ; since this is the checksum
       dcr c
       jz .fin

       ; Store at address
       mov m, a
       ; Increment address
       inx h
       jmp .loop

.fin:
       lxi h, inhex_sum
       mov a, m
       cpi 0
       ; If checksum fails, zero bit will not be set
       ; If checksum passes, zero bit will be set
       jz .success
       ; Error case
       xra a
       ; call write_hex
       stc
       ret 
.success: \
       ; we want to return non-zero since it's not the EOF
       xra a
       adi 1
       ret
       
       
; --- Read one ihex line ---
; Arguments:
;    B - Pseudoport to read from
; -------------------------
read_ihex_line:
-:     \
       lxi H, inhex_port
       mov A, M
       call AINP
       jz -
       cpi ':'
       jnz -

	lxi	H,INLIN	; Pointer to char in front of input buffer
	shld	INPTR	       ; Save as starting ptr
	mvi	A, 80	       ; Max number of chars in line (buf len)
       mov    C, A          ; Also set to max chars

; set the buffer to a string of null
-:	\
	mvi	M, 0
	inx	H
	dcr	A
	jnz	-	;ENTIRE LINE

       ; Read until we encounter ':'


-:	\
       push h
       lxi H, inhex_port
       mov A, M
       pop h
	call AINP
       jz -
	call	to_upper
	cpi	CR
       rz
	cpi	LF
       rz
     
       lhld   INPTR
	mov    M, A
       inx    H
	shld	INPTR
	dcr    C
       jnz	-
	ret

