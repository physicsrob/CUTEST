;
;
;               VIDEO DRIVER COMMAND TABLE
;
;     THIS TABLE DEFINES THE CHARACTERS FOR SPECIAL
;  PROCESSING. if THE CHARACTER IS NOT IN THE TABLE IT
;  GOES TO THE SCREEN.
;
TBL:	db	CLEAR	;SCREEN
	dw	ERASE_SCREEN
	db	UP	;CURSOR
	dw	PUP
	db	DOWN	;"
	dw	PDOWN
	db	LEFT	;"
	dw	PLEFT
	db	RIGHT	;"
	dw	PRIT
	db	HOME	;"
	dw	PHOME
	db	CR	;CARRIAGE RETURN
	dw	PCR
	db	LF	;LINE FEED
	dw	PLF
	db	BACKS	;BACK SPACE
	dw	PBACK
	db	ESC	;ESCAPE KEY
	dw	PESC
	db	0	;END OF TABLE
;
;
;
;                  VIDEO DISPLAY ROUTINES
;
;
;  THESE ROUTINES ALLOW FOR STANDARD VIDEO TERMINAL
;  OPERATIONS.  ON ENTRY, THE CHARACTER FOR OUTPUT IS IN
;  REGISTER B AND ALL REGISTERS ARE UNALTERED ON RETURN.
;
;
;
VDM01:	equ	$	;VDM OUTPUT DRIVER
	push	H	;SAVE HL
	push	D	;SAVE DE
	push	B
;
;  PROCESS ESC SEQUENCE if ANY
;
	lda	ESCFL	;GET ESCAPE FLAG
	ora	A
	jnz	ESCS	;IF NON ZERO GO PROCESS THE REST OF THE SEQUENCE
;
	mov	A,B	;GET CHAR
	ani	7FH	;CLR HI BIT in CASE
	mov	B,A	;USE CHAR STRIPPED OF HI BIT FOR COMPATABILITY
	jz	GOBK	;MAKE A QUICK EXIT FOR A NULL
;
	lxi	H,TBL
	call	TSRCH	;GO PROCESS
;
GOBACK:	equ	$	;RESET CURSOR AND DELAY
	call	VDADD	;GET SCRN addr
	mov	A,M	;GET CHAR
	ori	80H	;INVERSE VIDEO
	mov	M,A	;CURSOR IS NOW THERE
	lhld	SPEED-1	;GET DELAY SPEED
	inr	L	;MAKE IT DEFINITELY NON-ZERO
	xra	A	;DELAY ENds WHEN H=ZERO
TIMER:	dcx	H	;LOOP FOR DELAY AMNT
	cmp	H	;IS IT DONE YET
	jnz	TIMER	;NO--KEEP DELAYING
GOBK:	pop	B
	pop	D	;RESTORE ALL REGISTERS
	pop	H
	ret		;EXIT FROM VDMOT
;
;
NEXT:	equ	$	;GO TO NEXT CHR
	inx	H
	inx	H
;
;  THIS ROUTINE SEARCHES FOR A MATCH OF THE CHAR in "B"
;  TO THE CHAR IN THE TBL POINTED TO BY HL.
;
TSRCH:	mov	A,M	;GET CHR FROM TABLE
	ora	A	;SEE if END OF TBL
	jz	CHAR	;ZERO IS THE LAST
	cmp	B	;TEST THE CHR
	inx	H	;POINT FORWARD
	jnz	NEXT
	push	H	;FOUND ONE...SAVE ADDRESS
	call	CREM	;REMOVE CURSOR
	xthl		;RESTORE addr OF CHAR ENTRY in TBL
	jmp	DISPT	;DISPATCH FOR CURSOR CONTROL
;
;
CHAR:	equ	$	;WE HAVE A CHAR
	mov	A,B	;GET CHARACTER
	cpi	7FH	;IS IT A DEL?
	rz		;GO BACK if SO
;
;
;
OCHAR:	call	VDADD	;GET SCREEN ADDRESS
	mov	M,B	;PUT CHR ON SCREEN
	lda	NCHAR	;GET CHARACTER POSITION
	cpi	63	;END OF LINE?
	jc	OK
	lda	LINE
	cpi	15	;END OF SCREEN?
	jnz	OK
;
;   END OF SCREEN...ROLL UP ONE LINE
;
SCROLL:	xra	A
	sta	NCHAR	;BACK TO FIRST CHAR POSITION
SROL:	mov	C,A
	call	VDAD	;CALCULATE LINE TO BE BLANKED
	xra	A
	call	CLIN1	;CLEAR IT
	lda	BOT
	inr	A
	ani	0FH
	jmp	ERAS3
;
;   INCREMENT LINE COUNTER if NECESSARY
;
OK:	lda	NCHAR	;GET CHR POSITION
	inr	A
	ani	3FH	;MOD 64
	sta	NCHAR	;STORE THE NEW
	rnz		;MORE CHARS THIS LINE
PDOWN:	equ	$	;MOVE CURSOR DOWN ONE LINE
	lda	LINE	;GET THE LINE COUNT
	inr	A
CURSC:	ani	0FH	;MOD 15 INCREMENT
CUR:	sta	LINE	;STORE THE NEW
	ret
;
;    ERASE SCREEN
;
ERASE_SCREEN:	lxi	H,VDM_MEM	;POINT TO SCREEN
	mvi	M,80H+' '  ;THIS IS THE CURSOR
	inx	H	;NEXT CHAR

	lxi D, 3FFh
	mvi B, ' '
	call memset

	; set carry true, we use this to keep PHOME
	; from RETURNing.
	stc		;SAY WE WANT TO DROP THRU TO ERAS3
