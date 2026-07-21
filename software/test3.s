VDP_RAM = $A000
VDP_REG = $A001

REG0 = $80 								; m3 and exvdp
REG1 = $81 								; vdp options
REG2 = $82 								; name table base address, 4 bits, 
REG3 = $83 								; color table base address, 8 bits, 
REG4 = $84 								;pattern generator base address, 3 bits, 
REG5 = $85 								; sprite attribute table base address, 7 bits
REG6 = $86 								; sprite pattern generator base adderss, 3 bits
REG7 = $87 								; text code color, 4+4


PATTERN_ADDR_L = $0032
PATTERN_ADDR_H = $0033



; zero page
FONT_L = $34
FONT_H = $35
FONT_END_L = $36
FONT_END_H = $37

CURSOR_POS_L = $0038
CURSOR_POS_H = $0039

CURSOR_POS_X = $003A
CURSOR_POS_Y = $003B

VDP_READ_L = $003C
VDP_READ_H = $003D

LINE_BUFFER_PTR = $003E ;two byte, little endian
LINE_BUFFER = $0040 ; 41 bytes


XAML  = $24                            ; Last "opened" location Low
XAMH  = $25                            ; Last "opened" location High
STL   = $26                            ; Store address Low
STH   = $27                            ; Store address High
L     = $28                            ; Hex value parsing Low
H     = $29                            ; Hex value parsing High
YSAV  = $2A                            ; Used to see if hex value is given
MODE  = $2B                            ; $00=XAM, $7F=STOR, $AE=BLOCK XAM

kb_buffer   = $0200                          ; Input buffer
kb_wptr     = $0300
kb_rptr     = $0301
kb_flags    = $0302
RELEASED    = %00000001
SHIFT       = %00000010

ACIA_DATA   = $8600
ACIA_STATUS = $8601
ACIA_CMD    = $8602
ACIA_CTRL   = $8603

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


 .org $8000
 .org $c000
 
reset:
    sei
    lda #%11111111 ; Set all pins on port B to output
    sta DDRB
    lda #%00000000 ; Set all pins on port A to input
    sta DDRA
    lda #$82
    sta IER         ; enable ca1 interrupt
    lda #$01
    sta PCR
 
 lda #$00
 sta CURSOR_POS_L        ; reset cursor position
 sta CURSOR_POS_H
 sta CURSOR_POS_X
 sta CURSOR_POS_Y
 
 lda #$40
 sta LINE_BUFFER_PTR     ; pointer lowbyte
 lda #$00
 sta LINE_BUFFER_PTR + 1 ; pointer highbyte
 

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

 lda #%00000000
 sta VDP_REG
 lda #REG0
 sta VDP_REG
 
 lda #%11010000
 sta VDP_REG
 lda #REG1
 sta VDP_REG
 
 lda #$00 								; name table starts at $0000
 sta VDP_REG
 lda #REG2
 sta VDP_REG
 
 lda #$00
 sta VDP_REG
 lda #REG3
 sta VDP_REG
 
 lda #$01 								; pattern table starts at $0800
 sta VDP_REG
 lda #REG4
 sta VDP_REG
 
 lda #$00
 sta VDP_REG
 lda #REG5
 sta VDP_REG
 
 lda #$00
 sta VDP_REG
 lda #REG6
 sta VDP_REG
 
 lda #$F1 
 sta VDP_REG
 lda #REG7
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
 ldx #40
clean_loop1:
 lda #" "
 sta VDP_RAM
 dex
 bne clean_loop1
 dey
 bne clean_loop
 
 
;initialize cursor positon
 lda CURSOR_POS_L
 sta VDP_REG
 lda CURSOR_POS_H
 ora #$40
 sta VDP_REG
 ldx #0
 cli 



    lda #%10101010
    sta PORTB

    lda #$00
    sta kb_rptr
    sta kb_wptr
    sta kb_flags
    tax 
    tay 

main_loop:
    sei
    lda kb_rptr
    cmp kb_wptr
    cli 
    bne key_pressed
    jmp main_loop

key_pressed:
    ldx kb_rptr
    lda kb_buffer, x 
    jsr ECHO
    inc kb_rptr
    jmp main_loop

