	ADD_COMMAND 0, 'DU', DUMP, '<addr1> <addr2> - Dump memory data <addr1> to <addr2>'
	ADD_COMMAND 1, 'EN', ENTER, '<addr> - Enter data into memory starting at <addr>'
	ADD_COMMAND 2, 'EX', EXEC, '<addr> - Begin program execution at <addr>'
	ADD_COMMAND 3, 'GE', TLOAD, '(name(/unit) (addr)) - Get a tape file into memory'
	ADD_COMMAND 4, 'SA', TSAVE, 'name (/unit) <addr1> <addr2> <addr3> - Save a file from memory to tape'
	ADD_COMMAND 5, 'XE', TXEQ, '(name(/unit) (addr)) - Get then execute a tape file'
	ADD_COMMAND 6, 'CA', TLIST, '(/unit) Catalog tape files'
	ADD_COMMAND 7, 'SE', CSET, 'Set'
	ADD_COMMAND 8, 'CU', CUSET, 'Custom command'
	
	IF STRINGS = TRUE
	ADD_COMMAND 9, 'HE', HELP, 'Help'
	ENDIF