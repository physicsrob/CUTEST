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
; BOPEN -- THIS ROUTINE IS ONLY ACCESSIBLE FROM THE FOPEN jmp POINT
;        THIS ROUTINE "OPENS" THE CASSETTE UNIT FOR ACCESS
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
BOPEN:	push	H	;SAVE HEADER ADDRESS
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
;
UBUF:	pop	B	;HEADER ADDRESS
	ora	A	;CLEAR CARRY AND RETURN AFTER SToriNG PARAMS
	jmp	PSTOR	;STORE THE VALUES
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
EOFER:	dcr	A	;SET MINUS FLAGS
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
;   THE OPERATIONS WERE "REAds" THEN THE FILE IS JUST
;   MADE READY FOR NEW USE.
;
;   ON ENTRY:  A - HAS WHICH UNIT (1 OR 2)
;
;   ERROR RETURNS:  FILE WASN'T OPEN
;
;
PCLOS:	call	LFCB	;GET CONTROL BLOCK ADDRESS
	rz		;WASN'T OPEN, CARRY IS set FROM LFCB
	ora	A	;CLEAR CARRY
	inr	A	;set CONDITION FLAGS
	mvi	M,0	;CLOSE THE CONTROL BYTE
	rz		;WE WERE READING...NOTHING MORE TO DO
;
;    THE FILE OPERATIONS WERE "WRITES"
;
;  PUT THE CURRENT BLOCK ON THE TAPE
;  (EVEN if ONLY ONE BYTE)
;  THEN WRITE AN END OF FILE TO THE TAPE
;
;
	inx	H
	inx	H
	mov	A,M	;GET CURSOR POSITION
	mov	A,M	;GET CURSOR POSITION
	call	PLOAD	;BC GET HEADER ADDRESS, DE BUFFER ADDRESS
	push	B	;HEADER TO STACK
	lxi	H,BLKOF	;OFFSET TO BLOCK SIZE
	dad	B
	ora	A	;TEST COUNT
	jz	EOFW	;NO BYTES...JUST WRITE EOF
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
	call	WFBLK	;GO WRITE IT OUT
	pop	H	;BLOCK SIZE POINTER
;
;   NOW WRITE END OF FILE TO CASSETTE
;
EOFW:	xra	A	;PUT IN ZEROS FOR SIZE:  EOF MARK IS ZERO BYTES!
	mov	M,A
	inx	H
	mov	M,A
	pop	H	;HEADER ADDRESS
	jmp	WFBLK	;WRITE IT out AND RETURN
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
	jz	LFCB1	;UNIT ONE (VALUE OF ZERO)
	lxi	H,FCBA2	;UNIT TWO--PT TO ITS FCB
LFCB1:	equ	$	;HL PT TO PROPER FCB
	mov	A,M	;PICK UP FLAGS FM FCB
	ora	A	;set FLAGS BASED ON CONTROL WORD
	stc		;set CARRY in CASE OF IMMEDIATE ERROR RETURN
	ret
;
;
;
;
;    READ TAPE BYTE ROUTINE
;
;    ENTRY:       -  A -  HAS FILE NUMBER
;    EXIT: NORMAL -  A -  HAS BYTE
;          ERROR
;            CARRY set     - if FILE NOT OPEN OR
;                            PREVIOUS OPERATIONS WERE WRITE
;            CARRY & MINUS - END OF FILE ENCOUNTERED
;
;
;
;
RTBYT:	call	LFCB	;LOCATE THE FILE CONTROL BLOCK
	rz		;FILE NOT OPEN
	inr	A	;TEST if FF
	jm	TERE0	;ERROR WAS WRITING
	mvi	M, 0FFH	;set IT AS READ  (in CASE IT WAS JUST OPENED)
	inx	H
	mov	A,M	;GET READ COUNT
	push	H	;SAVE COUNT ADDRESS
	inx	H
	call	PLOAD	;GET THE OTHER PARAMETERS
	pop	H
	ora	A
	jnz	GTBYT	;if NOT EMPTY GO GET BYTE
