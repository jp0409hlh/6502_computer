.segment "RESET"

RESET:
    cld
    sei 
; VIA initialization
    lda #%11111111              ; Set all pins on port B to output
    sta DDRB
    lda #%00000000              ; Set all pins on port A to input
    sta DDRA
    lda #$82                    ; enable ca1 interrupt
    sta IER                     
    lda #$01                    ; ca1 positive edge
    sta PCR
; acia init
    lda #$00
    sta ACIA_STATUS
    lda #$1E                    ; 8-N-1, 9600 baud
    sta ACIA_CTRL
    lda #$09                    ; no parity, no echo, interrupt
    sta ACIA_CMD
    lda ACIA_DATA               ; dummy read 

    sta SER_RPTR
    sta SER_WPTR


.if .def(TMS9918_VDP)
; VDP initialization
    lda #$00
    sta CURSOR_L                ; Reset cursor position
    sta CURSOR_H
    sta CURSOR_X
    sta CURSOR_Y

    lda #40                     ; Set screen width with 40 (textmode)
    sta SCREEN_WIDTH
    lda #24                     ; Set screen height with 24
    sta SCREEN_HEIGHT

    lda #<font
    sta FONT_L
    lda #>font
    sta FONT_H

    lda #<font_end
    sta FONT_END_L
    lda #>font_end
    sta FONT_END_H

    lda #%00000000                          ; No external VDP input
    sta VDP_REG
    lda #VDP_REG0
    sta VDP_REG

    lda #%11010000                          ; 16K/ BLANK disable/ No Int/ TextMode/ 8x8 sprite/ Sprite MAG0
    sta VDP_REG
    lda #VDP_REG1
    sta VDP_REG

    lda #$00 								; Name table starts at $0000
    sta VDP_REG
    lda #VDP_REG2
    sta VDP_REG

    lda #$0D                                ; Color table starts at $0340
    sta VDP_REG
    lda #VDP_REG3
    sta VDP_REG

    lda #$01 								; Pattern table starts at $0800
    sta VDP_REG
    lda #VDP_REG4
    sta VDP_REG

    lda #$00                                ; !!!!!!!!!! SPRITE ATTR TABLE !!!!!!!
    sta VDP_REG
    lda #VDP_REG5
    sta VDP_REG

    lda #$00                                ; !!!!!!!! SPRITE PATTERN TABLE !!!!!!
    sta VDP_REG
    lda #VDP_REG6
    sta VDP_REG

    lda #$F1                                ; Text mode F/B color (white/black)
    sta VDP_REG
    lda #VDP_REG7
    sta VDP_REG

    clc
    ldx #$00
copy_pattern:                               ; Loop for copying font into pattern table
    lda #$00                                ; Setting up pattern table base address($0800)            
    sta VDP_REG
    lda #($08| $40)
    sta VDP_REG
    lda font
    sta VDP_RAM

    ldy #$00
copy_pattern_loop:
    inc FONT_L
    bne continue_copy
    inc FONT_H
continue_copy:
    lda (FONT_L),y
    sta VDP_RAM

    lda FONT_H			                    ;checks if its the end of the font 
    cmp FONT_END_H
    bne copy_pattern_loop
    lda FONT_L
    cmp FONT_END_L
    bne copy_pattern_loop

    ldx #0
    lda #$00
    sta VDP_REG
    lda #($00 | $40)
    sta VDP_REG

clean_screen:
    ldy #25
clean_loop:
    ldx SCREEN_WIDTH
clean_loop1:
    lda #' '                            ; Space
    sta VDP_RAM
    dex
    bne clean_loop1
    dey
    bne clean_loop
 
;initialize cursor positon
    lda #$00
    sta CURSOR_X
    sta CURSOR_Y
    lda #$00
    sta VDP_REG
    lda #$00
    ora #$40
    sta VDP_REG
.endif

; Setting up the default routine vector
; Output vectors
.if .def(TMS9918_VDP)
    lda #<VPRINTC
    sta CHR_OUT_VEC
    lda #>VPRINTC
    sta CHR_OUT_VEC + 1

    lda #<VPRINTCCTRL
    sta CTRL_CHR_OUT_VEC
    lda #>VPRINTCCTRL
    sta CTRL_CHR_OUT_VEC + 1
    
    lda #<VPRINTS
    sta STR_OUT_VEC
    lda #>VPRINTS
    sta STR_OUT_VEC + 1 

    lda #<VCHRSET
    sta CHR_SET_VEC
    lda #>VCHRSET
    sta CHR_SET_VEC + 1 
.else 
    lda #<SPRINTC
    sta CHR_OUT_VEC
    lda #>SPRINTC
    sta CHR_OUT_VEC + 1

    lda #<SPRINTC
    sta CTRL_CHR_OUT_VEC
    lda #>SPRINTC
    sta CTRL_CHR_OUT_VEC + 1
    
    lda #<SPRINTS
    sta STR_OUT_VEC
    lda #>SPRINTS
    sta STR_OUT_VEC + 1

    lda #<SCHRSET
    sta CHR_SET_VEC
    lda #>SCHRSET
    sta CHR_SET_VEC + 1 
.endif

; Input vectors
.if .def(KEYBOARD)
    lda #<KBGETC
    sta CHAR_IN_VEC
    lda #>KBGETC
    sta CHAR_IN_VEC + 1
.else 
    lda #<SGETC
    sta CHAR_IN_VEC
    lda #>SGETC
    sta CHAR_IN_VEC + 1
.endif

; IRQ routine vectors
    lda #$60                    ; Setting up the dummy interrupt routine (rts)
    sta $0000                   ; DUMMY_ISR := $0000

    lda #$00                    ; First default every ISR to dummy interrupt routine (Located at $0000)      
    sta ISR_VEC0
    sta ISR_VEC0 + 1
    sta ISR_VEC1 
    sta ISR_VEC1 + 1
    sta ISR_VEC2
    sta ISR_VEC2 + 1
    sta ISR_VEC3
    sta ISR_VEC3 + 1
    sta ISR_VEC4
    sta ISR_VEC4 + 1
    sta ISR_VEC5
    sta ISR_VEC5 + 1
    sta ISR_VEC6
    sta ISR_VEC6 + 1
    sta ISR_VEC7
    sta ISR_VEC7 + 1
    sta ISR_VEC8
    sta ISR_VEC8 + 1
    sta ISR_VEC9
    sta ISR_VEC9 + 1
    sta ISR_VEC10
    sta ISR_VEC10 + 1
    sta ISR_VEC11
    sta ISR_VEC11 + 1
    sta ISR_VEC12
    sta ISR_VEC12 + 1
    sta ISR_VEC13
    sta ISR_VEC13 + 1
    sta ISR_VEC14
    sta ISR_VEC14 + 1
    sta ISR_VEC15
    sta ISR_VEC15 + 1

; Setting up the keyboard interrupt service routine to ISR vector and some initialization
.if .def(KEYBOARD)
    lda #<KB_ISR
    sta ISR_VEC0
    lda #>KB_ISR
    sta ISR_VEC0 + 1

    lda #$00
    sta KB_FLAG
    sta KB_RPTR
    sta KB_WPTR
    sta READ_PTR
.endif

    lda #<SER_ISR
    sta ISR_VEC1
    lda #>SER_ISR 
    sta ISR_VEC1 + 1


    cli 
    jmp SHELL_START



    