;
PHOME:	equ	$	;RESET CURSOR TO HOME
	mvi	A,0	;CLEAR, LEAVE CARRY AS IS
	sta	LINE	;ZERO LINE
	sta	NCHAR	;LEFT SIDE OF SCREEN
	; if carry flag isn't set, this was a direct call to PHOME
	; so RETURN
	rnc		;THIS IS JUST A HOME OPERATION
;
ERAS3:	OUT	VDM_STAT_PORT	;RESET SCROLL PARAMETERS
	sta	BOT	;BEGINNING OF TEXT OFFSET
	ret
;
;
CLINE:	call	VDADD	;GET CURRENT SCREEN ADDRESS
	lda	NCHAR	;CURRENT CURSOR POSITION
CLIN1:	cpi	64	;NO MORE THAN 63
	rnc		;ALL DONE
	mvi	M,' '	;ALL SPACED OUT
	inx	H
	inr	A
	jmp	CLIN1	;LOOP TO END OF LINE
;
;
;  ROUTINE TO MOVE THE CURSOR UP ONE LINE
;
PUP:	lda	LINE	;GET LINE COUNT
	dcr	A
	jmp	CURSC	;MERGE
;
;  MOVE CURSOR LEFT ONE POSITION
;
PLEFT:	lda	NCHAR
	dcr	A
PCUR:	equ	$	;TAKE CARE OF CURSOR SAME LINE
	ani	03FH	;LET CURSOR WRAP AROUND
	sta	NCHAR	;UPDATED CURSOR
	ret
;
;     CURSOR RIGHT ONE POSITION
;
PRIT:	lda	NCHAR
	inr	A
	jmp	PCUR
;
;   ROUTINE TO CALCULATE SCREEN ADDRESS
;
;   ENTRY AT:    RETURNS:
;
;         VDADD  CURRENT SCREEN ADDRESS
;         VDAD2  ADDRESS OF CURRENT LINE, CHAR 'C'
;         VDAD   LINE 'A', CHARACTER POSITION 'C'

VDADD:	lda	NCHAR	;GET CHARACTER POSITION
	mov	C,A	;'C' KEEPS IT
VDAD2:	lda	LINE	;LINE POSITION
VDAD:	mov	L,A	;INTO 'L'
	lda	BOT	;GET TEXT OFFSET
	add	L	;add IT TO THE LINE POSITION
	rrc		;TIMES TWO
	rrc		;MAKES FOUR
	mov	L,A	;L HAS IT
	ani	3	;MOD THREE FOR LATER
	adi	VDM_MEM >> 8	;LOW SCREEN OFFSET
	mov	H,A	;NOW H IS DONE
	mov	A,L	;TWIST L'S Arm
	ani	0C0H
	add	C
	mov	L,A
	ret		;H & L ARE NOW PERVERTED
;
;    ROUTINE TO REMOVE CURSOR
;
CREM:	call	VDADD	;GET CURRENT SCREEN ADDRESS
	mov	A,M
	ani	7FH	;STRIP OFF THE CURSOR
	mov	M,A
	ret
;
;     ROUTINE TO BACKSPACE
;
PBACK:	call	PLEFT
	call	VDADD	;GET SCREEN ADDRESS
	mvi	M,' '	;PUT A BLANK THERE
	ret
;
;     ROUTINE TO PROCESS A CARRIAGE RETURN
;
PCR:	call	CLINE	;CLEAR FROM CURRENT CURSOR TO END OF LINE
;  NOTE THAT A COMES BACK=64 WHICH WILL BE CLEARED AT PCUR
	jmp	PCUR	;AND STORE THE NEW VALUE
;
;   ROUTINE TO PROCESS LINEFEED
;
PLF:	lda	LINE	;GET LINE COUNT
	inr	A	;NEXT LINE
	ani	15	;SEE if IT WRAPPED AROUND
	jnz	CUR	;IT DID NOT--NO SCROLL
;
	jmp	SROL	;SCROLL ONE LINE--CURSOR SOME POSITION
;
;     set ESCAPE PROCESS FLAG
;
PESC:	mvi	A, 0FFH
	sta	ESCFL	;SET FLAG
	ret
;
;       PROCESS ESCAPE SEQUENCE
;
ESCS:	call	CREM	;REMOVE CURSOR
	call	ESCSP	;PROCESS THE CHARACTER
	jmp	GOBACK
;
ESCSP:	lda	ESCFL	;GET ESCAPE FLAG
	cpi	0FFH	;TEST FLAG
	jz	SECOND
;
;  PROCESS THIRD CHR OF ESC SEQUENCE
;
	lxi	H,ESCFL
	mvi	M,0
	cpi	2
	jc	SETX	;SET X
	jz	SETY	;SET Y
	cpi	8	;SPECIAL set SPEED
	mov	A,B
	sta	SPEED
	cpi	9
	jc	OCHAR	;PUT IT ON THE SCREEN
	rnz
;
;  TAB ABSOLUTE TO VALUE in REG B
;
SETX:	mov	A,B
	jmp	PCUR
;
;  set CURSOR TO LINE "B"
;
SETY:	mov	A,B
	jmp	CURSC
;
;
;   PROCESS SECOND CHR OF ESC SEQUENCE
;
SECOND:	mov	A,B
	cpi	3
	jz	CURET
	cpi	4
	jnz	ARET2
	mov	B,H
	mov	C,L	;PRESENT SCREEN ADDRESS TO BC FOR RETURN
ARET1:	pop	H	;RETURN ADDRESS
	pop	D	;OLD B
	push	B
	push	H
	xra	A
ARET2:	sta	ESCFL
	ret
;
;
;     RETURN PRESENT SCREEN PARAMETERS in BC
;
CURET:	lxi	H,NCHAR
	mov	B,M	;CHARACTER POSITION
	inx	H
	mov	C,M	;LINE POSITION
	jmp	ARET1

