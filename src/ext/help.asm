HELP:	equ	$
	lxi	H, HELP_STR
	jmp	write_line

HELP_STR: \
	equ	$
	db	LF
	get_help_entry 0
	get_help_entry 1
	get_help_entry 2
	get_help_entry 3
	get_help_entry 4
	get_help_entry 5
	get_help_entry 6
	get_help_entry 7
	get_help_entry 8
	get_help_entry 9
	get_help_entry 10
	get_help_entry 11
	get_help_entry 12
	get_help_entry 13
	get_help_entry 14
	get_help_entry 15
	db "?   Help"
	db LF
	db "SET ? Set Help"
	db LF
	db	0	;END OF STRING

