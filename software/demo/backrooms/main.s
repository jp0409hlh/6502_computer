KEYBOARD = 1
TMS9918_VDP = 1
ACIA_BUG = 1

IFR_CA2 = %00000001
IFR_CA1 = %00000010

ACIA_STAT_INT = %10000000

; XMODEM
SOH = $01
EOT = $04
ACK = $06
NAK = $15
CAN = $18

.if .def(KEYBOARD)
RELEASED    = %00000001
SHIFT       = %00000010
.endif

.if .def(TMS9918_VDP)
; VDP
VDP_RAM = $A000
VDP_REG = $A001

VDP_REG0 = $80
VDP_REG1 = $81
VDP_REG2 = $82
VDP_REG3 = $83
VDP_REG4 = $84
VDP_REG5 = $85
VDP_REG6 = $86
VDP_REG7 = $87
.endif

; ACIA
ACIA_DATA = $8600
ACIA_STATUS = $8601
ACIA_CMD = $8602
ACIA_CTRL = $8603

; VIA
PORTB    = $8200
PORTA    = $8201
DDRB     = $8202
DDRA     = $8203
T1CL     = $8204
T1CH     = $8205
T1LL     = $8206
T1LH     = $8207
T2CL     = $8208
T2CH     = $8209
SR       = $820A
ACR      = $820B
PCR      = $820C
IFR      = $820D
IER      = $820E


;***********************************************************
;*                 RAM memory location                     *
;***********************************************************
.segment "ZEROPAGE"
DUMMY_ISR : .res 1
; general purpose registors
ZPR0 : .res 1
ZPR1 : .res 1
ZPR2 : .res 1
ZPR3 : .res 1
ZPR4 : .res 1
ZPR5 : .res 1
ZPR6 : .res 1
ZPR7 : .res 1
ZPR8 : .res 1
ZPR9 : .res 1
ZPR10 : .res 1
ZPR11 : .res 1
ZPR12 : .res 1
ZPR13 : .res 1
ZPR14 : .res 1
ZPR15 : .res 1

; wozmon stuffs
MON_XAML = ZPR0                         ; Last opened mem location low
MON_XAMH = ZPR1                         ; Lasr opened mem location high
MON_STL = ZPR2                          ; Store address low
MON_STH = ZPR3                          ; Store address high
MON_L = ZPR4                            ; Hex parsing low
MON_H = ZPR5                            ; Hex parsing high
MON_YSAV = ZPR6                         ; Used to see if hex value is given
MON_MODE = ZPR7                         ; $00 = XAM, $7F=STOR, $AE=BLK XAM

; variables
SER_RPTR : .res 1                    ; serial buffer read pointer
SER_WPTR : .res 1                      ; serial buffer write pointer

READ_PTR : .res 1
READ_END_PTR : .res 1

.if .def(KEYBOARD)
KB_RPTR : .res 1                     ; keyboard buffer read pointer
KB_WPTR : .res 1                       ; keyboard buffer write pointer
.endif 


.if .def(TMS9918_VDP)
SCREEN_WIDTH : .res 1               ; Screen width
SCREEN_HEIGHT : .res 1               ; Screen height
CURSOR_L : .res 1                   ; low byte of cursor location in nametable in vram, passed to vdp
CURSOR_H : .res 1                    ; high byte of cursor location in nametable in vram, passed to vdp
CURSOR_X : .res 1                   ; x coord of cursor on the screen
CURSOR_Y : .res 1                    ; y coord of cursor on the screen
VDP_ADDR_L : .res 1                  ; low addr for accessing vdp
VDP_ADDR_H : .res 1                 ; high addr for accessing vdp

FONT_L = ZPR0                       ; Temporary during reset
FONT_H = ZPR1
FONT_END_L = ZPR2
FONT_END_H = ZPR3

COLOR_L = ZPR4
COLOR_H = ZPR5
COLOR_END_L = ZPR6 
COLOR_END_H = ZPR7 

PATTERN_ADDR_L = ZPR8 
PATTERN_ADDR_H = ZPR9 
.endif

.if .def(KEYBOARD)
KB_FLAG : .res 1   
.endif

STR_PTR : .res 2
STR_PTR1 : .res 2
STR_PTR2 : .res 2

CMD_PTR : .res 2
LOAD_PTR : .res 2

STACK2_PTR : .res 1

; Assembler stuff
MAP_RPTR : .res 2         



.segment "RAM"
STACK2 : .res 256                           ; Secondary stack
SER_BUF : .res 256                          ; serial signal buffer, 256 bytes
KB_BUF : .res 256                           ; keyboard input buffer, 256 bytes 
IN_BUF : .res 256                           ; Gerneral input buffer
SCROLL_BUF : .res 41                        ; buffer to store a line during scrolling , 41 bytes 
RET_STR : .res 213                          ; A buffer to store string returned by subroutines
ARG0_VAL : .res 4                           ; 32-bit argument buffer
ARG1_VAL : .res 4                           ; 32-bit argument buffer
RET_VAL : .res 4                            ; 32-bit value return 

