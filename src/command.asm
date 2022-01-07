	SECTION	COMMAND
;
;
;
;            =--  COMMAND MODE  --=
;
;
;   THIS ROUTINE GETS AND PROCESSES COMMANDS
;
	PUBLIC	COMND
COMND:	LXI	SP,TOP_OF_STACK	;SET STACK POINTER
	CALL	PROMPT		;PUT PROMPT ON SCREEN
	CALL	READ_LINE	;INIT TO GET COMMAND LINE
	CALL	PROCESS_COMMAND	;PROCESS THE LINE
	JMP	COMND		;OVER AND OVER
;
;
;
;   THIS ROUTINE READS A COMMAND LINE FROM THE SYSTEM
;  KEYBOARD
;
;  C/R   TERMINATES THE SEQUENCE ERASING ALL CHARS TO THE
;        RIGHT OF THE CURSOR
;  L/F   TERMINATES THE SEQUENCE
;  ESC   RESETS TO COMMAND MODE.
;
;  Results stored in INLIN buffer
READ_LINE:	EQU	$	;HERE TO INIT FOR GCLIN
		LXI	H,INLIN-1	; Pointer to char in front of input buffer
		MVI	M,7	;MAKE SURE IT IS "BELL" TO KEEP FM DEL'ING TOO FAR
		INX	H	;NOW PT TO INPUT BFR
		SHLD	INPTR	;SAVE AS STARTING PTR
		MVI	A,80	;NUMBER OF CHARS IN LINE (MAX)

; Set the buffer to a string of blanks (' ')
.reset_loop:	MVI	M,' '	;BLANKS
		INX	H	;NEXT CHAR
		DCR	A	;FOR THIS COUNT
		JNZ	.reset_loop	;ENTIRE LINE


read_loop:	CALL_UNTIL_NZ	SINP	; READ INPUT DEVICE
		ANI	7FH	;MAKE SURE NO X'80' BIT DURING CMND MODE
		JZ	STRTD	;IF EITHER MODE (OR CTL-@)
		MOV	B,A
		CPI	CR	;IS IT CR?
		JZ	CLIN2	;YES--TERMINATE LINE HERE (CLR IF VDM)
		CPI	LF	;IS IT A LINEFEED
		RZ		;YES--TERMINATE LINE AS IS
		LHLD	INPTR	;CRNT LINE PTR
		CPI	7FH	;DELETE CHR?
		JNZ	+	;NO--OK
		MVI	B,BACKS	;REPLACE IT
		DCX	H	;BACK LINE PTR UP TOO
		MVI	A,'G'-40H	;SEE IF A BELL
		CMP	M	;IS IT?
		JNZ	++	;NO--OK
		MOV	B,A	;YES--RING THE BELL THEN
+:		EQU	$	;STORE CHAR IN INPUT AREA
		MOV	M,B	;PLACE CHAR INTO LINE
		INX	H	;NEXT CHAR
+:		EQU	$	;SAVE NEW LINE PTR
		SHLD	INPTR	;SAVE PTR

		CALL	SOUT
		JMP	read_loop
;
;
;
;
;      FIND AND PROCESS COMMAND
;
PROCESS_COMMAND:	EQU	$	;PROCESS THIS COMMAND LINE
			CALL	STUP	;SETUP TO PROCESS INPUT LINE
			XCHG		;DE=ADDR
			LXI	H,START	;PREP SO THAT HL WILL PT TO CUTER LATER
			PUSH	H	;PLACE PTR TO CUTER ON STACK FOR LATER DISPT
			CALL	FIND_NON_BLANK	;SCAN PAST BLANKS
			JZ	ERR1	;NO COMMAND?
			XCHG		;HL HAS FIRST CHR
			LXI	D,COMTAB	;POINT TO COMMAND TABLE
			CALL	FDCOM	;SEE IF IN PRIMARY TABLE
			CZ	FIND_CUSTOM_CMD	;TRY CUSTOM ONLY IF NOT PRIMARY COMMAND
