;   THE FOLLOWING ROUTINES PROVIDE "BYTE BY BYTE" ACCESS
;  TO THE CASSETTE TAPES ON EITHER A READ OR WRITE BASIS.
;
;  THE TAPE IS READ ONE BLOCK AT A TIME AND INDIVIDUAL
;  TRANSFERS OF DATA HANDLED BY MANAGING A BUFFER AREA.
;
;  THE BUFFER AREA IS CONTROLLED BY A FILE CONTROL BLOCK
;  (FCB) WHOSE STRUCTURE IS:
;
;
;     7 BYTES FOR EACH OF THE TWO FILES STRUCTURED AS
;   FOLLOWS:
;
;         1 BYTE -  ACCESS CONTROL   00 if CLOSED
;                                    FF if READING
;                                    FE if WRITING
;         1 BYTE -  READ COUNTER
;         1 BYTE -  BUFFER POSITION POINTER
;         2 BYTE -  CONTROL HEADER ADDRESS
;         2 BYTE -  BUFFER LOCATION ADDRESS
;
;
;
; cassette_open -- 
; THIS ROUTINE IS ONLY ACCESSIBLE FROM THE FOPEN JMP POINT
; THIS ROUTINE "OPENS" THE CASSETTE UNIT FOR ACCESS
;
;   ON ENTRY:  A - HAS THE TAPE UNIT NUMBER (1 OR 2)
;             HL - HAS USER SUPPLIED HEADER FOR TAPE FILE
;
;
;   NORMAL RETURN:   ALL REGISTERS ARE ALTERED
;                    BLOCK IS READY FOR ACCESS
;
;   ERROR RETURN:    CARRY BIT IS set
;
;   ERRORS:  BLOCK ALREADY OPEN
;
;
cassette_open:
	push	H	;SAVE HEADER ADDRESS
	call	LFCB	;GET ADDRESS OF FILE CONTROL
	jnz	TERE2	;FILE WAS ALREADY OPEN
	mvi	M,1	;NOW IT IS
	inx	H	;POINT TO READ COUNT
	mov	M,A	;ZERO
	inx	H	;POINT TO BUFFER CURSOR
	mov	M,A	;PUT IN THE ZERO COUNT
;
;  ALLOCATE THE BUFFER
;
	lxi	D,FBUF1	;POINT TO BUFFER AREA
	lda	FNUMF	;GET WHICH ONE WE ARE GOING TO USE
	add	D
	mov	D,A	;256 bit add
	
	pop	B	;HEADER ADDRESS
	ora	A	;CLEAR CARRY AND RETURN AFTER STORING PARAMS
	jmp	store_BCDE	;STORE THE VALUES
;
;    GENERAL ERROR RETURN POINTS FOR STACK CONTROL
;
TERE2:	pop	H
TERE1:	pop	D
TERE0:	xra	A	;CLEAR ALL FLAGS
	stc		;SET ERROR
	ret
;
;
return_eof_error:
	dcr	A	;SET MINUS FLAGS
	stc		;AND CARRY
	pop	D	;CLEAR THE STACK
	ret		;THE FLAGS TELL ALL
;
;
;
;
;   THIS ROUTINE CLOSES THE FILE BUFFER TO ALLOW ACCESS
;   FOR A DifFERENT CASSETTE OR PROGRAM.  if THE FILE
;   OPERATIONS WERE "WRITE" THEN THE LAST BLOCK IS WRITTED
;   out AND AN "END OF FILE" WRITTEN TO THE TAPE.  if
;   THE OPERATIONS WERE "READS" THEN THE FILE IS JUST
;   MADE READY FOR NEW USE.
;
;   ON ENTRY:  A - HAS WHICH UNIT (1 OR 2)
;
;   ERROR RETURNS:  FILE WASN'T OPEN
;
;
cassette_close:	
	call	LFCB	;GET CONTROL BLOCK ADDRESS
	rz		;WASN'T OPEN, CARRY IS SET FROM LFCB
	ora	A	;CLEAR CARRY
	inr	A	;SET CONDITION FLAGS
	mvi	M,0	;CLOSE THE CONTROL BYTE
	rz		;WE WERE READING...NOTHING MORE TO DO
