;
; TAPE CONFIG
;

TAPPT  equ 0FAH      ;TAPE STATUS PORT
TDATA  equ 0FBH      ;TAPE DATA PORT
TFE    equ 8         ;TAPE FRAMING ERROR
TOE    equ 16        ;TAPE OVERFLOW ERROR
TDR    equ 64        ;TAPE DATA READY
TTBE   equ 128       ;TAPE TRANSMITTER BUFFER EMPTY
TAPE1  equ 80H       ;1=TURN TAPE ONE ON
TAPE2  equ 40H       ;1=TURN TAPE TWO ON

tape_off:
	xra	A
	out	TAPPT
	pop	D	;RETURN BYTE COUNT
	ret

;
;
tape_on:
	; Turn tape on and then delay (length based on B)
	; Status is combination of tape speed and unit 
	; tape Speed: 20H or 0  
	; Tape Unit: Either TAPE1 (80H) or TAPE2 (40H), specified in config
	; FNUMF will _always_ be 0 for tape 1 or 1 for tape 2
	; This is different than CUTER where sometimes FNUMF
	; is used for the bitmask rather than the unit number.
	lda	FNUMF	;GET UNIT
	ora	A	;SEE WHICH UNIT
	lda	TSPD	;BUT 1ST GET SPEED
	jnz	+ ;MAKE IT UNIT TWO
	adi	TAPE2	;THIS ONCE=UNIT 2, TWICE=UNIT 1
+:	adi	TAPE2	;UNIT AND SPEED NOW SET IN A

	; Write to status port
	OUT	TAPPT
       jmp DELAY


wait_for_tape_data:
	IN	TAPPT	;TAPE STATUS PORT
	ani	TDR
	rnz
	call	SINP	;CHECK INPUT
	jz wait_for_tape_data
	ani	7FH	;CLEAR PARITY 1ST
	jnz wait_for_tape_data ;EITHER MODE OR CTL-@
	stc		;SET ERROR FLAG
	ret		;AND RETURN


;
;
; TODO: Push this to cuts.asm
cassette_output_byte:
	push	PSW
-:	in	TAPPT	;TAPE STATUS
	ani	TTBE	;IS TAPE READY FOR A CHAR YET
	jz	- ;NO--WAIT
	pop	PSW	;YES--RESTORE CHAR TO OUTPUT
	out	TDATA	;SEND CHAR TO TAPE
	jmp calculate_crc

;
;
;   THIS ROUTINE WRITES THE HEADER POINTED TO BY
;   HL TO THE TAPE.
;
write_header:	
	mvi	B,4	; Set delay after tape on
	call	tape_on	;TURN IT ON, THEN WRITE HEADER
	mvi	D,50	;WRITE 50 ZEROS
-:	xra	A
	call	cassette_output_byte
	dcr	D
	jnz	-
;
	mvi	A,1
	call	cassette_output_byte
	mvi	B,HLEN	;LENGTH TO WRITE OUT
	
	jmp cassette_write_buffer_page
;
;
;
TAPIN:	
	call	wait_for_tape_data
	rc
	in TAPPT		;TAPE STATUS
	ani	TFE+TOE	;DATA ERROR?
	in TDATA		;GET THE DATA
	rz			;IF NO ERRORS
	stc			;SET ERROR FLAG
	ret


; --- find_block ---
; Find 10 nulls followed by a 1
; ------------------
find_block:	
       mvi	B,10	;FIND 10 NULLS
-:	call wait_for_tape_data	
	rc		;IF ESCAPE
	IN	TDATA	;IGNORE ERROR CONDITIONS
	ora	A	;ZERO?
	jnz	find_block
	dcr	B
	jnz	-	;LOOP UNTIL 10 IN A ROW
;
;    WAIT FOR THE START CHARACTER
;
-:	call	TAPIN
	rc		;ERROR OR ESCAPE
	cpi	1	;ARE WE AT THE 01 YET (START CHAR)
	jc	-      ;NO, BUT STIL ZEROES
	jnz	find_block ;NO, LOOK FOR ANOTHER 10 NULLS
;
       ret