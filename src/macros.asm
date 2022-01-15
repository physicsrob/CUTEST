	macexp_dft	noif, nomacro

call_until_nz	macro	addr
$$loop		call addr
		jz $$loop
		endm


add_PSEUDOPORT	macro	i, \
				VDM, \
				DATAPORT, \
				STATUSPORT, \
				READMASK, \
				READiNVERT, \
				WRITEMASK, \
				RESETMASK, \
				SETUPMASK \
		

in_i:		equ $
		in STATUSPORT
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
$$loop		   in STATUSPORT
		   ani WRITEMASK
		   jz $$loop
		   mov A,B
		   out DATAPORT
		   ret
		endif

setup_i	macro
		   if strlen("RESETMASK")>0
			mvi	A, RESETMASK 
			OUT	STATUSPORT	
		   endif
		   if strlen("SETUPMASK")>0
			mvi	A, SETUPMASK 
			OUT	STATUSPORT	
		   endif
		endm

		endm
	