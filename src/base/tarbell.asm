tarbell_status	equ 06Eh
tarbell_data         equ 06Fh
tarbell_sync_byte    equ 0E6H
tarbell_presync_byte equ 03CH
tarbell_reset        equ 10H
tarbell_dataready    equ 10H
tarbell_header_nulls equ 10

; --- wait_for_tape_data ---
; Loop until data is ready or escape
; --------------------------
wait_for_tape_data:
	in tarbell_status
	ani tarbell_dataready
	jnz wait_for_tape_data
	ret ;AND RETURN

cassette_tape_on:
       ; We don't support tape control yet.
       ; So this is a noop other than the delay.
       ; (Delay specified in B)
       jmp DELAY

cassette_tape_off:
       ; We don't support tape control yet.
       ret

cassette_input_byte:	
	call wait_for_tape_data
       in tarbell_data
       ret

cassette_output_byte:
       push psw
.loop: 
       in tarbell_status
       ani 20h
       jnz .loop
       pop psw
       out tarbell_data
	jmp calculate_crc


cassette_write_header:
       mvi a, 03Ch
       call cassette_output_byte
        
       mvi a, 0E6h
       call cassette_output_byte
       
       
       ; Write the pattern of 10 nulls followed by a 1
       mvi b, tarbell_header_nulls ; Find 10 nulls
.nulls_loop:
       xra a
       call cassette_output_byte
       dcr b
       jnz .nulls_loop

       mvi a, 1
       call cassette_output_byte
       
	mvi	B,HLEN	;LENGTH TO WRITE OUT
	jmp cassette_write_buffer_page

; --- cassette_read_until_header ---
; Read from the cassette until we find a header or an escape key is pressed.
; ------------------
cassette_read_until_header:
       ; Reset the tarbell unit
       ; This will get it in the state where it's searching for the sync byte (E6)
	mvi a, tarbell_reset
	out tarbell_status 

       ; Poll for data
       ; Data will be available the byte after the sync byte (this is handled by the
       ; tarbell hardware).  DE will be our counter for how many times we polled for
       ; data.  We'll increment it until it rolls over
       lxi d, 0
.poll:
	in tarbell_status
	ani tarbell_dataready
       jz .data_ready
       xra a
       inx d
	cmp d		; If d != 0
	jnz .poll	; read more
	cmp e		; if e != 0
	jnz .poll	; read more

       ; If we get here we've timed out, so we start over unless an escape key was pressed
       call SINP	;CHECK INPUT
	jz cassette_read_until_header ; No key was pressed
       escape_key_test 
       stc
       rz ; Break if ESCAPE_KEY pressed 
       jmp cassette_read_until_header

.data_ready:
       ; If we get here we've gotten the sync byte
       ; Next we need to check for our pattern of 10 nulls followed by a 1
       mvi b, tarbell_header_nulls ; Find 10 nulls
.nulls_loop:
       call wait_for_tape_data
       rc ; Abort if escape
       in tarbell_data
       ora A ; Check if null
       ; If it's not null, we start over!
       jnz cassette_read_until_header
       ; It is null, we decrement
       dcr b
       jnz .nulls_loop

       ; If we get here, we successfully read 10 nulls! congrats!
       ; the next byte _must_ be the start char (1)
;
-:	call cassette_input_byte
	rc		; Escape
	cpi 1
       jnz cassette_read_until_header ; If it's not 1, we have to start looking for a block again!
       ret
       