; IO routine vectors
CHR_OUT_VEC : .res 2                        ; Scroll mode character out vector (default : PRINTC)
CTRL_CHR_OUT_VEC : .res 2                   ; Scroll mode control character out vector
STR_OUT_VEC : .res 2                        ; Scroll mode string out vector (default : PRINTS)
CHR_SET_VEC : .res 2                        ; Character set vector (default SETC)
CHR_IN_VEC : .res 2                        ; key in vector 

; Command routine vectors
CMD_ASM_VEC: .res 2
CMD_CARD_VEC: .res 2
CMD_CLR_VEC: .res 2
CMD_COL_VEC: .res 2
CMD_DUMP_VEC: .res 2
CMD_HELP_VEC: .res 2
CMD_INFO_VEC: .res 2
CMD_LOAD_VEC: .res 2
CMD_MON_VEC: .res 2
CMD_RST_VEC: .res 2
CMD_RUN_VEC: .res 2
CMD_SER_VEC: .res 2

; Interrupt routine vectors
ISR_VEC0 : .res 2
ISR_VEC1 : .res 2
ISR_VEC2 : .res 2
ISR_VEC3 : .res 2
ISR_VEC4 : .res 2
ISR_VEC5 : .res 2
ISR_VEC6 : .res 2
ISR_VEC7 : .res 2
ISR_VEC8 : .res 2
ISR_VEC9 : .res 2
ISR_VEC10 : .res 2
ISR_VEC11 : .res 2
ISR_VEC12 : .res 2
ISR_VEC13 : .res 2
ISR_VEC14 : .res 2
ISR_VEC15 : .res 2

; xmodem stuffs
LAST_LOAD_PTR : .res 2
LAST_BLK_NUM : .res 1

; assembler stuff
ASM_CUR_LINE : .res 2        ; Current editing line number 
ASM_MODE : .res 1            ; assembler mode
ASM_CMD_MODE := $01
ASM_ED_MODE  := $02
ASM_LIST_LINE : .res 2




RAM_START = $0800

SOURCE_START = $4000        ; Start of the assembler editor source




.segment "CODE"

.include "bios.s"
.include "font.s"
.include "map.s"

RESET:
    LDA #$1e           ; 8-N-1, 9600 baud.
    STA ACIA_CTRL
    LDA #$0B           ; No parity, no echo, no interrupts.
    STA ACIA_CMD
    lda #%11111111 ; Set all pins on port B to intput
    sta DDRB
    lda #%00000000 ; Set all pins on port A to input
    sta DDRA
    lda #%11001010
    sta PORTB
    lda #%11001100
    sta PORTB
    lda #$82
    sta IER         ; enable ca1 interrupt
    lda #$01
    sta PCR
    
    lda #$00
    sta CURSOR_L        ; reset cursor position
    sta CURSOR_H
    sta CURSOR_X
    sta CURSOR_Y
    
  

    ; pattern table starts at $0800
    lda #$00
    sta PATTERN_ADDR_L
    lda #$08
    sta PATTERN_ADDR_H
    
    lda #<font
    sta FONT_L
    lda #>font
    sta FONT_H
    
    lda #<font_end
    sta FONT_END_L
    lda #>font_end
    sta FONT_END_H

    lda #<color
    sta COLOR_L
    lda #>color
    sta COLOR_H
    lda #<color_end
    sta COLOR_END_L
    lda #>color_end
    sta COLOR_END_H

    lda #%00000000
    sta VDP_REG
    lda #VDP_REG0
    sta VDP_REG
    
    lda #%11000000
    sta VDP_REG
    lda #VDP_REG1
    sta VDP_REG
    
    lda #$00 								; name table starts at $0000
    sta VDP_REG
    lda #VDP_REG2
    sta VDP_REG
    
    lda #$0D                                ; color table starts at $0340
    sta VDP_REG
    lda #VDP_REG3
    sta VDP_REG
    
    lda #$01 								; pattern table starts at $0800
    sta VDP_REG
    lda #VDP_REG4
    sta VDP_REG
    
    lda #$00
    sta VDP_REG
    lda #VDP_REG5
    sta VDP_REG
    
    lda #$00
    sta VDP_REG
    lda #VDP_REG6
    sta VDP_REG
    
    lda #$F1 
    sta VDP_REG
    lda #VDP_REG7
    sta VDP_REG
    
    clc
    ldx #$0
copy_pattern:
    lda #$00
    sta VDP_REG
    lda #($08| $40)
    sta VDP_REG
    lda font
    sta VDP_RAM
    
    ldy #0
copy_pattern_loop:
    inc FONT_L
    bne continue_copy
    inc FONT_H
continue_copy:
    lda (FONT_L),y
    sta VDP_RAM
    
    lda FONT_H			;checks if its the end of the font 
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
    
    ldy #25
clean_loop:
    ldx #32
clean_loop1:
    lda #' '
    sta VDP_RAM
    dex
    bne clean_loop1
    dey
    bne clean_loop
    
    clc
    ldx #$0
