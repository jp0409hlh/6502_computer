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





.segment "RAM"
STACK2 : .res 256                           ; Secondary stack
SER_BUF : .res 256                          ; serial signal buffer, 256 bytes
KB_BUF : .res 256                           ; keyboard input buffer, 256 bytes 
IN_BUF : .res 256                           ; Gerneral input buffer
SCROLL_BUF : .res 41                        ; buffer to store a line during scrolling , 41 bytes 

; IO routine vectors
CHR_OUT_VEC : .res 2                        ; Scroll mode character out vector (default : PRINTC)
STR_OUT_VEC : .res 2                        ; Scroll mode string out vector (default : PRINTS)
CHR_SET_VEC : .res 2                        ; Character set vector (default SETC)
CHAR_IN_VEC : .res 2                        ; key in vector 

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



RAM_START = $0800



