.segment "KERNEL"

; ********************************************************
; *                     SYSTEM CALL                      *
; ********************************************************
; READ BYTE
; Description : Read a number of bytes from the file descriptor to
; a buffer. ZPR2 returns the first byte read.
; Pass in :
;  | A : fd  |  X : count  |  ZPR0 : BUF_L  |  ZPR1 : BUF_H  |
; Return : 
;  | Y : ret |  ZPR2 : byte  |
READ: 
    rts

; WRITE BYTE
; Descritption : Write a number of bytes from a buffer to the 
; file descriptor.
; Pass in :
;  | A : fd  |  X : count  |  ZPR0 : BUF_L  |  ZPR1 : BUF_H  |
; Return : 
;  | Y : ret |
WRITE:
    rts 


; ********************************************************
; *              STANDARD INPUT OUTPUT                   *
; ********************************************************

; PRINT CHARACTER
; Usage : Write a character to VDP or serial (depends on the
; current hardware configuration) in scroll mode.
; ! Notice ! : Control ascii characters wont do anything, e.g.
; printing LF wont cause line feed. In serial mode, all special
; characters will be replaced with '.' .
; How to use : Store the desired character to A.
; Modified flag : <depends on the vector>
; Modified registers : <depends on the vector>
; Modified memory : <depends on the vector>
PRINTC:
    jmp (CHR_OUT_VEC)

;PRINT CONTROL CHARACTER
; Usage : Write a control character to VDP or serial (depends on the
; current hardware configuration) in scroll mode.
; How to use : Store the desired character to A.
; Modified flag : <depends on the vector>
; Modified registers : <depends on the vector>
; Modified memory : <depends on the vector>
PRINTCCTRL:
    jmp (CTRL_CHR_OUT_VEC)

; PRINT STRING
; Usage : Prints a string to VDP or serial (depends on the current
; hardware configuration) in scroll mode.
; How to use : Store the pointer to the string in STR_PTR and STR_PTR+1.
; Modified flag : <depends on the vector>
; Modified registers : <depends on the vector>
; Modified memory : <depends on the vector>
PRINTS:
    jmp (STR_OUT_VEC)

; SET CHARACTER
; Usage : Set a character on the current cursor XY position but doesnt auto increment cursor X.
; How to use : Store the character in A and the position in CURSOR_X and CURSOR_Y.
; Modified flag : <depends on the vector>
; Modified registers : <depends on the vector>
; Modified memory : <depends on the vector>
SETC:
    jmp (CHR_SET_VEC)

; GET CHARACTER
; Usage : Gets a character.
; How to use : Call this subroutine and get the character from A.
; Modified flag : C, others depends on the vector
; Modified registers : A, others depends on the vector
; Modified memory : <depends on the vector>
GETC:
    jmp (CHAR_IN_VEC)


.if .def(TMS9918_VDP)
; VIDEO PRINT CHARACTER
; Usage : Write a character to VDP in scroll mode.
; How to use : Store the desired character to A.
; Modified flag : ?
; Modified registers : None
; Modified memory : CURSOR_X, CURSOR_Y, CURSOR_L, CURSOR_H 
VPRINTC:
    pha 
    lda CURSOR_X                ; Otherwise, start printing a character to screen
    cmp SCREEN_WIDTH            ; Has cursor X exceeded screen width?
    bne no_next_line            ; No
    lda #$00                    ; Yes, cursor X reset to 0
    sta CURSOR_X
    inc CURSOR_Y                ; Go to next line (Increment cursor Y)
    lda CURSOR_Y                
    cmp #24                     ; Has the cursor Y exceed screen height?
    bne no_scroll_up            ; No
    jsr vdp_scroll_up           ; Yes, scroll up
no_next_line:
no_scroll_up:
    pla 
    jsr VCHRSET
    inc CURSOR_X
    rts 

; VIDEO PRINT CONTROL CHARACTER
; Usage : Write a control character to VDP in scroll mode.
; How to use : Store the desired character to A.
; Modified flag : ?
; Modified registers : None
; Modified memory : CURSOR_X, CURSOR_Y, CURSOR_L, CURSOR_H
VPRINTCCTRL:
    pha 
    cmp #$0D                    ; Carriage return?
    beq key_return              ; Yes
    cmp #$08                    ; Backspace?
    beq key_backspace           ; Yes
    cmp #$0A                    ; Line feed?
    beq key_linefeed            ; Yes
