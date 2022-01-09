;
;
;
;   THIS ROUTINE PROCESSES THE XEQ AND GET COMMANDS
;
;
	PUBLIC TXEQ
TXEQ:	DB	3EH	;THIS BEGINS "MVI" OF THE "XRA" FOLLOWING
	PUBLIC TLOAD
TLOAD:	XRA	A	;A=0 TLOAD, A=AF (#0) THEN XEQ
	PUSH	PSW	;SAVE FLAG TO SAY WHETHER LOAD OR XEQ
	LXI	H,DHEAD	;PLACE DUMMY HDR HERE FOR COMPARES
	CALL	NAME	;SET IN NAME AND UNIT
	LXI	H,0	;ASSUME LOAD ADDR NOT GIVEN
	CALL	GET_OPT_HEX_ARG	;HL EITHER =0, OR OVERRIDE LOAD ADDR
;
TLOA2:	XCHG		;PUT ADDRESS IN DE
	LXI	H,DHEAD	;PT TO NORMAL HDR
	MOV	A,M	;GET 1ST CHAR OF NAME
	ORA	A	;IS THERE A NAME?
	JNZ	TLOA3	;YES--LOOK FOR IT
	LXI	H,THEAD	;PT TO SAME HDR TO LOAD NEXT FILE
TLOA3:	PUSH	H	;SAVE PTR TO WHICH HDR TO USE
	CALL	ALOAD	;GET UNIT AND SPEED
	POP	H	;RESTORE PTR TO PROPER HDR TO USE
	CALL	RTAPE	;READ IN THE TAPE
	JC	TAERR	;TAPE ERROR?
;
	CALL	NAOUT	;PUT OUT THE HEADER PARAMETERS
	POP	PSW	;RESTORE FLAG SAYING WHETHER IT WAS LOAD OR XEQ
	ORA	A
	RZ		;AUTO XEQ NOT WANTED
	LDA	HTYPE	;CHECK TYPE
	ORA	A	;SET FLAGS
	JM	TAERR	;TYPE IS NON XEQ
	LDA	THEAD+5
	ORA	A
	JNZ	TAERR	;THE BYTE MUST BE ZERO FOR AUTO XEQ
	LHLD	XEQAD	;GET THE TAPE ADDRESS
	JMP	EXEC1	;AND GO OFF TO IT
;
;
;
;   THIS ROUTINE IS USED TO SAVE PROGRAMS AND DATA ON
;   THE CASSETTE UNIT.
;
;
	PUBLIC TSAVE
TSAVE:	EQU	$	;SAVE MEMORY IMAGE TO TAPE
	CALL	NAME0	;GET NAME AND UNIT
	CALL	GET_HEX_ARG	;GET START ADDRESS
	PUSH	H	;SAVE START ADDR FOR SIZE COMPUTATION LATER
	CALL	GET_HEX_ARG	;GET END ADDR (REQUIRED)
	XTHL		;HL=START ADDR NOW, STACK=END ADDR
	PUSH	H	;STACK =START FOLLOWED BY END
	CALL	GET_OPT_HEX_ARG	;SEE IF RETRIEVE FROM ADDR
	SHLD	LOADR	;EITHER ACTUAL START, OR OVERRIDE INTO HDR
	POP	H	;;HL=START ADDR
	POP	D	;DE=END ADDR
	PUSH	H	;PUT START BACK ONTO STACK
	MOV	A,E	;SIZE=END-START+1
	SUB	L
	MOV	L,A
	MOV	A,D
	SBI	0	;THIS EQUALS A "SBB H"
	SUB	H	;THIS IS NEEDED
	MOV	H,A
	INX	H
	SHLD	BLOCK	;STORE THE SIZE
	PUSH	H	;SAVE AS THE BLOCK SIZE
;
	CALL	ALOAD	;GET UNIT AND SPEED
	LXI	H,THEAD	;PT TO HEADER TO WRITE
	CALL	WHEAD	;TURN TAPE ON, THEN WRITE HEADER
	POP	D	;GET BACK THE SIZE
	POP	H	;AND GET BACK THE ACTUAL START ADDR
	JMP	WTAP1	;WRITE THE BLK (W/EXTRA PUSH)
;
;   OUTPUT ERROR AND HEADER
;
TAERR:	CALL	CRLF
	MVI	D,6
	LXI	H,ERRM
	CALL	NLOOP	;OUTPUT ERROR
	CALL	NAOUT	;THEN THE HEADER
	JMP	COMN1
;
ERRM:	DB	'ERROR '

;
;
;              CAT COMMAND
;
;   THIS ROUTINE READS HEADERS FROM THE TAPE AND OUTPUTS
;   THEM TO THE OUTPUT DEVICE.  IT CONTINUES UNTIL THE
;   MODE KEY IS DEPRESSED.
;
	PUBLIC	TLIST
TLIST:	EQU	$	;PRODUCE A LIST OF FILES ON A TAPE
	CALL	NAME0	;GET UNIT IF ANY (NAME IS IGNORED)
	CALL	CRLF	;START ON A FRESH LINE
;
;
LLIST:	CALL	ALOAD
	MVI	B,1
	CALL	TON	;TURN ON THE TAPE
LIST1:	CALL	RHEAD
	JC	COMN1	;TRUN OFF THE TAPE UNIT
	JNZ	LIST1
	CALL	NAOUT	;OUTPUT THE HEADER
	JMP	LLIST
;
;
;   THIS ROUTINE GETS THE CASSETTE UNIT NUMBER AND
;   SPEED TO REGISTER "A" FOR THE TAPE CALLS
;
ALOAD:	LXI	H,FNUMF	;POINT TO THE UNIT SPECIFICATION
	LDA	TSPD	;GET THE TAPE SPEED
	ORA	M	;PUT THEM TOGETHER
	RET		;AND GO BACK
;
;   THIS ROUTINE OUTPUTS THE NAME AND PARAMETERS OF
;   THEAD TO THE OUTPUT DEVICE.
;
;
NAOUT:	MVI	D,8
	LXI	H,THEAD-1  ;POINT TO THE HEADER
	CALL	NLOOP	;OUTPUT THE HEADER
	CALL	BOUT	;ANOTHER BLANK
	LHLD	LOADR	;NOW THE LOAD ADDRESS
	CALL	ADOUT	;PUT IT OUT
	LHLD	BLOCK	;AND THE BLOCK SIZE
	CALL	ADOUT
	JMP	CRLF	;DO THE CRLF AND RETURN
;
;
NLOOP:	MOV	A,M	;GET CHARACTER
	ORA	A
	JNZ	CHRLI	;IF IT ISN'T A ZERO
	MVI	A,' '	;SPACE OTHERWISE
CHRLI:	EQU	$	;CHAR IS OK TO SEND
	CALL	OUTH	;OUTPUT IT FROM A REG
	INX	H
	DCR	D
	JNZ	NLOOP
	RET
