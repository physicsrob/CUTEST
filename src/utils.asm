
; --- memset ---
; Set chunk of memory to one value.
; Arguments:
;    HL - Pointer to memory
;    DE - length to set
;    B - value to set
; --------------
memset:
       mov m, b
       inx h
       dcx d
       xra a
       ora d
       ora e
       jnz memset
       ret