key_linefeed:                   ; LF, automatically does CR too      
    inc CURSOR_Y                ; Increment cursor y               
    lda CURSOR_Y
    cmp #24                     ; Is cursor at the bottom
    bne key_return              ; No, do nothing
    jsr vdp_scroll_up           ; Yes, scroll up
key_return:                     ; CR
    lda #$00                    ; Cursor go to left
    sta CURSOR_X
    jmp exit_vprintc
key_backspace:
    lda CURSOR_X                ; Is cursor X 0?
    beq cursor_on_left          ; Yes
    dec CURSOR_X                ; No, decrement cursor X as normal
    jmp exit_vprintc
cursor_on_left:                 ; cursor on the left
    lda SCREEN_WIDTH
    sec
    sbc #1                      ; Cursor X go to right most side
    sta CURSOR_X                
    lda CURSOR_Y                ; is cursor on the top
    beq exit_vprintc            ; Yes, do nothing
    dec CURSOR_Y                ; No, decrement cursor y as normal
exit_vprintc:
    pla 
    rts 
.endif


.if .def(TMS9918_VDP)
; VIDEO CHARACTER SET
; Usage : Output a character at the posisition defined by 
; cursor coordinate. This can be used for random access to vram
; name table
; How to use : Store the desired character to A, and the cursor xy coordinate
; to CURSOR_X and CURSOR_Y
; Modified flag : ?
; Modified registers : ?
; Modified memory : ?
VCHRSET:
    pha 
    jsr xy_to_name_addr         ; Convert xy coord to address in name table 
    lda CURSOR_L                ; Setting up VRAM write address
    sta VDP_REG
    lda CURSOR_H
    ora #$40
    sta VDP_REG 
    pla
    sta VDP_RAM                 ; write to vram
    rts
.endif  

.if .def(TMS9918_VDP)
; Tranlate cursor xy coordinate to nametable address
xy_to_name_addr:
    pha
    txa
    pha 
    clc
    lda CURSOR_Y
    asl A                       
    tax                         ; X reg = cursor_y * 2
    lda SCREEN_WIDTH            ; Multiply cursor y by screen width (32 or 40)
    cmp #40                     ; Is screen width 40(text mode)?
    beq screen_width_40         ; Yes
    lda mul_by_32, x            ; Otherwise, get mul32 result low byte 
    sta CURSOR_L                
    inx 
    lda mul_by_32, x            ; Get mul32 result high byte
    sta CURSOR_H
    jmp exit_xy_to_name         
screen_width_40:
    lda mul_by_40, x            ; Get mul40 result low byte 
    sta CURSOR_L                
    inx 
    lda mul_by_40, x            ; Get mul40 result high byte
    sta CURSOR_H
exit_xy_to_name:                ; Add cursor x to result
    clc
    lda CURSOR_L
    adc CURSOR_X
    sta CURSOR_L
    lda CURSOR_H
    adc #$00
    sta CURSOR_H
    pla
    tax 
    pla 
    rts
.endif 

.if .def(TMS9918_VDP)
; Scroll up in scroll mode
vdp_scroll_up:
    pha                         
    txa 
    pha
    tya
    pha
    lda SCREEN_WIDTH
    sta VDP_ADDR_L
    lda #$00
    sta VDP_ADDR_H
    ldy #24                     ; Y loop index
line_loop:
    lda VDP_ADDR_L              ; set up VRAM address for reading
    sta VDP_REG
    lda VDP_ADDR_H
    ora #$40
    sta VDP_REG
    lda VDP_RAM                 ; Dummy read, discard
    ldx SCREEN_WIDTH            ; X loop index
vram_to_buffer_loop:            ; Stores a whole line of tiles to a buffer
    lda VDP_RAM
    sta SCROLL_BUF,X            ; Store character into buffer
    dex
    bne vram_to_buffer_loop     ; Has read a whole line?
vdp_addr_goto_previous_line:    ; Cursor go to the previous line
    sec
    lda VDP_ADDR_L              ; Set vram address to the start of the previous line
    sbc SCREEN_WIDTH            
    sta VDP_ADDR_L
    lda VDP_ADDR_H
    sbc #$00
    sta VDP_ADDR_H
    lda VDP_ADDR_L              ; Set up address for vram
    sta VDP_REG
    lda VDP_ADDR_H
    ora #$40
    sta VDP_REG

    ldx SCREEN_WIDTH
buffer_to_vram_loop:            ; Stores buffer tile data to vram       
    lda SCROLL_BUF,X 
    sta VDP_RAM
    dex
    bne buffer_to_vram_loop
