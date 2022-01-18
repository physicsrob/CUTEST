	macexp_dft	noif, nomacro

call_until_nz	macro	addr
$$loop		call addr
		jz $$loop
		endm


ADD_PSEUDOPORT	macro	i, \
				VDM, \
				DATAPORT, \
				STATUSPORT, \
				READMASK, \
				READINVERT, \
				WRITEMASK, \
				RESETMASK, \
				SETUPMASK \


	if strlen("VDM") > 0
PSEUDOPORT_i_USEVDM equ True
USEVDM equ True
	else
PSEUDOPORT_i_USEVDM equ False
	endif

PSEUDOPORT_i_DPORT equ DATAPORT 
PSEUDOPORT_i_SPORT equ STATUSPORT
PSEUDOPORT_i_RMASK equ READMASK

	if strlen("READINVERT")>0
PSEUDOPORT_i_RINVERT equ READINVERT
	else
PSEUDOPORT_i_RINVERT equ False
	endif
	
	if strlen("WRITEMASK") > 0
PSEUDOPORT_i_WMASK equ WRITEMASK
	else
PSEUDOPORT_i_WMASK equ False
	endif

	if strlen("RESETMASK")>0
PSEUDOPORT_i_RSTMASK equ RESETMASK
	else
PSEUDOPORT_i_RSTMASK equ False
	endif
	

	if strlen("SETUPMASK")>0
PSEUDOPORT_i_STPMASK equ SETUPMASK
	else
PSEUDOPORT_i_STPMASK equ False
	endif

	endm

input_routine	macro i
	ifdef PSEUDOPORT_i_DPORT

	in PSEUDOPORT_i_SPORT 
	if PSEUDOPORT_i_RINVERT <> False
		CMA
	endif
	ani PSEUDOPORT_i_RMASK
	rz
	in PSEUDOPORT_i_DPORT
	ret

	endif
	endm

output_routine macro i
	ifdef PSEUDOPORT_i_DPORT

	if PSEUDOPORT_i_USEVDM <> False
	jmp VDM01
	else
$$loop in PSEUDOPORT_i_SPORT
	ani PSEUDOPORT_i_WMASK 
	jz $$loop
	mov A,B
	out PSEUDOPORT_i_DPORT
	ret
	endif
	endif
	endm

setup_routine	macro i
	ifdef PSEUDOPORT_i_DPORT
	
	if PSEUDOPORT_i_RSTMASK <> False
	mvi A, PSEUDOPORT_i_RSTMASK
	out PSEUDOPORT_i_SPORT
	endif
	
	if PSEUDOPORT_i_STPMASK <> False
	mvi A, PSEUDOPORT_i_RSTMASK
	out PSEUDOPORT_i_SPORT
	endif
	
	endif
	endm
