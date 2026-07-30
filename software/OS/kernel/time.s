; ********************************************************
; *                        TIME                          *
; ******************************************************** 

; SLEEP IN SECONDS
; Usage: Halts the processor
; How to use:
; Modified flag :
; Modified register : 
; Modified memory : ZPR0
.proc SLEEPSEC
    sta ZPR0                    ; How many seconds to pass?
    pha 
    txa 
    pha 
    tya 
    pha 

    pla 
    tay 
    pla 
    tax 
    pla 
    rts
.endproc  

; SLEEP IN MILLISECONDS
; Usage: Halts the processor
; How to use:
; Modified flag :
; Modified register : 
; Modified memory : 
.proc SLEEPMILLISEC
    sta ZPR0                    ; How many seconds to pass?

    pha 
    txa 
    pha 
    tya 
    pha 

    pla 
    tay 
    pla 
    tax 
    pla 
    rts 
.endproc 