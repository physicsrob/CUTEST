       ORG EXT_ADDRESS

       ; Identify ourselves
       mov b, b

       ; Install command table
	lxi h, ext_cmd_tab
	call load_cmd_tab

       ; Display Banner
       lxi     H, BANNER_STR
       call    write_line

       ret
       
       
ext_cmd_tab:
	db 'IN'
	dw in
	db 'OU'
	dw out
       db 0
       db 0
       
       include strutil.asm
       include strings.asm
       include inout.asm