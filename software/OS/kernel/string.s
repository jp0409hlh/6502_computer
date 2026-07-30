; ********************************************************
; *                        STRING                        *
; ******************************************************** 


; STRING COMPARE CASE SENSITIVE
; Usage: Compares two strings (case sensitive)
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
.proc STR_CMP_CS
    ldy #$00        ;Compare strings, case-sensitive
    lda (STR_PTR),Y     ;Naturally, the zero flag is used to return if the strings are equal
    cmp (STR_PTR1),Y
    beq str_cmp1
    jmp str_cmp_exit
str_cmp1:
    tay
str_cmp_loop:
    lda (<STR_PTR1),Y
    and #$7F
    sta ZPR2
    lda (<STR_PTR),Y
    and #$7F
    cmp ZPR2
    bne str_cmp_exit
    dey
    bne str_cmp_loop
str_cmp_exit:
    rts
.endproc 

; STRING COMPARE CASE NON-SENSITIVE
; Usage: Compares two strings (case not sensitive)
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
.proc STR_CMP_CNS
    rts
.endproc 

; STRING COPY
; Usage: Copys a string to another location
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
.proc STR_CPY
    rts 
.endproc 

; STRING TO INT
; Usage: Converts string to integer
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
.proc ATOI
    rts 
.endproc 

; INT TO STRING
; Usage: Converts integer to string 
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
.proc ITOA
    rts 
.endproc 

; STRING TO FLOAT
; Usage: Converts string to float
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
.proc ATOF
    rts
.endproc 

; FLOAT TO STRING
; Usage: Converts float to integer
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
.proc FTOA
    rts
.endproc 

;HEX STRING TO VALUE
.proc ATOH
    tya 
    pha 
    txa 
    pha 
    ldy #$00
    sty RET_VAL
    sty RET_VAL + 1
    sty RET_VAL + 2
    sty RET_VAL + 3
loop:
    ldx #0
    tya 
    cmp (STR_PTR,X)                 ; Compare to length
    beq exit
    iny
    lda (STR_PTR),Y                 ; Get character fror hex test
    eor #$30                        ; Map digit to $0-9
    cmp #$0A                        ; Digit?
    bcc is_digit                    ; Yes
    adc #$88                        ; Map letter "A"-"F" to $FA-$FF
    cmp #$FA                        ; Is upper-case hex?
    bcs is_digit                    ; Yes
    adc #$20                        ; Map letter "a"-"f" to $FA-$FF
    cmp #$FA                        ; Is lower-case hex?
    bcs is_digit                    ; Yes
    jmp error_exit                  ; Otherwise return with error
is_digit:
    ldx #4
hexshift:
    asl RET_VAL
    rol RET_VAL + 1 
    rol RET_VAL + 2
    rol RET_VAL + 3
    dex
    bne hexshift
    and #$0F
    ora RET_VAL
    sta RET_VAL
    jmp loop
exit:
    sec 
    jmp pull

error_exit:
    clc
pull:
    pla 
    tax 
    pla 
    tay 
    rts 
.endproc

;HEX VALUE TO STRING
.proc HTOA
    pha 
    txa                             ; Save X
    pha             
    tya                             ; Save Y, Y is the string index
    pha 

    ldy #$00
    lda #8 
    sta RET_STR
    iny 
    lda ARG0_VAL + 3
    pha 
    lsr A 
    lsr A 
    lsr A 
    lsr A 
    jsr prhex
    pla 
    iny 
    jsr prhex 

    iny 
    lda ARG0_VAL + 2
    pha 
    lsr A 
    lsr A 
    lsr A 
    lsr A 
    jsr prhex
    pla 
    iny 
    jsr prhex 

    iny 
    lda ARG0_VAL + 1
    pha 
    lsr A 
    lsr A 
    lsr A 
    lsr A 
    jsr prhex
    pla 
    iny 
    jsr prhex 

    iny 
    lda ARG0_VAL
    pha 
    lsr A 
    lsr A 
    lsr A 
    lsr A 
    jsr prhex
    pla 
    iny 
    jsr prhex 
exit:
    pla 
    tay 
    pla 
    tax 
    pla 
    rts 

prhex:
    and #$0F                    ; Mask LSD for hex
    ora #$30                    ; add '0'
    cmp #$3A                    ; Is digit?
    bcc str_chr                 ; Yes, store to string
    adc #$06                    ; Add offset for letter
str_chr:
    sta RET_STR,Y 
    rts 
.endproc