;
;    THE FILE OPERATIONS WERE "WRITES"
;
;  PUT THE CURRENT BLOCK ON THE TAPE
;  (EVEN IF ONLY ONE BYTE)
;  THEN WRITE AN END OF FILE TO THE TAPE
;
;
	inx	H
	inx	H
	mov	A,M	;GET CURSOR POSITION
	mov	A,M	;GET CURSOR POSITION
	call	load_BCDE	;BC GET HEADER ADDRESS, DE BUFFER ADDRESS
	push	B	;HEADER TO STACK
	lxi	H,BLKOF	;OFFSET TO BLOCK SIZE
	dad	B
	ora	A	;TEST COUNT
	jz	.write_eof ;NO BYTES...JUST WRITE EOF
;
;    WRITE LAST BLOCK
;
	push	H	;SAVE BLOCK SIZE POINTER FOR EOF
	mov	M,A	;PUT IN COUNT
	inx	H
	mvi	M,0	;ZERO THE HIGHER BYTE
	inx	H
	mov	M,E	;BUFFER ADDRESS
	inx	H
	mov	M,D
	mov	H,B
	mov	L,C	;PUT HEADER ADDRESS IN HL
	call	cassette_write_block	;GO WRITE IT OUT
	pop	H	;BLOCK SIZE POINTER

.write_eof:
	; Write end of file to cassette
	; HL already setup to point to block size
	; Set the block size to zero, this is how we represent EOF
	xra	A
	mov	M,A
	inx	H
	mov	M,A
	pop	H	;HEADER ADDRESS
	jmp	cassette_write_block ;WRITE IT OUT AND RETURN
;
;
;
;
;   THIS ROUTINE LOCATES THE FILE CONTROL BLOCK POINTED TO
;   BY REGISTER "A".  ON RETURN HL POINT TO THE CONTROL BYT
;   AND REGISTER "A" HAS THE CONTROL WORD WITH THE FLAGS
;   set FOR IMMEDIATE CONDITION DECISIONS.
;
;
LFCB:	lxi	H,FCBAS	;POINT TO THE BASE OF IT
	; File numbers are represented to the user as 1 or 2.
	; Convert this to 0 or 1 
	rar
	ani	1
	sta	FNUMF	;CURRENT ACCESS FILE NUMBER
	jz	+	;UNIT ONE (VALUE OF ZERO)
	lxi	H,FCBA2	;UNIT TWO--PT TO ITS FCB
+:	mov	A,M	;PICK UP FLAGS FM FCB
	ora	A	;SET FLAGS BASED ON CONTROL WORD
	stc		;SET CARRY IN CASE OF IMMEDIATE ERROR RETURN
	ret

; --- cassette_read_byte ---
; Read tape byte routine.  This is used by the entry point, but
; not any of the cassette commands.  According to the CUTER manual
; this is how BASIC reads/writes to tape.
;
; ENTRY:       -  A -  HAS FILE NUMBER
; EXIT: NORMAL -  A -  HAS BYTE
; ERROR
;    CARRY set     - F FILE NOT OPEN OR PREVIOUS OPERATIONS WERE WRITE
;    CARRY & MINUS - END OF FILE ENCOUNTERED
; -------------------------
cassette_read_byte:
	call	LFCB	;LOCATE THE FILE CONTROL BLOCK
	rz		;FILE NOT OPEN
	inr	A	;TEST if FF
	jm	TERE0	;ERROR WAS WRITING
	mvi	M, 0FFH	;SET IT AS READ  (in CASE IT WAS JUST OPENED)
	inx	H
	mov	A,M	;GET READ COUNT
	push	H	;SAVE COUNT ADDRESS
	inx	H
	call	load_BCDE	;GET THE OTHER PARAMETERS
	pop	H
	ora	A
	jnz	.get_byte_from_buffer	;IF NOT EMPTY GO GET BYTE
	
	;
	;  CURSOR POSITION WAS ZERO...READ A NEW BLOCK INTO
	;  THE BUFFER.
	;
	push	D	;BUFFER POINTER
	push	H	;TABLE ADDRESS
	inx	H
	call	PHEAD	;PREPARE THE HEADER FOR READ
	call	cassette_read_block ;READ IN THE BLOCK
	jc	TERE2	;ERROR POPP OFF STACK BEFORE RETURN
	pop	H
	mov	A,E	;LOW BYTE OF COUNT (WILL BE ZERO if 256)
	ora	D	;SEE if BOTH ARE ZERO
	jz	return_eof_error	;BYTE COUNT WAS ZERO....END OF FILE
	mov	M,E	;NEW COUNT ( ZERO IS 256 AT THIS POINT)
	inx	H	;BUFFER LOCATION POINTER
	mvi	M,0
	dcx	H
	mov	A,E	;COUNT TO A
	pop	D	;GET BACK BUFFER ADDRESS