message: .asciiz "Hello world"

ECHO:
 PHA
 cmp #$0D
 beq return
 cmp #$08
 beq back_space
 jmp ECHO_1
return:
 inc CURSOR_POS_Y
 lda #$00
 sta CURSOR_POS_X
 
 lda CURSOR_POS_Y
 cmp #24
 bne return_complete
 jsr scroll
return_complete:
 pla 
 jmp ECHO_ACIA

back_space:
 lda CURSOR_POS_X
 beq last_line
 dec CURSOR_POS_X 
 pla
 jmp ECHO_ACIA
last_line:
 lda #39
 sta CURSOR_POS_X
 dec CURSOR_POS_Y
 pla
 jmp ECHO_ACIA
 
ECHO_1: 
 lda CURSOR_POS_Y
 cmp #24
 bne no_scroll
 jsr scroll
no_scroll:
; set address for this character
 jsr xy_to_name
 
 lda CURSOR_POS_L
 sta VDP_REG
 lda CURSOR_POS_H
 ora #$40
 sta VDP_REG
 
; increment for the next character
 inc CURSOR_POS_X
 lda CURSOR_POS_X
 cmp #40
 bne not_next_line
 lda #$00
 STA CURSOR_POS_X
 inc CURSOR_POS_Y
 
not_next_line:
 nop
 
ECHO_BOTH:
 PLA
 sta VDP_RAM
 
 
ECHO_ACIA:
 STA ACIA_DATA      ; Output character.
 pha 

 LDA #$FF           ; Initialize delay loop.
TXDELAY:        
 SBC #$01           ; Decrement A.
 BNE TXDELAY        ; Until X gets to 0.  
 pla
 rts
 
xy_to_name:
 pha
 clc
 lda #$00
 sta CURSOR_POS_H
 
 lda CURSOR_POS_Y	;40*y + x
 ASL A
 ASL A
 ASL A
 sta CURSOR_POS_L
 ASL A
 ROL CURSOR_POS_H
 ASL A
 ROL CURSOR_POS_H
 clc
 adc CURSOR_POS_L
 sta CURSOR_POS_L
 lda CURSOR_POS_H
 adc #$00
 sta CURSOR_POS_H
 
 clc
 lda CURSOR_POS_L
 adc CURSOR_POS_X
 sta CURSOR_POS_L
 lda CURSOR_POS_H
 adc #$00
 sta CURSOR_POS_H
 pla 
 rts
 
scroll:
 PHA
 txa
 PHA
 tya
 PHA
 ; initialize first position, which is $0028 on the name table
 lda #40
 sta VDP_READ_L
 lda #$00
 sta VDP_READ_H
 
 ldy #24
line_loop:
 lda VDP_READ_L			; vdp_read base address set
 sta VDP_REG
 lda VDP_READ_H
 ora #$40
 sta VDP_REG
 
 lda VDP_RAM			; first read discard (dummy read)
 
 ldx #40
vram_to_buffer_loop:
 lda VDP_RAM
 sta LINE_BUFFER,x 
 dex 
 bne vram_to_buffer_loop
 
vdp_read_minus_forty:
 sec
 lda VDP_READ_L
 sbc #40
 sta VDP_READ_L
 lda VDP_READ_H
 sbc #$00
 sta VDP_READ_H
 
 lda VDP_READ_L			; vdp_read base address set in order to write
 sta VDP_REG
 lda VDP_READ_H
 ora #$40
 sta VDP_REG
 
 ldx #40
buffer_to_vram_loop:
 lda LINE_BUFFER,x 
 sta VDP_RAM
 dex
 bne buffer_to_vram_loop
 
vdp_read_add_eighty:
 clc
 lda VDP_READ_L
 adc #80
 sta VDP_READ_L
 lda VDP_READ_H
 adc #$00
 sta VDP_READ_H
 
 dey
 bne line_loop
 
 lda #23
 sta CURSOR_POS_Y

 PLA
 tay
 PLA
 TAX
 PLA
 rts
 
 
 