;
;  CURSOR POSITION WAS ZERO...READ A NEW BLOCK INTO
;  THE BUFFER.
;
RDNBLK:	push	D	;BUFFER POINTER
	push	H	;TABLE ADDRESS
	inx	H
	call	PHEAD	;PREPARE THE HEADER FOR READ
	call	RFBLK	;READ in THE BLOCK
	jc	TERE2	;ERROR pop OFF STACK BEFORE RETURN
	pop	H
	mov	A,E	;LOW BYTE OF COUNT (WILL BE ZERO if 256)
	ora	D	;SEE if BOTH ARE ZERO
	jz	EOFER	;BYTE COUNT WAS ZERO....END OF FILE
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
;  AND RETURNS IT in REGISTER "A".  if THE END
;  OF THE BUFFER IS REACHED IT MOVES THE POINTER
;  TO THE BEGINNING OF THE BUFFER FOR THE NEXT
;  LOAD.
;
GTBYT:	dcr	A	;BUMP THE COUNT
	mov	M,A	;RESTORE IT
	inx	H
	mov	A,M	;GET BUFFER POSITION
	inr	M	;BUMP IT
;
	add	E
	mov	E,A	;DE NOW POINT TO CORRECT BUFFER POSITION
	jnc	RT1
	inr	D
RT1:	ldax	D	;GET CHARACTER FROM BUFFER
	ora	A	;CLEAR CARRY
	ret		;ALL DONE
;
;
;
;
;      THIS ROUTINE IS USED TO WRITE A BYTE TO THE FILE
;
;      ON ENTRY:   A -  HAS FILE NUMBER
;                  B -  HAS DATA BYTE
;
;
WTBYT:	call	LFCB	;GET CONTROL BLOCK
	rz		;FILE WASN'T OPEN
	inr	A
	rz		;FILE WAS READ
	mvi	M,0FEH	;set IT TO WRITE
	inx	H
	inx	H
	mov	A,B	;GET CHARACTER
	push	PSW
	push	H	;SAVE CONTROL ADDRESS+2
;
;   NOW DO THE WRITE
;
	call	PLOAD	;BC GETS HEADER addr, DE BUFFER ADDRESS
	pop	H
	mov	A,M	;COUNT BYTE
	add	E
	mov	E,A
	jnc	WT1
	inr	D
WT1:	pop	PSW	;CHARACTER
	stax	D	;PUT CHR in BUFFER
	ora	A	;CLEAR FLAGS
	inr	M	;INCREMENT THE COUNT
	rnz		;RETURN if COUNT DIDN'T ROLL OVER
;
;   THE BUFFER IS FULL. WRITE IT TO TAPE AND RESET
;  CONTROL BLOCK.
;
	call	PHEAD	;PREPARE THE HEADER
	jmp	WFBLK	;WRITE IT out AND RETURN
;
;
;
;
;  THIS ROUTINE PUTS THE BLOCK SIZE (256) AND BUFFER
;  ADDRESS in THE FILE HEADER.
;
PHEAD:	call	PLOAD	;GET HEADER AND BUFFER ADDRESSES
	push	B	;HEADER ADDRESS
	lxi	H,BLKOF-1	;PSTOR DOES AN INCREMENT
	dad	B	;HL POINT TO BLOCKSIZE ENTRY
	lxi	B,256
	call	PSTOR
	pop	H	;HL RETURN WITH HEADER ADDRESS
	ret
;
;
PSTOR:	inx	H
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
PLOAD:	inx	H
	mov	C,M
	inx	H
	mov	B,M
	inx	H
	mov	E,M
	inx	H
	mov	D,M
	ret
