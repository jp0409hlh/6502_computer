.segment "BIOS"


RESET:
    cld
    clc
; VIA initialization

; acia init
    lda #$1e                    ; 8-N-1, 9600 baud
    sta ACIA_CTRL
    lda #$0b                    ; no parity, no echo, no interrupt
    sta ACIA_CMD
    lda ACIA_DATA               ; dummy read 


.ifdef TMS9918 
; VDP initialization
    lda #$00
    sta CURSOR_L                ; reset cursor position
    sta CURSOR_H
    sta CURSOR_X
    sta CURSOR_Y

.endif







; KEYBOARD CHARACTER IN 
; Usage : Get a character from keyboard.
; How to use : If carry set, read character from A.
; Modified flag : C
; Modified registers : A
; Modified memory : none 
;KBCHRIN:


; SERIAL CHARACTER IN 
; Usage : Get a character from serial.
; How to use : If carry set, read character from A.
; Modified flag : C
; Modified registers : A
; Modified memory : none
;SERCHRIN:


; VIDEO CHARACTER OUT 
; Usage : Write character to VDP.
; How to use : Store the desired character to A and call this
; subroutine.
; Modified flag : ?
; Modified registers : ?
; Modified memory : ?
;VCHROUT:
    
;   jsr


; SERIAL CHARACTER OUT 
; Usage : Output a character to serial.
; How to use : Store the desired character to A and call this
; subroutine.
; Modified flag : ?
; Modified registers : none
; Modified memory : none
;SERCHROUT:

    




.segment "VECTOR"
    .word NMI
    .word RESET
    .word IRQ