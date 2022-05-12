tarbell_status	equ 06Eh
tarbell_data         equ 06Fh
tarbell_sync_byte    equ 0E6H
tarbell_presync_byte equ 03CH
tarbell_reset        equ 10H
tarbell_dataready    equ 10H

; --- wait_for_tape_data ---
; Loop until data is ready or escape
; --------------------------
wait_for_tape_data:
	in tarbell_status
	ani tarbell_dataready
       rnz
	call SINP	;CHECK INPUT
	jz wait_for_tape_data
	ani 7FH	;CLEAR PARITY 1ST
	jnz wait_for_tape_data ;EITHER MODE OR CTL-@
	stc ;SET ERROR FLAG
	ret ;AND RETURN

tape_on:
       ; We don't support tape control yet.
       ; So this is a noop.
       ret

TAPIN:	
	call wait_for_tape_data
	rc
       in tarbell_data
       ret

;
; --- find_block ---
; Reads from tape until the beginning of a block is found or an escape key is pressed
; ------------------
find_block:
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
       inx d
	cmp d		; If d != 0
	jnz .loop	; read more
	cmp e		; if e != 0
	jnz .loop	; read more

       ; If we get here we've timed out, so we start over unless an escape key was pressed
       call SINP	;CHECK INPUT
	jz find_block ; No key was pressed
	cpi 7F
       rz ; Break if 7F was pressed (mode or CTL-@)
       jmp find_block

.data_ready:
       ; If we get here we've gotten the sync byte
       ; Next we need to check for our pattern of 10 nulls followed by a 1
       mvi b, 10 ; Find 10 nulls
.nulls_loop:
       call wait_for_tape_data
       rc ; Abort if escape
       in tarbell_data
       ora A ; Check if null
       ; If it's not null, we start over!
       jnz find_block
       ; It is null, we decrement
       dcr b
       jnz .nulls_loop

       ; If we get here, we successfully read 10 nulls! congrats!
       ; the next byte _must_ be the start char (1)
;
-:	call TAPIN
	rc		; Escape
	cpi 1
       jnz find_block ; If it's not 1, we have to start looking for a block again!
       ; Otherwise, success!!! 
       ret
       
