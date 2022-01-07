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

	ADD_COMMAND 'DU', DUMP, '<addr1> <addr2> - Dump memory data <addr1> to <addr2>'
	ADD_COMMAND 'EN', ENTER, '<addr> - Enter data into memory starting at <addr>'
	ADD_COMMAND 'EX', EXEC, '<addr> - Begin program execution at <addr>'
	ADD_COMMAND 'GE', TLOAD, '(name(/unit) (addr)) - Get a tape file into memory'
	ADD_COMMAND 'SA', TSAVE, 'name (/unit) <addr1> <addr2> <addr3> - Save a file from memory to tape'
	ADD_COMMAND 'XE', TXEQ, '(name(/unit) (addr)) - Get then execute a tape file'
	ADD_COMMAND 'CA', TLIST, '(/unit) Catalog tape files'
	ADD_COMMAND 'SE', CSET, 'Set'
	ADD_COMMAND 'CU', CUSET, 'Custom command'
