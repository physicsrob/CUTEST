       ORG EXT_ADDRESS

       ; Identify ourselves
       mov b, b

       ; Install command table
	lxi h, ext_cmd_tab
       mvi b, ext_cmd_tab_len
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
       db 'IH'
       dw inhex
       db '? '
       dw HELP

ext_cmd_tab_len equ 4

       ;include debug.asm
       include strutil.asm
       include strings.asm
       include inout.asm
       include help.asm
       include ihex.asm
