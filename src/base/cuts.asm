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

cassette_tape_off:
	xra	A
	out	TAPPT
	ret

;
;
cassette_tape_on:
	; Turn tape on and then delay (length based on B)

	; First step is to calculate status byte to write.
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
	IN	TDATA	;CLEAR THE UART FLAGS
       jmp DELAY


; --- wait_for_tape_data ---
; Loop until data is ready or escape
; --------------------------
wait_for_tape_data:
	IN	TAPPT	;TAPE STATUS PORT
	ani	TDR
	rnz
	call	SINP	;CHECK INPUT
	jz wait_for_tape_data
	escape_key_test	
	jnz wait_for_tape_data 
	stc		;SET ERROR FLAG
	ret		;AND RETURN


; ------------------------- 
; cassette_output_byte
;
; Wait until cassette is ready and write one byte (contained in A).
; Update CRC (in C)
; ------------------------- 
cassette_output_byte:
	push	PSW
-:	in	TAPPT	;TAPE STATUS
	ani	TTBE	;IS TAPE READY FOR A CHAR YET
	jz	- ;NO--WAIT
	pop	PSW	;YES--RESTORE CHAR TO OUTPUT
	out	TDATA	;SEND CHAR TO TAPE
	jmp calculate_crc

; -------------------------- ;
; cassette_write_header
; This routine is always called to start the writing of a block to the tape.
; On Enter:
;	HL points to HEADER for the new block.
; -------------------------- ;
cassette_write_header:	
	mvi	B,4	; Set delay after tape on
	call	cassette_tape_on	;TURN IT ON, THEN WRITE HEADER
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
cassette_input_byte:	
	call	wait_for_tape_data
	rc
	in TAPPT		;TAPE STATUS
	ani	TFE+TOE	;DATA ERROR?
	in TDATA		;GET THE DATA
	rz			;IF NO ERRORS
	stc			;SET ERROR FLAG
	ret


; --- cassette_read_until_header ---
; Read from the cassette until we find a header.
; For CUTS this means 10 or more nulls followed by a 1
; ------------------
cassette_read_until_header:	
       mvi	B,10	;FIND 10 NULLS
-:	call wait_for_tape_data	
	rc		;IF ESCAPE
	IN	TDATA	;IGNORE ERROR CONDITIONS
	ora	A	;ZERO?
	jnz	cassette_read_until_header
	dcr	B
	jnz	-	;LOOP UNTIL 10 IN A ROW
;
;    WAIT FOR THE START CHARACTER
;
-:	call	cassette_input_byte
	rc		;ERROR OR ESCAPE
	cpi	1	;ARE WE AT THE 01 YET (START CHAR)
	jc	-      ;NO, BUT STILL ZEROES
	jnz	cassette_read_until_header ;NO, LOOK FOR ANOTHER 10 NULLS
;
       ret