;
;
;
;   THIS ROUTINE GETS ONE BYTE FROM THE BUFFER
;  AND RETURNS IT IN REGISTER "A".  IF THE END
;  OF THE BUFFER IS REACHED IT MOVES THE POINTER
;  TO THE BEGINNING OF THE BUFFER FOR THE NEXT
;  LOAD.
;
.get_byte_from_buffer:	
	dcr	A	;BUMP THE COUNT
	mov	M,A	;RESTORE IT
	inx	H
	mov	A,M	;GET BUFFER POSITION
	inr	M	;BUMP IT
;
	add	E
	mov	E,A	;DE NOW POINT TO CORRECT BUFFER POSITION
	jnc	+
	inr	D
+:	ldax	D	;GET CHARACTER FROM BUFFER
	ora	A	;CLEAR CARRY
	ret		;ALL DONE

; --- cassette_write_byte ---
; Write tape byte routine.  This is used by the entry point, but
; not accessed by any commands.
;      ON ENTRY:   A -  HAS FILE NUMBER (1 or 2)
;                  B -  HAS DATA BYTE
; --------------------------
cassette_write_byte:
	call	LFCB	;GET CONTROL BLOCK
	rz		;FILE WASN'T OPEN
	inr	A
	rz		;FILE WAS READ
	mvi	M,0FEH	;SET IT TO WRITE
	inx	H
	inx	H
	mov	A,B	;GET CHARACTER
	push	PSW
	push	H	;SAVE CONTROL ADDRESS+2
;
;   NOW DO THE WRITE
;
	call	load_BCDE	;BC GETS HEADER addr, DE BUFFER ADDRESS
	pop	H
	mov	A,M	;COUNT BYTE
	add	E
	mov	E,A
	jnc	+
	inr	D
+:	pop	PSW	;CHARACTER
	stax	D	;PUT CHR in BUFFER
	ora	A	;CLEAR FLAGS
	inr	M	;INCREMENT THE COUNT
	rnz		;RETURN if COUNT DIDN'T ROLL OVER
;
;   THE BUFFER IS FULL. WRITE IT TO TAPE AND RESET
;  CONTROL BLOCK.
;
	call	PHEAD	;PREPARE THE HEADER
	jmp	cassette_write_block ;WRITE IT out AND RETURN
;
;
;
;
;  THIS ROUTINE PUTS THE BLOCK SIZE (256) AND BUFFER
;  ADDRESS IN THE FILE HEADER.
;
PHEAD:	call	load_BCDE	;GET HEADER AND BUFFER ADDRESSES
	push	B	;HEADER ADDRESS
	lxi	H,BLKOF-1	;store_BCDE DOES AN INCREMENT
	dad	B	;HL POINT TO BLOCKSIZE ENTRY
	lxi	B,256
	call	store_BCDE
	pop	H	;HL RETURN WITH HEADER ADDRESS
	ret
;
;
store_BCDE:
	inx	H
	mov	M,C
	inx	H
	mov	M,B
	inx	H
	mov	M,E
	inx	H
	mov	M,D
	ret
;
;
load_BCDE:
	inx	H
	mov	C,M
	inx	H
	mov	B,M
	inx	H
	mov	E,M
	inx	H
	mov	D,M
	ret