font:
 ; line drawing
  .byte $20,$50,$88,$88,$F8,$88,$88,$00 ; lr
  .byte $18,$18,$18,$18,$18,$18,$18,$18 ; ud
  .byte $00,$00,$00,$F8,$F8,$18,$18,$18 ; ld
  .byte $00,$00,$00,$1F,$1F,$18,$18,$18 ; rd
  .byte $18,$18,$18,$F8,$F8,$00,$00,$00 ; lu
  .byte $18,$18,$18,$1F,$1F,$00,$00,$00 ; ur
  .byte $18,$18,$18,$FF,$FF,$18,$18,$18 ; lurd
; <nonsense for debug>
  .byte $07,$07,$07,$07,$07,$07,$07,$00 ; 07
  .byte $00,$10,$20,$60,$FC,$60,$20,$10 ; 08, backspace
  .byte $09,$09,$09,$09,$09,$09,$09,$00 ; 09
  .byte $0A,$0A,$0A,$0A,$0A,$0A,$0A,$00 ; 0A
  .byte $0B,$0B,$0B,$0B,$0B,$0B,$0B,$00 ; 0B
  .byte $0C,$0C,$0C,$0C,$0C,$0C,$0C,$00 ; 0C
  .byte $E0,$80,$80,$E0,$38,$28,$30,$28 ; 0D, CR
  .byte $0E,$0E,$0E,$0E,$0E,$0E,$0E,$00 ; 0E
  .byte $0F,$0F,$0F,$0F,$0F,$0F,$0F,$00 ; 0F
  .byte $10,$10,$10,$10,$10,$10,$10,$00 ; 10
  .byte $11,$11,$11,$11,$11,$11,$11,$00 ; 11
  .byte $12,$12,$12,$12,$12,$12,$12,$00 ; 12
  .byte $13,$13,$13,$13,$13,$13,$13,$00 ; 13
  .byte $14,$14,$14,$14,$14,$14,$14,$00 ; 14
  .byte $15,$15,$15,$15,$15,$15,$15,$00 ; 15
  .byte $16,$16,$16,$16,$16,$16,$16,$00 ; 16
  .byte $17,$17,$17,$17,$17,$17,$17,$00 ; 17
  .byte $18,$18,$18,$18,$18,$18,$18,$00 ; 18
  .byte $19,$19,$19,$19,$19,$19,$19,$00 ; 19
  .byte $1A,$1A,$1A,$1A,$1A,$1A,$1A,$00 ; 1A
  .byte $1B,$1B,$1B,$1B,$1B,$1B,$1B,$00 ; 1B
  .byte $1C,$1C,$1C,$1C,$1C,$1C,$1C,$00 ; 1C
  .byte $1D,$1D,$1D,$1D,$1D,$1D,$1D,$00 ; 1D
  .byte $1E,$1E,$1E,$1E,$1E,$1E,$1E,$00 ; 1E
  .byte $1F,$1F,$1F,$1F,$1F,$1F,$1F,$00 ; 1F