;
;
;
;
;
;   THIS ROUTINE SETS THE CORRECT UNIT FOR SYSTEM REAds
RFBLK:	call	GTUNT	;set UP A=UNIT WITH SPEED
;
;
;
;
;              TAPE READ ROUTINES
;
;     ON-ENTRY:     A HAS UNIT AND SPEED
;                   HL POINT TO HEADER BLOCK
;                   DE HAVE OPTIONAL PUT ADDRESS
;
;     ON EXIT:      CARRY IS set if ERROR OCCURED
;                   TAPE UNITS ARE OFF
;
;
RTAPE:	push	D	;SAVE OPTIONAL ADDRESS
	mvi	B,3	;SHORT DELAY
	call	TON
	IN	TDATA	;CLEAR THE UART FLAGS
;
PTAP1:	push	H	;HEADER ADDRESS
	call	RHEAD	;GO READ HEADER
	pop	H
	jc	TERR	;if AN ERROR OR ESC WAS RECEIVED
	jnz	PTAP1	;if VALID HEADER NOT FOUND
;
;  FOUND A VALID HEADER NOW DO COMPARE
;
	push	H	;GET BACK AND RESAVE ADDRESS
	lxi	D,THEAD
	call	DHcmp	;COMPARE DE-HL HEADERS
	pop	H
	jnz	PTAP1
;
;
	pop	D	;OPTIONAL "PUT" ADDRESS
	mov	A,D
	ora	E	;SEE if DE IS ZERO
	lhld	BLOCK	;GET BLOCK SIZE
	xchg		;...TO DE
;  DE HAS HBLOCK....HL HAS USER OPTION
	jnz	RTAP	;if DE WAS ZERO GET TAPE LOAD ADDRESS
	lhld	LOADR	;GET TAPE LOAD ADDRESS
;
;
;     THIS ROUTINE REAds "DE" BYTES FROM THE TAPE
;     TO ADDRESS HL.  THE BYTES MUST BE FROM ONE
;     CONTIGUOUS PHYSICAL BLOCK ON THE TAPE.
;
;          HL HAS "PUT" ADDRESS
;          DE HAS SIZE OF TAPE BLOCK
;
RTAP:	push	D	;SAVE SIZE FOR RETURN TO callING PROGRAM
;
RTAP2:	equ	$	;HERE TO LOOP RDING BLKS
	call	dcrCT	;DROP COUNT, B=LEN THIS BLK
	jz	RTOFF	;ZERO=ALL DONE
;
	call	RHED1	;READ THAT MANY BYTES
	jc	TERR	;if ERROR OR ESC
	jz	RTAP2	;RD OK--READ SOME MORE
;
;  ERROR RETURN
;
TERR:	xra	A
	stc		;set ERROR FLAGS
	jmp	RTOF1
;
;
TOFF:	mvi	B,1
	call	DELAY
RTOFF:	xra	A
RTOF1:	OUT	TAPPT
	pop	D	;RETURN BYTE COUNT
	ret
;
;
dcrCT:	equ	$	;COMMON RTN TO COUNT DOWN BLK LENGTHS
	xra	A	;CLR FOR LATER TESTS
	mov	B,A	;set THIS BLK LEN=256
	ora	D	;IS AMNT LEFT < 256
	jnz	dcrC2	;NO--REDUCE AMNT BY 256
	ora	E	;IS ENTIRE COUNT ZERO
	rz		;ALL DONE--ZERO=THIS CONDITION
	mov	B,E	;set THIS BLK LEN TO AMNT REMAINING
	mov	E,D	;MAKE ENTIRE COUNT ZERO NOW
	ret		;ALL DONE (NON-ZERO FLAG)
dcrC2:	equ	$	;REDUCE COUNT BY 256
	dcr	D	;DROP BY 256
	ora	A	;FORCE NON-ZERO FLAG
	ret		;NON-ZERO=NOT DONE YET (BLK LEN=256)