; ---------------------------------------------;
;
; cassette_read_block
;
; Reads a file, including the header, from tape.
; Turns the tape on (if using CUTS)
; On entry:
;	Tape speed and unit from SET is used, this is different than SOLOS/CUTER
;	HL contains the address of file header information.
;	DE contains the address-of where the file is to be loaded into memory.
;		If set to 0, this information is taken from file header information on tape.)
; On exit:
;	Normal return: Carry Flag is cleared, and data has been transferred into memory.
; 	Error return: On errors, or user pressing MODE (or Control-@) from keyboard, the Carry Flag is set.
;
; Tape units will be turned off before returning.
; ---------------------------------------------;
cassette_read_block:	
	push	D	;SAVE OPTIONAL ADDRESS
	mvi	B,3	;SHORT DELAY
	call	cassette_tape_on
;
-:
	push	H	; HEADER ADDRESS
	call	read_header	;GO READ HEADER
	pop	H
	jc	tape_error	;IF AN ERROR OR ESC WAS RECEIVED
	jnz 	-		;IF VALID HEADER NOT FOUND
;
;  FOUND A VALID HEADER NOW DO COMPARE
;
	push	H	;GET BACK AND RESAVE ADDRESS
	lxi	D,THEAD
	call	compare_names	;COMPARE DE-HL HEADERS
	pop	H
	jnz	-
;
;
	pop	D	;OPTIONAL "PUT" ADDRESS
	mov	A,D
	ora	E	;SEE if DE IS ZERO
	lhld	BLOCK	;GET BLOCK SIZE
	xchg		;...TO DE
;  DE HAS HBLOCK....HL HAS USER OPTION
	jnz +
	lhld	LOADR	;GET TAPE LOAD ADDRESS
+:
	push D
	call	RTAP
	pop D	
	ret

;
;
;     THIS ROUTINE READS "DE" BYTES FROM THE TAPE
;     TO ADDRESS HL.  THE BYTES MUST BE FROM ONE
;     CONTIGUOUS PHYSICAL BLOCK ON THE TAPE.
;
;          HL HAS "PUT" ADDRESS
;          DE HAS SIZE OF TAPE BLOCK
;
RTAP:
;
-:	
	; Find out how many bytes (up to 256) to read
	; right now.  DE gets decremented by this value
	; and B gets this value.
	call	decrement_de_by_page
	
	; If zero, turn tape off.
	jz	cassette_tape_off

	call	read_chunk	;READ THAT MANY BYTES
	jc	tape_error	;IF ERROR OR ESC
	jz	-	;RD OK--READ SOME MORE
;
;  ERROR RETURN
;
tape_error:	
	; Turn tape off (send 0 to status) 
	; Pop DE off the stack
	; and return
	stc	; SET ERROR FLAGS
	jmp	cassette_tape_off
;
;
delay_then_off:
	mvi B,1
	call DELAY
	jmp cassette_tape_off

; --- decrement_de_by_page ---
; Decrements DE by up to 256 bytes, but less if necessary to prevent from rolling past zero.
; Returns number of bytes decremented in B
; ------------------------------
decrement_de_by_page:
	;COMMON RTN TO COUNT DOWN BLK LENGTHS
	; Reset A & B
	xra A	
	mov B,A	
	; Check if D is zero (less than one block left) 
	; (in which case the amount left will be in E) 
	ora D
	jnz +
	; This is the branch for less than 256 bytes left (D=0, E has remaining bytes)
	ora E
	; If there are zero bytes left return with zero flag set
	rz
	; There are some bytes, but less than one block
	mov B,E ; Set return value to amount remaining (E)
	mov E,D ; Set E to 0 (D was already 0)
	ret
+:	
	; This is the branch for more than 256 bytes left
	dcr D	;DROP BY 256
	ora A	;FORCE NON-ZERO FLAG
	ret	;NON-ZERO=NOT DONE YET (BLK LEN=256)
;

; --- read_header ---
; Find header on tape and read it into THEAD
; -------------------
read_header:	
	; Find the start of a block on the tape
	call cassette_read_until_header
	rc

	; We found it, so now read the header
	lxi	H,THEAD	;POINT TO BUFFER
	mvi	B,HLEN		;LENGTH TO READ
	; Drop through to read_chunk