vdp_addr_goto_next_two_lines:   ; Cursor go to next 2 line
    lda SCREEN_WIDTH
    clc                         ; Clear carry for rol (mul by 2) 
    rol A                       ; Take screen width and multiplies by 2
    clc
    adc VDP_ADDR_L              ; Add result to vram address
    sta VDP_ADDR_L
    lda VDP_ADDR_H
    adc #$00
    sta VDP_ADDR_H

    dey
    bne line_loop               ; Has looped through all 24 lines?
    lda #23                     ; Yes, cursor y = last line
    sta CURSOR_Y

    pla
    tay
    pla
    tax
    pla
    rts
.endif

; Multiplication lookup table
mul_by_32:
    .word 0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, 480, 512, 544, 576, 608, 640, 672, 704, 736
mul_by_40:
    .word 0, 40, 80, 120, 160, 200, 240, 280, 320, 360, 400, 440, 480, 520, 560, 600, 640, 680, 720, 760, 800, 840, 880, 920
                      

.if .def(TMS9918_VDP)
; VIDEO PRINT STRING (pascal style)
; Usage : prints a string to vdp in scroll mode.
; how to use : store the pointer to STR_PTR and call this subroutine.
; Modified flag : ?
; Modified registers : none
; Modified memory : none
VPRINTS:
    pha                         ; Save A
    txa                         ; Save X
    pha                         
    tya                         ; save Y
    pha

    ldy #0
    lda (STR_PTR), Y
    tax                         ; X now has the length of the string 
    ldy #1
@loop:
    lda (STR_PTR), Y
    jsr VPRINTC
    iny
    dex
    bne @loop

    pla
    tax 
    pla 
    tay
    pla 
    rts 
.endif


.if .def(KEYBOARD)
; KEYBOARD GET CHARACTER
; Usage : Get a character from keyboard, carry flag denotes a 
; keyboard hit.
; How to use : Call this subroutine and get the character in A.
; Modified flag : ?, C
; Modified register : A, ZP0
; Modified memory : ?
KBGETC:
    txa 
    pha 
    sei 
    lda KB_RPTR
    cmp KB_WPTR
    cli 
    bne @key_pressed
    pla
    tax 
    clc                         ; No key pressed, clear carry
    rts
@key_pressed:
    ldx KB_RPTR
    lda KB_BUF, X
    sta ZPR0
    inc KB_RPTR
    pla 
    tax 
    lda ZPR0
    sec                         ; key pressed, set carry
    rts
.endif

; SERIAL PRINT CHARACTER
; Usage : Sends a character through serial.
; ! Notice ! : All control characters will render as '.' .
; How to use : store the desired character to A.
; Modified flag : ?
; Modified registers : none
; Modified memory : none
SPRINTC:
.if .def(ACIA_BUG)
    pha
    cmp #$20
    bcs not_ctrl_char
    lda #'.'
not_ctrl_char:
    sta ACIA_DATA
    lda #$FF
@txdelay:       
	sbc #$01
    bne @txdelay
    pla
.else  
    sta ACIA_DATA 
.endif
    rts 

; SERIAL PRINT STRING
; Usage : Prints a string through serial.
; How to use : Store the pointer to the string in STR_PTR and STR_PTR + 1
; and call this subroutine.
; Modified flag : ?
; Modified registers : none
; Modified memory : none
SPRINTS:
    rts

; SERIAL CHARACTER SET 
SCHRSET:
    rts 

; SERIAL GET CHARACTER
; Usage : get a character from SERIAL, carry flag denotes a 
; character sent.
; How to use : Call this subroutine and get the character in A.
; Modified flag : ?, C
; Modified register : A
; Modified memory : none
SGETC:
    txa 
    pha 
    sei 
    lda SER_RPTR
    cmp SER_WPTR
    bne @key_pressed
    pla
    tax 
    clc                         ; No key pressed, clear carry
    cli 
    rts
@key_pressed:
    ldx SER_RPTR
    lda SER_BUF, X
    sta ZPR0
    inc SER_RPTR
    pla 
    tax 
    lda ZPR0
    sec                         ; key pressed, set carry
    cli 
    rts


; ********************************************************
; *                   STANDARD LIBRARY                   *
; ********************************************************
; --------------------
; -      MEMORY      -
; --------------------
; MEMORY ALLOCATION
; Usage: Allocates memory
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
MALLOC:
    rts

; FREE MEMORY
; Usage: Frees memory
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
FREE:
    rts

; RANDOM
; Usage: Returns a random number
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
RAND:
    rts

