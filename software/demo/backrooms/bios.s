; VIDEO PRINT CHARACTER
; Usage : Write a character to VDP in scroll mode.
; How to use : Store the desired character to A.
; Modified flag : ?
; Modified registers : None
; Modified memory : CURSOR_X, CURSOR_Y, CURSOR_L, CURSOR_H 
.proc VPRINTC
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
.endproc 

; VIDEO PRINT CONTROL CHARACTER
; Usage : Write a control character to VDP in scroll mode.
; How to use : Store the desired character to A.
; Modified flag : ?
; Modified registers : None
; Modified memory : CURSOR_X, CURSOR_Y, CURSOR_L, CURSOR_H
.proc VPRINTCCTRL
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
    jmp exit
key_backspace:
    lda CURSOR_X                ; Is cursor X 0?
    beq cursor_on_left          ; Yes
    dec CURSOR_X                ; No, decrement cursor X as normal
    jmp exit
cursor_on_left:                 ; cursor on the left
    lda SCREEN_WIDTH
    sec
    sbc #1                      ; Cursor X go to right most side
    sta CURSOR_X                
    lda CURSOR_Y                ; is cursor on the top
    beq exit                    ; Yes, do nothing
    dec CURSOR_Y                ; No, decrement cursor y as normal
exit:
    pla 
    rts 
.endproc 




; VIDEO CHARACTER SET
; Usage : Output a character at the posisition defined by 
; cursor coordinate. This can be used for random access to vram
; name table
; How to use : Store the desired character to A, and the cursor xy coordinate
; to CURSOR_X and CURSOR_Y
; Modified flag : ?
; Modified registers : ?
; Modified memory : ?
.proc VCHRSET
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
.endproc 
 


; Tranlate cursor xy coordinate to nametable address
.proc xy_to_name_addr
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
    jmp exit        
screen_width_40:
    lda mul_by_40, x            ; Get mul40 result low byte 
    sta CURSOR_L                
    inx 
    lda mul_by_40, x            ; Get mul40 result high byte
    sta CURSOR_H
exit:                           ; Add cursor x to result
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
.endproc 



; Scroll up in scroll mode
.proc vdp_scroll_up
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
.endproc 


; Multiplication lookup table
mul_by_32:
    .word 0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, 480, 512, 544, 576, 608, 640, 672, 704, 736
mul_by_40:
    .word 0, 40, 80, 120, 160, 200, 240, 280, 320, 360, 400, 440, 480, 520, 560, 600, 640, 680, 720, 760, 800, 840, 880, 920
                      


; VIDEO PRINT STRING (pascal style)
; Usage : prints a string to vdp in scroll mode.
; how to use : store the pointer to STR_PTR and call this subroutine.
; Modified flag : ?
; Modified registers : none
; Modified memory : none
.proc VPRINTS
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
.endproc 




; KEYBOARD GET CHARACTER
; Usage : Get a character from keyboard, carry flag denotes a 
; keyboard hit.
; How to use : Call this subroutine and get the character in A.
; Modified flag : ?, C
; Modified register : A, ZP0
; Modified memory : ?
.proc KBGETC
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
.endproc 


; SERIAL SEND C
; Usage : Sends a character through serial.
; How to use : store the desired character to A.
; Modified flag : ?
; Modified registers : none
; Modified memory : none
.proc SSENDC
    .if .def(ACIA_BUG)
    pha 
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
.endproc

; SERIAL PRINT CHARACTER
; Usage : Sends a character through serial.
; ! Notice ! : All control characters will render as '.' .
; How to use : store the desired character to A.
; Modified flag : ?
; Modified registers : none
; Modified memory : none
.proc SPRINTC
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
.endproc 

; SERIAL PRINT STRING
; Usage : Prints a string through serial.
; How to use : Store the pointer to the string in STR_PTR and STR_PTR + 1
; and call this subroutine.
; Modified flag : ?
; Modified registers : none
; Modified memory : none
.proc SPRINTS
    rts
.endproc 

; SERIAL CHARACTER SET 
.proc SCHRSET
    rts 
.endproc 

; SERIAL GET CHARACTER
; Usage : get a character from SERIAL, carry flag denotes a 
; character sent.
; How to use : Call this subroutine and get the character in A.
; Modified flag : ?, C
; Modified register : A
; Modified memory : none
.proc SGETC
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
.endproc 