; </nonsense>
  .byte $00,$00,$00,$00,$00,$00,$00,$00 ; ' '
  .byte $20,$20,$20,$00,$20,$20,$00,$00 ; !
  .byte $50,$50,$50,$00,$00,$00,$00,$00 ; "
  .byte $50,$50,$F8,$50,$F8,$50,$50,$00 ; #
  .byte $20,$78,$A0,$70,$28,$F0,$20,$00 ; $
  .byte $C0,$C8,$10,$20,$40,$98,$18,$00 ; %
  .byte $40,$A0,$A0,$40,$A8,$90,$68,$00 ; &
  .byte $20,$20,$40,$00,$00,$00,$00,$00 ; '
  .byte $20,$40,$80,$80,$80,$40,$20,$00 ; (
  .byte $20,$10,$08,$08,$08,$10,$20,$00 ; )
  .byte $20,$A8,$70,$20,$70,$A8,$20,$00 ; *
  .byte $00,$20,$20,$F8,$20,$20,$00,$00 ; +
  .byte $00,$00,$00,$00,$20,$20,$40,$00 ; ,
  .byte $00,$00,$00,$F8,$00,$00,$00,$00 ; -
  .byte $00,$00,$00,$00,$20,$20,$00,$00 ; .
  .byte $00,$08,$10,$20,$40,$80,$00,$00 ; /
  .byte $70,$88,$98,$A8,$C8,$88,$70,$00 ; 0
  .byte $20,$60,$20,$20,$20,$20,$70,$00 ; 1
  .byte $70,$88,$08,$30,$40,$80,$F8,$00 ; 2
  .byte $F8,$08,$10,$30,$08,$88,$70,$00 ; 3
  .byte $10,$30,$50,$90,$F8,$10,$10,$00 ; 4
  .byte $F8,$80,$F0,$08,$08,$88,$70,$00 ; 5
  .byte $38,$40,$80,$F0,$88,$88,$70,$00 ; 6
  .byte $F8,$08,$10,$20,$40,$40,$40,$00 ; 7
  .byte $70,$88,$88,$70,$88,$88,$70,$00 ; 8
  .byte $70,$88,$88,$78,$08,$10,$E0,$00 ; 9
  .byte $00,$00,$20,$00,$20,$00,$00,$00 ; :
  .byte $00,$00,$20,$00,$20,$20,$40,$00 ; ;
  .byte $10,$20,$40,$80,$40,$20,$10,$00 ; <
  .byte $00,$00,$F8,$00,$F8,$00,$00,$00 ; =
  .byte $40,$20,$10,$08,$10,$20,$40,$00 ; >
  .byte $70,$88,$10,$20,$20,$00,$20,$00 ; ?
  .byte $70,$88,$A8,$B8,$B0,$80,$78,$00 ; @
  .byte $20,$50,$88,$88,$F8,$88,$88,$00 ; A
  .byte $F0,$88,$88,$F0,$88,$88,$F0,$00 ; B
  .byte $70,$88,$80,$80,$80,$88,$70,$00 ; C
  .byte $F0,$88,$88,$88,$88,$88,$F0,$00 ; D
  .byte $F8,$80,$80,$F0,$80,$80,$F8,$00 ; E
  .byte $F8,$80,$80,$F0,$80,$80,$80,$00 ; F
  .byte $78,$80,$80,$80,$98,$88,$78,$00 ; G
  .byte $88,$88,$88,$F8,$88,$88,$88,$00 ; H
  .byte $70,$20,$20,$20,$20,$20,$70,$00 ; I
  .byte $08,$08,$08,$08,$08,$88,$70,$00 ; J
  .byte $88,$90,$A0,$C0,$A0,$90,$88,$00 ; K
  .byte $80,$80,$80,$80,$80,$80,$F8,$00 ; L
  .byte $88,$D8,$A8,$A8,$88,$88,$88,$00 ; M
  .byte $88,$88,$C8,$A8,$98,$88,$88,$00 ; N
  .byte $70,$88,$88,$88,$88,$88,$70,$00 ; O
  .byte $F0,$88,$88,$F0,$80,$80,$80,$00 ; P
  .byte $70,$88,$88,$88,$A8,$90,$68,$00 ; Q
  .byte $F0,$88,$88,$F0,$A0,$90,$88,$00 ; R
  .byte $70,$88,$80,$70,$08,$88,$70,$00 ; S
  .byte $F8,$20,$20,$20,$20,$20,$20,$00 ; T
  .byte $88,$88,$88,$88,$88,$88,$70,$00 ; U
  .byte $88,$88,$88,$88,$50,$50,$20,$00 ; V
  .byte $88,$88,$88,$A8,$A8,$D8,$88,$00 ; W
  .byte $88,$88,$50,$20,$50,$88,$88,$00 ; X
  .byte $88,$88,$50,$20,$20,$20,$20,$00 ; Y
  .byte $F8,$08,$10,$20,$40,$80,$F8,$00 ; Z
  .byte $F8,$C0,$C0,$C0,$C0,$C0,$F8,$00 ; [
  .byte $00,$80,$40,$20,$10,$08,$00,$00 ; \
  .byte $F8,$18,$18,$18,$18,$18,$F8,$00 ; ]
  .byte $00,$00,$20,$50,$88,$00,$00,$00 ; ^
  .byte $00,$00,$00,$00,$00,$00,$F8,$00 ; _
  .byte $40,$20,$10,$00,$00,$00,$00,$00 ; `
  .byte $00,$00,$70,$88,$88,$98,$68,$00 ; a
  .byte $80,$80,$F0,$88,$88,$88,$F0,$00 ; b
  .byte $00,$00,$78,$80,$80,$80,$78,$00 ; c
  .byte $08,$08,$78,$88,$88,$88,$78,$00 ; d
  .byte $00,$00,$70,$88,$F8,$80,$78,$00 ; e
  .byte $30,$40,$E0,$40,$40,$40,$40,$00 ; f
  .byte $00,$00,$70,$88,$F8,$08,$F0,$00 ; g
  .byte $80,$80,$F0,$88,$88,$88,$88,$00 ; h
  .byte $00,$40,$00,$40,$40,$40,$40,$00 ; i
  .byte $00,$20,$00,$20,$20,$A0,$60,$00 ; j
  .byte $00,$80,$80,$A0,$C0,$A0,$90,$00 ; k
  .byte $C0,$40,$40,$40,$40,$40,$60,$00 ; l
  .byte $00,$00,$D8,$A8,$A8,$A8,$A8,$00 ; m
  .byte $00,$00,$F0,$88,$88,$88,$88,$00 ; n
  .byte $00,$00,$70,$88,$88,$88,$70,$00 ; o
  .byte $00,$00,$70,$88,$F0,$80,$80,$00 ; p
  .byte $00,$00,$F0,$88,$78,$08,$08,$00 ; q
  .byte $00,$00,$70,$88,$80,$80,$80,$00 ; r
  .byte $00,$00,$78,$80,$70,$08,$F0,$00 ; s
  .byte $40,$40,$F0,$40,$40,$40,$30,$00 ; t
  .byte $00,$00,$88,$88,$88,$88,$78,$00 ; u
  .byte $00,$00,$88,$88,$90,$A0,$40,$00 ; v
  .byte $00,$00,$88,$88,$88,$A8,$D8,$00 ; w
  .byte $00,$00,$88,$50,$20,$50,$88,$00 ; x
  .byte $00,$00,$88,$88,$78,$08,$F0,$00 ; y
  .byte $00,$00,$F8,$10,$20,$40,$F8,$00 ; z
  .byte $38,$40,$20,$C0,$20,$40,$38,$00 ; {
  .byte $40,$40,$40,$00,$40,$40,$40,$00 ; |
  .byte $E0,$10,$20,$18,$20,$10,$E0,$00 ; }
  .byte $40,$A8,$10,$00,$00,$00,$00,$00 ; ~
  .byte $A8,$50,$A8,$50,$A8,$50,$A8,$00 ; checkerboard
font_end:
  .byte $FF

nmi:
    rti 
irq:
    pha
    txa
    pha
    lda kb_flags
    and #RELEASED       ; check if releaseing a key
    beq read_key        ; otherwise, read the key

    lda kb_flags
    eor #RELEASED           ; flip the releasing key
    sta kb_flags
    lda PORTA               ; read to clear the interrupt, read released key
    cmp #$12                ; left shift
    beq shift_up
    cmp #$59
    beq shift_up
    jmp exit
shift_up:
    lda kb_flags
    eor #SHIFT
    sta kb_flags
    jmp exit

read_key:
    lda PORTA           ; get scancode
    cmp #$F0            ; release?
    beq key_release
    cmp #$12            ; left shift ? 
    beq shift_down
    cmp #$59
    beq shift_down

    tax
    lda kb_flags
    and #SHIFT
    bne shifted_key

    lda keymap, x 
    jmp push_key

shifted_key:
    lda keymap_shifted, x

push_key:
    ldx kb_wptr
    sta kb_buffer, x    ; put it in the buffer
    inc kb_wptr
    jmp exit
shift_down:
    lda kb_flags
    ora #SHIFT          ; set shitf flag
    sta kb_flags
    jmp exit
key_release:
    lda kb_flags
    ora #RELEASED       ; set released flag
    sta kb_flags
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
    .byte '??"?{+?????}?|??' ; 50-5f
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

 .org $fffa
 .word nmi
 .word reset
 .word irq

 
 