; --------------------
; -      MATH        -
; --------------------
; INT32 ADDITION
; Usage: 32-bit integer addition
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
INT32_ADD:
    rts

; INT32 SUBTRACTION
; Usage: 32-bit integer subtraction
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
INT32_SUB:
    rts

; IN32 MULTIPLICATION
; Usage: 32-bit integer multiplication
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
INT32_MUL:
    rts 

; INT32 DIVISION
; Usage: 32-bit integer division
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
INT32_DIV:
    rts 

; FLOAT ADDITION
; Usage: Float addition
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
FLOAT_ADD:
    rts

; FLOAT SUBTRACTION
; Usage: Float subtraction
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
FLOAT_SUB:
    rts

; FLOAT MULTIPLICATION
; Usage: Float multiplication
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
FLOAT_MUL:
    rts 

; FLOAT DIVISION
; Usage: Float division
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
FLOAT_DIV:
    rts 

; INT32 TO FLOAT CONVERSION
; Usage: 32-bit integer to float
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
INT32_TO_FLOAT:
    rts 

; FLOAT TO INT32 CONVERSION
; Usage: Float to 32-bit integer
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
FLOAT_TO_INT32:
    rts 

; SQUARE ROOT
; Usage: Takes square root of a float
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
SQRT:
    rts 

; POWER
; Usage: Raises a float to the power of a byte
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
POW:
    rts 


; --------------------
; -      STRING      -
; --------------------

; STRING COMPARE CASE SENSITIVE
; Usage: Compares two strings (case sensitive)
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
STR_CMP_CS:
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

; STRING COMPARE CASE NON-SENSITIVE
; Usage: Compares two strings (case not sensitive)
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
STR_CMP_CNS:
    rts

; STRING COPY
; Usage: Copys a string to another location
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
STR_CPY:
    rts 

; STRING TO INT
; Usage: Converts string to integer
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
ATOI:
    rts 

; INT TO STRING
; Usage: Converts integer to string 
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
ITOA:
    rts 

; STRING TO FLOAT
; Usage: Converts string to float
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
ATOF:
    rts

; FLOAT TO STRING
; Usage: Converts float to integer
; How to use:
; Modified flag :
; Modified register : 
; Modifies memory : 
FTOA:
    rts

; ********************************************************
; *           DEFAULT INTERRUPT SERVICE ROUTINE          *
; ******************************************************** 

.if .def(KEYBOARD)
; KEYBOARD INTERRUPT SERVICE ROUTINE (Not to be confused with KBGETC)
; Usage: Puts the key into KB_BUF
; Modified flag : None
; Modified register : None
; Modifies memory : KB_BUF, KB_FLAG, KB_RPTR, KB_WPTR
KB_ISR:
    pha 
    txa 
    pha 

    lda IFR 
    and #IFR_CA1                ; Did CA1(keyboard) cause the interrupt?
    beq exit_kbisr              ; No, exits.
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
    jmp exit_kbisr              ; Otherwise, ignores released key

shift_up:                       ; Shift key is released. Flips the shift flag
    lda KB_FLAG
    eor #SHIFT
    sta KB_FLAG
    jmp exit_kbisr

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
    jmp exit_kbisr

shift_down:                     ; Shift is pressed
    lda KB_FLAG
    ora #SHIFT                  ; set shift flag
    sta KB_FLAG
    jmp exit_kbisr

key_release:                    ; Key is released
    lda KB_FLAG
    ora #RELEASED               ; set released flag
    sta KB_FLAG
exit_kbisr:
    pla 
    tax 
    pla 
    rts 

keymap:
    .byte "????????????? `?" ; 00-0f
    .byte "?????q1???zsaw2?" ; 10-1f
    .byte "?cxde43?? vftr5?" ; 20-2f
    .byte "?nbhgy6???mju78?" ; 30-3f
    .byte "?,kio09??./l;p-?" ; 40-4f
    .byte "??'?[=????", $0A ,"]?\??" ; 50-5f
    .byte "??????",$08,"??1?47???" ; 60-6f
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
SER_ISR:
    pha
    txa 
    pha 

    lda ACIA_STATUS
    and #ACIA_STAT_INT                  ; ACIA caused the interrupt?
    beq exit_serisr                     ; No, skips
    lda ACIA_DATA
    ldx SER_WPTR
    sta SER_BUF, X
    inc SER_WPTR

exit_serisr:
    pla 
    tax
    pla 
    rts 

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
.segment "VECTOR"
    .word NMI
    .word RESET
    .word IRQ