read_chunk:
	; Read a block into HL for B bytes
	mvi	C,0	; Reset the CRC
-:	call	cassette_input_byte	; Read a byte
	rc
	mov	M,A
	inx	H
	call	calculate_crc
	dcr	B
	jnz	-
;
;   THIS ROUTINE GETS THE NEXT BYTE AND COMPARES IT
; TO THE VALUE in REGISTER C.  THE FLAGS ARE SET ON
; RETURN.
;
	call	cassette_input_byte	;GET CRC BYTE
	xra	C	;CLR CARRY AND set ZERO if MATCH, ELSE NON-ZERO
	rz		;CRC IS FINE
	lda	IGNCR	;BAD CRC, SHD WE STILL ACCEPT IT
	inr	A	;SEE if IT WAS FF, if FF THEN ZERO SAYS IGN ERR
;   NOW, CRC ERR DETECTION DEPENDS ON IGNCR.
	ret
;



; ---------------------------------------------;
;
; cassette_write_block
;
; Called by: WRBLK entry point; all byte-access routines (to write the buffer)
;
; Write a file, including the header, to tape.
; Turns the tape on (if using CUTS)
; On entry:
;	Tape speed and unit from SET is used, this is different than SOLOS/CUTER
;	HL contains the address to store the file header information.
; On exit:
;	Normal return: Carry Flag is cleared, and data has been written to tape.
; ---------------------------------------------;
cassette_write_block:
	push	H	;SAVE HEADER ADDRESS
	call	cassette_write_header	;TURN ON, THEN WRITE HDR
	pop	H
	lxi	D,BLKOF	;OFFSET TO BLOCK SIZE IN HEADER
	dad	D	;HL POINT TO BLOCK SIZE
	mov	E,M
	inx	H
	mov	D,M	;DE HAVE SIZE
	inx	H
	mov	A,M
	inx	H
	mov	H,M
	mov	L,A	;HL HAVE STARTING ADDRESS
	; Fall through to cassette_write_buffer

; ----------------------- ;
; cassette_write_buffer
;
; This routine writes one physical block to tape.
; On entry:
;	DE contains number of bytes to write
;	HL contains address of buffer 
; ----------------------- ;
cassette_write_buffer:	
-:	
	; Find out how many bytes (up to 256) to write
	; right now.  DE gets decremented by this value
	; and B gets this value.
	call	decrement_de_by_page
	; If no more bytes, turn tape off
	jz	delay_then_off
	; Otherwise, write bytes
	call	cassette_write_buffer_page	;WRITE BLOCK FOR BYTES in B (256)
	jmp	-	;LOOP UNTIL ALL DONE

; --- calculate_crc ---
; On Entry:
;    C contains existing CRC
;    Accumulator contains new byte 
; On Exit:
;    C contains CRC modified for new byte 
calculate_crc:
	;A COMMON CRC COMPUTATION ROUTINE
	sub	C
	mov	C,A
	xra	C
	cma	
	sub	C
	mov	C,A
	ret

; ------------------------------;
; cassette_write_buffer_page
; 
; This routine writes B bytes to the current tape, followed by a CRC.
;
; On entry:
;	HL points to buffer to be written
;	B contains number of bytes
; ------------------------------;
cassette_write_buffer_page:
	mvi	C,0	;RESET CRC BYTE
-:	mov	A,M	;GET CHARACTER
	call	cassette_output_byte	;WRITE IT TO THE TAPE
	dcr	B
	inx	H
	jnz	-
	mov	A,C	;GET CRC
	jmp	cassette_output_byte	;PUT IT ON THE TAPE AND RETURN
;
;

; --- compare_names ---
; Compare the name in THEAD to the name in the user
; supplied header (located at HL).
; Returns zero is the two names are the same.
; ---------------------
compare_names:	mvi	B,5
-:	ldax	D
	cmp	M
	rnz
	dcr	B
	rz		;IF ALL FIVE COMPARED
	inx	H
	inx	D
	jmp	-