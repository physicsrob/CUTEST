;
;
;    S Y S T E M    E Q U A T E S
;
; Default memory plan:
; C000 - C7FF CUTEST BASE   (2k)
; C800 - CBFF UNUSED        (1k)  
; CC00 - CFFF VDM Memory    (1k)
; D000 - D7FF CUTEST EXT    (2k)
; D800 - DFFF CUTEST MEMORY (2k)

BASE_ADDRESS  equ 03000H
EXT_ADDRESS   equ 04000H
MEM_ADDRESS   equ 0D800H 
MEM_SIZE      equ 0800H     ; 2k memory
SENSE_PORT    equ 0FFH      ;SENSE SWITCHES

AUTOLOAD_EXT  equ True

;          VDM PARAMETERS
;
VDM_MEM       equ 0CC00H    ; VDM SCREEN MEMORY
VDM_STAT_PORT equ 0C8H      ; VDM CONTROL PORT

; Uncomment either CUTS or TARBELL
;TAPE_DRIVER   equ "CUTS"
TAPE_DRIVER   equ "TARBELL"


escape_key_test: MACRO
       ; Check for control-C
	cpi 3
       ; Original SOLOS/CUTER behavior:
       ; Check for "EITHER MODE OR CTL-@""
	; ani	7FH
       ENDM



       ; Pseudoport 0 = Processor Tech VDM1 + Keyboard
       ;ADD_PSEUDOPORT       0, \
       ;                    VDM=TRUE, \
       ;                    DATAPORT=3, \
       ;                    STATUSPORT=0, \
       ;                    READMASK=1, \
       ;                    READINVERT=TRUE

       ; Pseudoport 1 =  882SIO port 1
       ADD_PSEUDOPORT       0, \
                            DATAPORT=11h, \
                            STATUSPORT=10h, \
                            READMASK=1, \
                            WRITEMASK=2, \
                            RESETMASK=3, \
                            SETUPMASK=17 \


       ; Simulator ports
       ; ADD_PSEUDOPORT       0, \
       ;                      VDM=TRUE, \
       ;                      DATAPORT=5h, \
       ;                      STATUSPORT=4h, \
       ;                      READMASK=1, \
       ;                      READINVERT=TRUE

       ; ADD_PSEUDOPORT       1, \
       ;                      DATAPORT=1h, \
       ;                      STATUSPORT=0h, \
       ;                      READMASK=1, \
       ;                      WRITEMASK=128, \
       ;                      READINVERT=TRUE