copy_color:
    lda #$40				; low byte of color table
    sta VDP_REG
    lda #($03| $40)		; high byte of color table
    sta VDP_REG
    lda color				; the first byte in color table
    sta VDP_RAM

; copy color table 
    ldy #0
copy_color_loop:
    inc COLOR_L				; increments the position of the coordinates of color in ROM
    bne continue_copy_color
    inc COLOR_H
continue_copy_color:
    lda (COLOR_L),y 		    ; copies the byte to vdp ram
    sta VDP_RAM
    
    lda COLOR_H			;checks if its the end of the color
    cmp COLOR_END_H
    bne copy_color_loop
    lda COLOR_L
    cmp COLOR_END_L
    bne copy_color_loop
    

;initialize cursor positon
    lda CURSOR_L
    sta VDP_REG
    lda CURSOR_H
    ora #$40
    sta VDP_REG
    
    ldx #0
    lda #$00
    sta KB_RPTR
    sta KB_WPTR
    sta KB_FLAG

    lda #32 
    sta SCREEN_WIDTH
    lda #24 
    sta SCREEN_HEIGHT

    lda #<map
    sta MAP_RPTR
    lda #>map
    sta MAP_RPTR + 1

    ldy #0

start:
    jsr KBGETC
    bcc start 
    ldx #$A0
H_loop:
    lda (MAP_RPTR),Y 
    jsr VPRINTC
    iny 
    cpy #32
    bne H_loop

    jsr DELAY

    clc 
    lda MAP_RPTR
    adc #32
    sta MAP_RPTR
    lda MAP_RPTR + 1
    adc #0 
    sta MAP_RPTR + 1

    bit MAP_RPTR
    bvs skip
    dex 
skip:

    ldy #0
    lda MAP_RPTR
    cmp #<map_end
    bne H_loop
    lda MAP_RPTR + 1
    cmp #>map_end
    bne H_loop

    ldx #$FF
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY
    jsr DELAY

    lda #12
    sta CURSOR_X
    sta CURSOR_Y

    lda #<msg 
    sta STR_PTR
    lda #>msg 
    sta STR_PTR + 1
    jsr VPRINTS


halt:
    jmp halt

msg: .byte 09, "Backrooms"

DELAY:
    pha 
    tya 
    pha 
    txa 
    pha 
    tax 

delay_loop1:
    ldy #$AD
delay_loop2:
    dey 
    bne delay_loop2
    dex 
    bne delay_loop1

    pla 
    tax 
    pla 
    tay 
    pla 
    rts 

NMI:
    rti 

IRQ:
    pha
    txa
    pha
    lda KB_FLAG
    and #RELEASED       ; check if releaseing a key
    beq read_key        ; otherwise, read the key

    lda KB_FLAG
    eor #RELEASED           ; flip the releasing key
    sta KB_FLAG
    lda PORTA               ; read to clear the interrupt, read released key
    cmp #$12                ; left shift
    beq shift_up
    cmp #$59
    beq shift_up
    jmp exit
shift_up:
    lda KB_FLAG
    eor #SHIFT
    sta KB_FLAG
    jmp exit

read_key:
    lda PORTA           ; get scancode
    cmp #$F0            ; release?
    beq key_release
    cmp #$12            ; left shift ? 
    beq shift_down
    cmp #$59
    beq shift_down
    cmp #$5A
    beq enter_down

    tax
    lda KB_FLAG
    and #SHIFT
    bne shifted_key

    lda keymap, x 
    jmp push_key
enter_down:
    lda #$0D 
    jmp push_key
shifted_key:
    lda keymap_shifted, x

push_key:
    ldx KB_WPTR
    sta KB_BUF, x    ; put it in the buffer
    inc KB_WPTR
    jmp exit
shift_down:
    lda KB_FLAG
    ora #SHIFT          ; set shitf flag
    sta KB_FLAG
    jmp exit
key_release:
    lda KB_FLAG
    ora #RELEASED       ; set released flag
    sta KB_FLAG
exit:
    pla
    tax 
    pla
    rti 

keymap:
    .byte "????????????? `?" ; 00-0f
    .byte "?????q1???zsaw2?" ; 10-1f
    .byte "?cxde43?? vftr5?" ; 20-2f
    .byte "?nbhgy6???mju78?" ; 30-3f
    .byte "?,kio09??./l;p-?" ; 40-4f
    .byte "??'?[=?????]?\??" ; 50-5f
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

keymap_shifted:
    .byte "????????????? ~?" ; 00-0f
    .byte "?????Q!???ZSAW@?" ; 10-1f
    .byte "?CXDE$#?? VFTR%?" ; 20-2f
    .byte "?NBHGY^???MJU&*?" ; 30-3f
    .byte "?<KIO)(??>?L:P_?" ; 40-4f
    .byte "????{+?????}?|??" ; 50-5f
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



.segment "VECTOR"
.word NMI 
.word RESET
.word IRQ