;
;
;   READ THE HEADER
;
RHEAD:	mvi	B,10	;FIND 10 NULLS
RHEA1:	call	STAT
	RC		;if ESCAPE
	IN	TDATA	;IGNORE ERROR CONDITIONS
	ora	A	;ZERO?
	jnz	RHEAD
	dcr	B
	jnz	RHEA1	;LOOP UNTIL 10 in A ROW
;
;    WAIT FOR THE START CHARACTER
;
SOHL:	call	TAPIN
	RC		;ERROR OR ESCAPE
	cpi	1	;ARE WE AT THE 01 YET (START CHAR)
	jc	SOHL	;NO, BUT STIL ZEROES
	jnz	RHEAD	;NO, LOOK FOR ANOTHER 10 NULLS
;
;    WE HAVE  10 (OR MORE) NULLS FOLLOWED IMMEDIATELY
;    BY AN 01.  NOW READ THE HEADER.
;
	lxi	H,THEAD	;POINT TO BUFFER
	mvi	B,HLEN	;LENGTH TO READ
;
RHED1:	equ	$	;RD A BLOCK INTO HL FOR B BYTES
	mvi	C,0	;INIT THE CRC
RHED2:	equ	$	;LOOP HERE
	call	TAPIN	;GET A BYTE
	RC
	mov	M,A	;STORE IT
	inx	H	;INCREMENT ADDRESS
	call	DOCRC	;GO COMPUTE THE CRC
	dcr	B	;WHOLE HEADER YET?
	jnz	RHED2	;DO ALL THE BYTES
;
;   THIS ROUTINE GETS THE NEXT BYTE AND COMPARES IT
; TO THE VALUE in REGISTER C.  THE FLAGS ARE set ON
; RETURN.
;
	call	TAPIN	;GET CRC BYTE
	xra	C	;CLR CARRY AND set ZERO if MATCH, ELSE NON-ZERO
	rz		;CRC IS FINE
	lda	IGNCR	;BAD CRC, SHD WE STILL ACCEPT IT
	inr	A	;SEE if IT WAS FF, if FF THEN ZERO SAYS IGN ERR
;   NOW, CRC ERR DETECTION DEPENds ON IGNCR.
	ret
;
;    THIS ROUTINE GETS THE NEXT AVAILABLE BYTE FROM THE
;  TAPE.  WHILE WAITING FOR THE BYTE THE KEYBOARD IS TESTED
;  FOR AN ESC COMMAND.  if RECEIVED THE TAPE LOAD IS
;  TERMINATED AND A RETURN TO THE COMMAND MODE IS MADE.
;
STAT:	IN	TAPPT	;TAPE STATUS PORT
	ani	TDR
	rnz
	call	SINP	;CHECK INPUT
	jz	STAT	;NOTHING THERE YET
	ani	7FH	;CLEAR PARITY 1ST
	jnz	STAT	;EITHER MODE OR CTL-@
	stc		;set ERROR FLAG
	ret		;AND RETURN
;
;
;
TAPIN:	call	STAT	;WAIT UNTIL A CHARACTER IS AVAILABLE
	RC
;
TREDY:	IN	TAPPT		;TAPE STATUS
	ani	TFE+TOE	;DATA ERROR?
	IN	TDATA		;GET THE DATA
	rz			;if NO ERRORS
	stc			;set ERROR FLAG
	ret
;
;
;  THIS ROUTINE GETS THE CORRECT UNIT FOR SYSTEM WRITES
WFBLK:	call	GTUNT	;set UP A WITH UNIT AND SPEED
;
;
;
;       WRITE TAPE BLOCK ROUTINE
;
;   ON ENTRY:   A   HAS UNIT AND SPEED
;              HL   HAS POINTER TO HEADER
;
;
WTAPE:	equ	$	;HERE TO WRITE TAPE
	push	H	;SAVE HEADER ADDRESS
	call	WHEAD	;TURN ON, THEN WRITE HDR
	pop	H
	lxi	D,BLKOF	;OFFSET TO BLOCK SIZE in HEADER
	dad	D	;HL POINT TO BLOCK SIZE
	mov	E,M
	inx	H
	mov	D,M	;DE HAVE SIZE
	inx	H
	mov	A,M
	inx	H
	mov	H,M
	mov	L,A	;HL HAVE STARTING ADDRESS
