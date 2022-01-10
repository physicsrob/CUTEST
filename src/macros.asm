	macexp_dft	noif, nomacro

call_until_nz	macro	addr
$$loop		call addr
		jz $$loop
		endm


add_PSEUDOPORT	macro	i, \
				VDM, \
				DATAPORT, \
				staTUSPORT, \
				READMASK, \
				READiNVERT, \
				WRITEMASK, \
				RESETMASK, \
				setupMASK \
		

in_i:		equ $
		in staTUSPORT
		if strlen("READiNVERT")>0
		   CMA
		endif
		ani READMASK
		rz
		in DATAPORT
		ret

		if strlen("VDM")>0
USEVDM:	   equ TRUE
out_i:		   equ VDM01
		ELSE
out_i:		   equ $
$$loop		   in staTUSPORT
		   ani WRITEMASK
		   jz $$loop
		   mov A,B
		   out DATAPORT
		   ret
		endif

setup_i	macro
		   if strlen("RESETMASK")>0
			mvi	A, RESETMASK 
			OUT	staTUSPORT	
		   endif
		   if strlen("setupMASK")>0
			mvi	A, setupMASK 
			OUT	staTUSPORT	
		   endif
		endm

		endm
	

add_command	macro i, NAME, PTR, HLP
CMDNAME_i	set NAME
CMDPTR_i	set PTR
CMDHELP_i	set HLP
		endm	


get_comtab_entry	macro i
			ifdef CMDNAME_i
			db	CMDNAME_i
			dw	CMDPTR_i
			endif
			endm

get_help_entry	macro i
			ifdef CMDHELP_i
			db CMDNAME_i
			db '   '
			db CMDHELP_i
			db LF
			endif
			endm
