;***********************************************************
;*          IO and peripheral memory location              *
;***********************************************************
; VDP
VDP_RAM = $A000
VDP_REG = $A001

; VDP register select
VDP_REG0 = $80
VDP_REG1 = $81
VDP_REG2 = $82
VDP_REG3 = $83
VDP_REG4 = $84
VDP_REG5 = $85
VDP_REG6 = $86
VDP_REG7 = $87

; ACIA
ACIA_DATA = $8600
ACIA_STATUS = $8601
ACIA_CMD = $8602
ACIA_CTRL = $8203

; VIA
PORTB = $8200
PORTA = $8201
DDRB = $8202
DDRA = $8203
T1CL = $8204
T1CH = $8205
ACR = $8206
IFR = $8207
IER = $8208


;***********************************************************
;*                 RAM memory location                     *
;***********************************************************
; general purpose registors
ZPR0 = $0000
ZPR1 = $0001
ZPR2 = $0002
ZPR3 = $0003
ZPR4 = $0004
ZPR5 = $0005
ZPR6 = $0006
ZPR7 = $0007
ZPR8 = $0008
ZPR9 = $0009
ZPR10 = $000a
ZPR11 = $000b
ZPR12 = $000c
ZPR13 = $000d
ZPR14 = $000e
ZPR15 = $000f

; variable in ram   (move to zero page?)
SER_BUF = $0200                     ; serial signal buffer, 256 bytes
IN_BUF = $0300                      ; keyboard input buffer, 256 bytes 
SCROLL_BUF = $0400                  ; buffer to store a line, 41 byte 
SCREEN_WIDTH = $042A                ; 40 for text mode and 32 for other mode
CURSOR_L = $042B                    ; low byte of cursor location in nametable in vram, passed to vdp
CURSOR_H = $042C                    ; high byte of cursor location in nametable in vram, passed to vdp
CURSOR_X = $042D                    ; x coord of cursor on the screen
CURSOR_Y = $042E                    ; y coord of cursor on the screen
VDP_ADDR_L = $042F                  ; low addr for accessing vdp
VDP_ADDR_H = $0430                  ; high addr for accessing vdp



