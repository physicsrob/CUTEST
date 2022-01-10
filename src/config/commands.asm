	add_command 0, 'DU', DUMP, '<addr1> <addr2> - Dump memory data <addr1> to <addr2>'
	add_command 1, 'EN', ENTER, '<addr> - Enter data into memory STARTing at <addr>'
	add_command 2, 'EX', EXEC, '<addr> - Begin program execution at <addr>'
	add_command 3, 'GE', TLOAD, '(name(/unit) (addr)) - Get a tape file into memory'
	add_command 4, 'SA', TSAVE, 'name (/unit) <addr1> <addr2> <addr3> - Save a file from memory to tape'
	add_command 5, 'XE', TXEQ, '(name(/unit) (addr)) - Get then execute a tape file'
	add_command 6, 'CA', TLIST, '(/unit) Catalog tape files'
	add_command 7, 'SE', Cset, 'set'
	add_command 8, 'CU', CUset, 'Custom command'
	
	if STRINGS = TRUE
	add_command 9, 'HE', HELP, 'Help'
	endif