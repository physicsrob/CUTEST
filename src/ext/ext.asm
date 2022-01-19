       ORG EXT_ADDRESS

       ; Identify ourselves
       mov b, b

       ; Install command table
	lxi h, ext_cmd_tab
       mvi b, 2
	call register_command_tab

       ; Display Banner
       lxi     H, BANNER_STR
       call    write_line

       ret
       
       
ext_cmd_tab:
	db 'IN'
	dw in
	db 'OU'
	dw out
       
       include strutil.asm
       include strings.asm
       include inout.asm