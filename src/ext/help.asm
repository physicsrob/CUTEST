HELP:	equ	$
	; Check if we're getting set help
	call NAME0

	lxi H, THEAD
	lxi D, SET_STR	
	mvi B, 3
	call memcmp
	
	jz set_help

	lxi	H, HELP_STR
	jmp	write_line

set_help:
	lxi	H, SET_HELP_STR
	jmp	write_line

HELP_STR: \
	db '\n'
	db 'DU(MP)  <addr1> <addr2> - Dump memory data addr1 to addr2\n'
       db 'EN(TER) <addr> - Enter data into memory at addr\n'
       db 'EX(EC)  <addr> - Begin program execution at addr\n'
       db 'GE(T)   (name(/unit) (addr)) - Get a tape file into memory\n'
       db 'SA(VE)  (/unit) <a1> <a2> <a3> - Save file from memory to tape\n'
       db 'XE      (name(/unit) (addr)) - Get then execute a tape file\n'
       db 'CA      (/unit) Catalog tape files\n'
       db 'SE(T)   <key>=<value>\n'
       ;'CU', CUSET, 'Custom command'
       db 'IN      <port> - Read from port\n'
       db 'OU      <port> <value> - Write to port\n'
       db 'HI      Input intel hex\n'
	db '?      Help\n'
	db '? SET  Set Help \n'
	db 0	;END OF STRING

SET_STR:
	db 'SET'
	db 0

SET_HELP_STR:
	db '\n'
	db 'SET <key> = <value>\n'
	db 'TA   Tape speed\n'
	db 'S    Display speed\n'
	db 'I    Input pseudoport\n'
	db 'O    Output psuedoport\n'
	db 'XE   File header XEQ address\n'
	db 'TY   Header type\n'
	db 'N    Number of nulls following CRLF\n'
	db 'CR   CRC (Normal or Ignore CRC errors)\n'
	db 0