;
;    THIS ROUTINE WRITES ONE PHYSICAL BLOCK ON THE
;  TAPE "DE" BYTES LONG FROM ADDRESS "HL".
;
;
WTAP1:	equ	$	;HERE FOR THE EXTRA push
	push	H	;A DUMMY push FOR LATER EXIT
WTAP2:	equ	$	;LOOP HERE UNTIL ENTIRE AMOUNT READ
	call	dcrCT	;DROP COUNT in DE AND set UP B W/LEN THIS BLK
	jz	TOFF	;RETURNS ZERO if ALL DONE
	call	WTBL	;WRITE BLOCK FOR BYTES in B (256)
	jmp	WTAP2	;LOOP UNTIL ALL DONE
;
;
WRTAP:	push	PSW
WRWAT:	IN	TAPPT	;TAPE STATUS
	ani	TTBE	;IS TAPE READY FOR A CHAR YET
	jz	WRWAT	;NO--WAIT
	pop	PSW	;YES--RESTORE CHAR TO OUTPUT
	OUT	TDATA	;SEND CHAR TO TAPE
;
DOCRC:	equ	$	;A COMMON CRC COMPUTATION ROUTINE
	sub	C
	mov	C,A
	xra	C
	CMA
	sub	C
	mov	C,A
	ret		;ONE  BYTE NOW WRITTEN
;
;
;   THIS ROUTINE WRITES THE HEADER POINTED TO BY
;   HL TO THE TAPE.
;
WHEAD:	equ	$	;HERE TO 1ST TURN ON THE TAPE
	call	WTON	;TURN IT ON, THEN WRITE HEADER
	mvi	D,50	;WRITE 50 ZEROS
NULOP:	xra	A
	call	WRTAP
	dcr	D
	jnz	NULOP
;
	mvi	A,1
	call	WRTAP
	mvi	B,HLEN	;LENGTH TO WRITE OUT
;
WTBL:	mvi	C,0	;RESET CRC BYTE
WLOOP:	mov	A,M	;GET CHARACTER
	call	WRTAP	;WRITE IT TO THE TAPE
	dcr	B
	inx	H
	jnz	WLOOP
	mov	A,C	;GET CRC
	jmp	WRTAP	;PUT IT ON THE TAPE AND RETURN
;
;
;   THIS ROUTINE COMPARES THE HEADER in THEAD TO
;   THE USER SUPPLIED HEADER in ADDRESS HL.
;   ON RETURN if ZERO IS set THE TWO NAMES COMPARED
;
DHcmp:	mvi	B,5
DHLOP:	ldax	D
	cmp	M
	rnz
	dcr	B
	rz		;if ALL FIVE COMPARED
	inx	H
	inx	D
	jmp	DHLOP
;
GTUNT:	equ	$	;set A=SPEED + UNIT
	lda	FNUMF	;GET UNIT
	ora	A	;SEE WHICH UNIT
	lda	TSPD	;BUT 1ST GET SPEED
	jnz	GTUN2	;MAKE IT UNIT TWO
	adi	TAPE2	;THIS ONCE=UNIT 2, TWICE=UNIT 1
GTUN2:	adi	TAPE2	;UNIT AND SPEED NOW set in A
	ret		;ALL DONE
;
WTON:	mvi	B,4	;set LOOP DELAY  (BIT LONGER ON A WRITE)
TON:	equ	$	;HERE TO TURN A TAPE ON THEN DELAY
	OUT	TAPPT	;GET TAPE movING, THEN DELAY
;
DELAY:	lxi	D,0
DLOP1:	dcx	D
	mov	A,D
	ora	E
	jnz	DLOP1
	dcr	B
	jnz	DELAY
	ret
	