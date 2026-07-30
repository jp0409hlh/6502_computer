; ********************************************************
; *           DEFAULT INTERRUPT SERVICE ROUTINE          *
; ******************************************************** 

.if .def(KEYBOARD)
; KEYBOARD INTERRUPT SERVICE ROUTINE (Not to be confused with KBGETC)
; Usage: Puts the key into KB_BUF
; Modified flag : None
; Modified register : None
; Modified memory : KB_BUF, KB_FLAG, KB_RPTR, KB_WPTR
.proc KB_ISR
    pha 
    txa 
    pha 

    lda IFR 
    and #IFR_CA1                ; Did CA1(keyboard) cause the interrupt?
    beq exit                    ; No, exits.
                                ; Otherwise, start processing key input
    lda KB_FLAG                 ; Read keyboard flag
    and #RELEASED               ; Check if releaseing a key
    beq read_key                ; Not releasing a key, reads the key
    lda KB_FLAG                 ; Otherwise, flips the releasing key flag
    eor #RELEASED               ; Flip the releasing key flag
    sta KB_FLAG
    lda PORTA                   ; read to clear the interrupt, also reads the released key
    cmp #$12                    ; Is left shift being released? 
    beq shift_up                ; Yes
    cmp #$59                    ; Is right shift being released?
    beq shift_up                ; Yes
    jmp exit                    ; Otherwise, ignores released key

shift_up:                       ; Shift key is released. Flips the shift flag
    lda KB_FLAG
    eor #SHIFT
    sta KB_FLAG
    jmp exit 

; Getting the corresponding ascii character
read_key:
    lda PORTA                   ; Get scancode
    cmp #$F0                    ; Is it a release indicator?
    beq key_release             ; Yes
    cmp #$12                    ; Is it a left shift? 
    beq shift_down              ; Yes
    cmp #$59                    ; Is it a right shift?
    beq shift_down              ; Yes

    tax                         ; Transfer scancode to X
    lda KB_FLAG
    and #SHIFT                  ; Is shift flag set?
    bne shifted_key             ; Yes, get shifted ascii
    lda keymap, x               ; Otherwise, get normal ascii
    jmp push_key

shifted_key:
    lda keymap_shifted, x

; Put the ascii character(Stored in A) into the Keyboard buffer
push_key:                       ; Normal ascii
    ldx KB_WPTR
    sta KB_BUF, x               ; Put it in the buffer
    inc KB_WPTR
    jmp exit

shift_down:                     ; Shift is pressed
    lda KB_FLAG
    ora #SHIFT                  ; set shift flag
    sta KB_FLAG
    jmp exit

key_release:                    ; Key is released
    lda KB_FLAG
    ora #RELEASED               ; set released flag
    sta KB_FLAG
exit:
    pla 
    tax 
    pla 
    rts 
.endproc 

keymap:
    .byte "????????????? `?" ; 00-0f
    .byte "?????q1???zsaw2?" ; 10-1f
    .byte "?cxde43?? vftr5?" ; 20-2f
    .byte "?nbhgy6???mju78?" ; 30-3f
    .byte "?,kio09??./l;p-?" ; 40-4f
    .byte "??'?[=????", $0A ,"]?\??" ; 50-5f
    .byte "??????",$08,"??1?47???" ; 60-6f
    .byte "0.2568", $1B,"??+3-*9??" ; 70-7f
    .byte "????????????????" ; 80-8f
    .byte "????????????????" ; 90-8f
    .byte "????????????????" ; a0-8f
    .byte "????????????????" ; b0-8f
    .byte "????????????????" ; c0-8f
    .byte "????????????????" ; d0-8f
    .byte "????????????????" ; e0-8f
    .byte "????????????????" ; f0-8f

keymap_shifted:
    .byte "????????????? ~?" ; 00-0f
    .byte "?????Q!???ZSAW@?" ; 10-1f
    .byte "?CXDE$#?? VFTR%?" ; 20-2f
    .byte "?NBHGY^???MJU&*?" ; 30-3f
    .byte "?<KIO)(??>?L:P_?" ; 40-4f
    .byte "??", $22,"?{+?????}?|??" ; 50-5f
    .byte "?????????1?47???" ; 60-6f
    .byte "0.2568???+3-*9??" ; 70-7f
    .byte "????????????????" ; 80-8f
    .byte "????????????????" ; 90-8f
    .byte "????????????????" ; a0-8f
    .byte "????????????????" ; b0-8f
    .byte "????????????????" ; c0-8f
    .byte "????????????????" ; d0-8f
    .byte "????????????????" ; e0-8f
    .byte "????????????????" ; f0-8f

.endif

; SERIAL INTERRUPT SERVICE ROUTINE
; Usage: Processes interrupt caused by the ACIA
.proc SER_ISR
    pha
    txa 
    pha 

    lda ACIA_STATUS
    and #ACIA_STAT_INT                  ; ACIA caused the interrupt?
    beq exit                            ; No, skips
    lda ACIA_DATA
    ldx SER_WPTR
    sta SER_BUF, X
    inc SER_WPTR

exit:
    pla 
    tax
    pla 
    rts 
.endproc 

ISR0:
    jmp (ISR_VEC0)
ISR1:
    jmp (ISR_VEC1)
ISR2:
    jmp (ISR_VEC2)
ISR3:
    jmp (ISR_VEC3)
ISR4:
    jmp (ISR_VEC4)
ISR5:
    jmp (ISR_VEC5)
ISR6:
    jmp (ISR_VEC6)
ISR7:
    jmp (ISR_VEC7)
ISR8:
    jmp (ISR_VEC8)
ISR9:
    jmp (ISR_VEC9)
ISR10:
    jmp (ISR_VEC10)
ISR11:
    jmp (ISR_VEC11)
ISR12:
    jmp (ISR_VEC12)
ISR13:
    jmp (ISR_VEC13)
ISR14:
    jmp (ISR_VEC14)
ISR15:
    jmp (ISR_VEC15)


; Main IRQ routine, goes through all 16 ISRs
IRQ:
    jsr ISR0
    jsr ISR1 
    jsr ISR2
    jsr ISR2
    jsr ISR3
    jsr ISR4
    jsr ISR5
    jsr ISR6
    jsr ISR7 
    jsr ISR8
    jsr ISR9
    jsr ISR10
    jsr ISR11
    jsr ISR12
    jsr ISR13
    jsr ISR14
    jsr ISR15
    rti 

NMI:
    rti 