DISP0:			EQU	$	;HERE TO EITHER DISPATCH OR DO ERROR
			JZ	ERR2	;NOT IN EITHER TABLE
			INX	D	;PT DE TO ADDR OF RTN
			XCHG		;HL=ADDR OF ADDR OF RTN
; **** DROP THRU TO DISPT ***
;
; THIS ROUTINE DISPTACHES TO THE ADDR AT CONTENTS OF HL.
; HL ARE RESTORED PRIOR TO GOING TO ROUTINE.
;
	PUBLIC	DISPT
DISPT:	EQU	$	;DISPATCH
	MOV	A,M	;LOW BYTE
	INX	H
	MOV	H,M	;HI BYTE
	MOV	L,A	;AND LO, HL NOW COMPLETE
DISP1:	EQU	$	;HERE TO GO OFF TO HL DIRECTLY
	XTHL		;HL RESTORED AND ADDR ON STACK
	MOV	A,L	;ALWAYS PASS L IN "A" (PRIMARILY FOR SET'S)
	RET		;OFF TO ROUTINE
;
;
;
;   THIS ROUTINE SEARCHES THROUGH A TABLE, POINTED TO
;  BY 'DE', FOR A DOUBLE CHARACTER MATCH OF THE 'HL'
;  MEMORY CONTENT.  IF NO MATCH IS FOUND THE SCAN ENDS
;  WITH THE ZERO FLAG SET, ELSE NON-ZERO SET.
;
FIND_CUSTOM_CMD:	EQU	$	;HERE TO SCAN CUSTOM TABLE
	LXI	D,CUSTOM_COMMAND_TAB	;PT TO CUSTOM RTN TBL
FDCOM:	LDAX	D
	ORA	A	;TEST FOR TABLE END
	RZ		;NOT FOUND POST THAT AND RETURN
	PUSH	H	;SAVE START OF SCAN ADDRESS
	CMP	M	;TEST FIRST CHR
	INX	D
	JNZ	NCOM
;
	INX	H
	LDAX	D
	CMP	M	;NOW SECOND CHARACTER
	JNZ	NCOM	;GOODNESS
;
	POP	H	;RETURN HL TO PT TO CHAR START
	ORA	A	;FORCE TO NON-ZERO FLAG
	RET		;LET CALLER KNOW
;
;
NCOM:	INX	D	;GO TO NEXT ENTRY
	INX	D
	INX	D
	POP	H	;GET BACK ORIGINAL ADDRESS
	JMP	FDCOM	;CONTINUE SEARCH
;
;
; SET UP TO PROCESS AN INPUT LINE
; If output port is not VDM:
;	sets INPTR to beginning of input buffer
;	sets HL to INLIN
; If output port is VDM
;	sets INPTR to beginning of input buffer
;	removes the cursor (most significant bit of the current char)
;	sets HL to video memory of 2nd character on current line	
STUP:	EQU	$	;PREPARE WHETHER VDM OR NOT
	; Assume non-vdm input
	; Set INPTR to beginning of input buffer (INLIN)
	LXI	H,INLIN	;ASSUME NON-VDM INPUT
	SHLD	INPTR	;ALSO RESET PTR FOR NOW
	
	; Load output port to accumulator
	LDA	OPORT	;SEE IF IT IS VDM
	ORA	A	;IS IT THE VDM PORT
	RNZ		;NO--HL ARE SET PROPERLY
	CALL	CREM	;REMOVE CURSOR
	MVI	C,1	;GET VDM ADDR FM POSITION ONE
	JMP	VDAD2	;GET SCRN ADDR
;
;           COMMAND TABLE
;
;  THIS TABLE DESCRIBES THE VALID COMMANDS FOR CUTER
;
COMTAB:	EQU	$	;START OF KNOWN COMMANDS
	DB	'DU'	;DUMP
	DW	DUMP
	DB	'EN'	;ENTR
	DW	ENTER
	DB	'EX'	;EXEC
	DW	EXEC
	DB	'GE'	;GET
	DW	TLOAD
	DB	'SA'	;SAVE
	DW	TSAVE
	DB	'XE'	;XEQ
	DW	TXEQ
	DB	'CA'	;CAT
	DW	TLIST
	DB	'SE'	;SET COMMAND
	DW	CSET
	DB	'CU'	;CUSTOM COMMAND ENTER/CLEAR
	DW	CUSET
	DB	0	;END OF TABLE MARK
;
;
;               DISPLAY DRIVER COMMAND TABLE
;
;     THIS TABLE DEFINES THE CHARACTERS FOR SPECIAL
;  PROCESSING. IF THE CHARACTER IS NOT IN THE TABLE IT
;  GOES TO THE SCREEN.
;
	PUBLIC TBL
TBL:	DB	CLEAR	;SCREEN
	DW	ERASE_SCREEN
	DB	UP	;CURSOR
	DW	PUP
	DB	DOWN	;"
	DW	PDOWN
	DB	LEFT	;"
	DW	PLEFT
	DB	RIGHT	;"
	DW	PRIT
	DB	HOME	;"
	DW	PHOME
	DB	CR	;CARRIAGE RETURN
	DW	PCR
	DB	LF	;LINE FEED
	DW	PLF
	DB	BACKS	;BACK SPACE
	DW	PBACK
	DB	ESC	;ESCAPE KEY
	DW	PESC
	DB	0	;END OF TABLE
;
;   OUTPUT DEVICE TABLE
;
	PUBLIC OTAB
OTAB:	EQU $
	IFDEF OUT_0
	DW OUT_0
	ENDIF
	IFDEF OUT_1
	DW OUT_1
	ENDIF
	IFDEF OUT_2
	DW OUT_2
	ENDIF
	IFDEF OUT_3
	DW OUT_3
	ENDIF
;
;    INPUT DEVICE TABLE
;
	PUBLIC ITAB
ITAB:	EQU $
	IFDEF IN_0
	DW IN_0
	ENDIF
	IFDEF IN_1
	DW IN_1
	ENDIF
	IFDEF IN_2
	DW IN_2
	ENDIF
	IFDEF IN_3
	DW IN_3
	ENDIF
;
;
;       SECONDARY COMMAND TABLE FOR SET COMMAND
;
SETAB:	DB	'TA'	;SET TAPE SPEED
	DW	TASPD
	DB	'S='	;SET DISPLAY SPEED
	DW	DISPD
	DB	'I='	;SET INPUT PORT
	DW	SETIN
	DB	'O='	;SET OUTPUT PORT
	DW	SETOT
	DB	'CI'	;SET CUSTOM DRIVER ADDRESS
	DW	SETCI
	DB	'CO'	;SET CUSTOM OUTPUT DRIVER ADDRESS
	DW	SETCO
	DB	'XE'	;SET HEADER XEQ ADDRESS
	DW	SETXQ
	DB	'TY'	;SET HEADER TYPE
	DW	SETTY
	DB	'N='	;SET NUMBER OF NULLS
	DW	SETNU
	DB	'CR'	;SET CRC (NORMAL OR IGNORE CRC ERRORS)
	DW	SETCR
	DB	0	;END OF TABLE MARK
; -*-
;
;
;      OUTPUT A CRLF FOLLOWED BY A PROMPT
;
PROMPT: \
	CALL	CRLF
	MVI	B,'>'	;THE PROMPT
	JMP	SOUT	;PUT IT ON THE SCREEN

CRLF:	MVI	B,LF	;LINE FEED
	CALL	SOUT
	MVI	B,CR	;CARRIAGE RETURN
	CALL	SOUT
	LDA	NUCNT	;GET COUNT OF NULLS TO OUTPUT
	MOV	C,A	;SAVE COUNT IN C
-:	DCR	C
	RM		;COUNTED DOWN PAST ZERO (MAX COUNT IS X'7F')
	XRA	A	;HERE IS THE NULL
	CALL	OUTH	;OUTPUT IT
	JMP	-	;LOOP FOR NUMBER OF NULLS
;
;
; FIND_NEXT_ARG
; This routine will scan until it find the first blank character,
; and then once a blank character is identified, it will continue
; to scan until a non-blank is identified.  This is the first
; character of the next argument in the command.
; Arguments:
;	DE - Set to input buffer
; Returns:
;	zero flag set if it was unable to find another argument
;	zero flag not set if found another argu
; Returns non-zero if it has found another argument.
; 	The address of the argument will be loaded in DE 
FIND_NEXT_ARG:	\
	MVI	C,12	;MAXIMUM COMMAND STRING
-:	LDAX	D
	CPI	BLANK
	JZ	FIND_NON_BLANK	;GOT A BLANK NOW SCAN PAST IT
	INX	D
	CPI	'='	;A EQUAL WILL ALSO STOP US (AT NEXT CHAR)
	JZ	FIND_NON_BLANK	;FOUND, DE PT TO NEXT CHAR
	DCR	C	;NO MORE THAN TWELVE
	JNZ	-
	RET		;GO BACK WITH ZERO FLAG SET
;
;
;  SCAN PAST UP TO 10 BLANK POSITIONS LOOKING FOR
; A NON BLANK CHARACTER.
;
FIND_NON_BLANK:	\
	MVI	C,10	;SCAN TO FIRST NON BLANK CHR WITHIN 10
FIND_NON_BLANK1:	\
	LDAX	D	;GET NEXT CHARACTER
	CPI	SPACE
	RNZ		;WE'RE PAST THEM
	INX	D	;NEXT SCAN ADDRESS
	DCR	C
	RZ		;COMMAND ERROR
	JMP	FIND_NON_BLANK1	;KEEP LOOPING
;
; GET_HEX_ARG
; This routine find the next argument, converts it from hex,
; and stores the results in HL.  On error we call the error handler.
; Arguments:
;   DE - Pointer to input buffer
; Returns:
;   Hex value stored into H/L
GET_HEX_ARG:	\
	CALL	FIND_NEXT_ARG
	JZ	ERR1

;
; HEX_STR_TO_HL
; THIS ROUTINE CONVERTS ASCII DIGITS INTO BINARY FOLLOWING
; A STANDARD HEX CONVERSION.  THE SCAN STOPS WHEN AN ASCII
; SPACE IS ENCOUNTERED.  PARAMETER ERRORS REPLACE THE ERROR
; CHARACTER ON THE SCREEN WITH A QUESTION MARK.
; Arguments:
;    DE - Pointer to string
; Returns:
;    Hex valued into H/L
HEX_STR_TO_HL: \
	LXI	H,0	;CLEAR H & L
-:	LDAX	D	;GET CHARACTER
	CPI	20H	;IS IT A SPACE?
	RZ		;IF SO
	CPI	'/'
	RZ
	CPI	':'
	RZ

	; DAD H Adds HL to HL, thus shifting left one bit	
	; We shift left four bits.
	DAD	H
	DAD	H
	DAD	H
	DAD	H
	CALL	+	;DO THE CONVERSION
	JNC	ERR1	;NOT VALID HEXIDECIMAL VALUE
	ADD	L
	MOV	L,A	;MOVE IT IN
	INX	D	;BUMP THE POINTER
	JMP	-
;
+:	SUI	48	;REMOVE ASCII BIAS
	CPI	10
	RC		;IF LESS THAN 9
	SUI	7	;IT'S A LETTER??
	CPI	10H
	RET		;WITH TEST IN HAND
;
; GET_OPT_HEX_ARG
; THIS ROUTINE WILL SEE IF A FIELD (OPERAND) IS PRESENT.
; IF NOT, THEN HL WILL REMAIN AS THEY WERE ON ENTRY.
; IF IT WAS PRESENT, THEN HL=THAT VALUE IN HEX.
;
GET_OPT_HEX_ARG: \
	CALL	FIND_NEXT_ARG	;SEE IF FIELD IS PRESENT
	RZ		;RETURN LEAVING HL AS THEY WERE ON ENTRY
	CALL	HEX_STR_TO_HL	;FIELD IS THERE, GO GET IT
	RET		;HL= EITHER OPTIONAL FIELD (HEX), OR AS IT WAS
	

	include command_dump.asm
	include command_entr.asm
	include command_execute.asm
	include command_cassette.asm
	include command_set.asm
	include command_custom.asm

	ENDSECTION COMMAND

