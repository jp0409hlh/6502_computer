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

; WRITE BYTE
; Descritption : Write a number of bytes from a buffer to the 
; file descriptor.
; Pass in :
;  | A : fd  |  X : count  |  ZPR0 : BUF_L  |  ZPR1 : BUF_H  |
; Return : 
;  | Y : ret |
WRITE:


; ********************************************************
; *              STANDARD INPUT OUTPUT                   *
; ********************************************************

; PRINT CHARACTER
; Usage : Write a character to VDP or serial (depends on the
; current hardware configuration).
; How to use : Store the desired character to A and call this
; subroutine.
; Modified flag : ?
; Modified registers : ?
; Modified memory : ?
PRINTC:

; PRINT STRING
; usage : prints a string to VDP or serial (depends on the current
; hardware configuration).
; how to use : store the pointer to the string in register (L->A, H->X)
; and call this subroutine.
; modified flag : ?
; modified registers : none
; modified memory : none
PRINTS:


; VIDEO PRINT CHARACTER
; Usage : Write a character to VDP
; How to use : Store the desired character to A and call this
; subroutine.
; Modified flag : ?
; Modified registers : ?
; Modified memory : ?
VPRINTC:
    pha                         ; push the character to stack
    cmp #$0D                    ; CR
    beq key_return
    cmp #$08                    ; back space
    beq key_backspace
    cmp #$0A                    ; line feed
    beq key_linefeed
    lda CURSOR_X
    cmp SCREEN_WIDTH            ; is cursor on the right
    bne not_next_line           ; no
    lda #$00                    ; yes, cursor go to left
    sta CURSOR_X
    inc CURSOR_Y                ; go to next line
    lda CURSOR_Y                
    cmp #24                     ; is cursor below the bottom
    bne no_scroll_up            ; no
    jsr scroll_up               ; yes, scroll up
not_next_line:
no_scroll_up:
VCHROUT:
    jsr xy_to_name_addr         ; convert xy coord to address in name table 
    lda CURSOR_L
    sta VDP_REG
    lda CURSOR_H
    ora #$40
    sta VDP_REG 
    pla
    sta VDP_RAM                 ; write to vram
    inc CURSOR_X                ; update cursor position for next time
    rts 

key_return:
    lda #$00                    ; cursor go to left
    sta CURSOR_X
    pla
    rts
key_backspace:
    lda CURSOR_X                ; is the cursor on the left
    beq cursor_on_left          ; yes
    dec CURSOR_X                ; no, decrement cursor x as normal
    pla
    rts
cursor_on_left:                 ; cursor on the left
    lda SCREEN_WIDTH
    sec
    sbc #1
    sta CURSOR_X                ; cursor x to the right
    lda CURSOR_Y                ; is cursor on the top
    beq exit_chrout              ; yes, do nothing
    dec CURSOR_Y                ; no, decrement cursor y as normal
    pla
    rts

key_linefeed:
    inc CURSOR_Y                ; increment cursor y
    lda CURSOR_Y
    cmp #24                     ; is cursor at the bottom
    bne exit_chrout             ; no, do nothing
    jsr scroll_up               ; yes, scroll up
exit_chrout:
    pla 
    rts


; tranlate cursor xy coordinate to nametable address
xy_to_name_addr:
    pha
    clc
    lda CURSOR_Y
    asl A
    tax
    lda SCREEN_WIDTH            ; multiply cursor y by screen width (32 or 40)
    cmp #40                     ; is screen width 40
    beq screen_width_40         ; yes
    lda mul_by_32, x            ; no, get mul result low byte 
    sta CURSOR_L                
    inx 
    lda mul_by_32, x            ; get mul result high byte
    sta CURSOR_H
    jmp y_mul_complete          ; 
screen_width_40:
    lda mul_by_40, x            ; no, get mul result low byte 
    sta CURSOR_L                
    inx 
    lda mul_by_40, x            ; get mul result high byte
    sta CURSOR_H
y_mul_complete:                 ; add cursor x to result
    clc
    lda CURSOR_L
    adc CURSOR_X
    sta CURSOR_L
    lda CURSOR_H
    adc #$00
    sta CURSOR_H
    pla
    rts


scroll_up:
    pha                         ; ? really need to save registers?
    txa 
    pha
    tya
    pha
    lda SCREEN_WIDTH
    sta VDP_ADDR_L
    lda #$00
    sta VDP_ADDR_H
    ldy #24                     ; loop index
line_loop:
    lda VDP_ADDR_L              ; set up VRAM address for reading
    sta VDP_REG
    lda VDP_ADDR_H
    ora #$40
    sta VDP_REG
    lda VDP_RAM                 ; dummy read
    ldx SCREEN_WIDTH            ; loop index
vram_to_buffer_loop:
    lda VDP_RAM
    sta SCROLL_BUF,X            ; store character into buffer
    dex
    bne vram_to_buffer_loop     ; Has read a whole line?
vdp_addr_goto_previous_line:
    sec
    lda VDP_ADDR_L              ; set vram address to the start of
    sbc SCREEN_WIDTH            ; the previous line
    sta VDP_ADDR_L
    lda VDP_ADDR_H
    sbc SCREEN_WIDTH
    sta VDP_ADDR_H
    lda VDP_ADDR_L
    sta VDP_REG
    lda VDP_ADDR_H
    ora #$40
    sta VDP_REG
    ldx SCREEN_WIDTH
buffer_to_vram_loop:            
    lda SCROLL_BUF,X 
    sta VDP_RAM
    dex
    bne buffer_to_vram_loop
vdp_addr_goto_next_two_lines:
    lda SCREEN_WIDTH
    lsr A                       ; take screen width and times 2
    clc
    adc VDP_ADDR_L              ; add to vram address
    sta VDP_ADDR_L
    lda VDP_ADDR_H
    adc #$00
    sta VDP_ADDR_H

    dey
    bne line_loop
    lda #23
    sta CURSOR_Y

    pla
    tay
    pla
    tax
    pla
    rts



                      


; VIDEO PRINT STRING
; usage : prints a string to vdp.
; how to use : store the pointer to the string in register (L->A, H->X)
; and call this subroutine.
; modified flag : ?
; modified registers : none
; modified memory : none
VPRINTS:
    tya                         ; save Y
    pha
    ldy #$00                    ; reset index Y
    sta STR_PTR                 ; store string pointer
    stx STR_PTR+1
@print_loop:
    lda (STR_PTR),y             ; get the Yth character of the string
    beq vprintc_done
    jsr VPRINTC
    iny
    jmp @print_loop
vprintc_done:
    pla
    tay
    rts 

; KEYBOARD GET CHARACTER
; usage : get a character from keyboard, carry flag denotes a 
; keyboard hit.
; how to use : call this subroutine and get the character in A.
; modified flag : ?, C
; modified register : A
; modified memory : none
KGETC:
    sec
    rts
@no_keypressed:
    clc
    rts

; KEYBOARD SCAN CHARACTER
; usage : loops until a key has been pressed
; how to use : call this subroutine and get the character in A.
; modified flag : ?
; modified register : A
; modified memory : none
KSCANC:
    rts

; KEYBOARD SCAN STRING (Really needs this ?, need Echo?)
; Usage : loops and stores keyboard input until CR
; how to use : call this subroutine and get the pointer to the string 
; in the registers (L->A, H->X), which is located in the input buffer.
; Modified flag : 
; Modified register : none
; Modified memory : IN_BUF and STR_PTR
KSCANS:
    rts




; SERIAL PRINT CHARACTER
; usage : prints a character to the terminal via serial
; how to use : store the desired character to A and call this
; subroutine.
; modified flag : 
; modified registers : none
; modified memory : none
SPRINTC:
    pha
    sta     ACIA_DATA
    lda     #$FF
@txdelay:       
	sbc     #$01
    bne     @txdelay
    pla
    rts 

; SERIAL PRINT STRING
; usage : prints a string to the terminal via serial.
; how to use : store the pointer to the string in register (L->A, H->X)
; and call this subroutine.
; modified flag : ?
; modified registers : none
; modified memory : none
SPRINTS:
    rts

; SERIAL GET CHARACTER
; usage : get a character from SERIAL, carry flag denotes a 
; keyboard hit.
; how to use : call this subroutine and get the character in A.
; modified flag : ?, C
; modified register : A
; modified memory : none
SGETC:
    lda ACIA_STATUS
    and #$08
    beq @no_keypressed
    lda ACIA_DATA
    sec
    rts
@no_keypressed:
    clc
    rts

; SERIAL SCAN CHARACTER
; usage : loops until a key has been pressed
; how to use : call this subroutine and get the character in A.
; modified flag : ?
; modified register : A
; modified memory : none
SSCANC:
    rts

; SERIAL SCAN STRING (Really need this? need Echo?)
; usage : loops and stores keyboard input until CR
; how to use : call this subroutine and get the address to the string
; in the registers (L->A, H->X). The string is located in the SER_BUF 
; buffer.
; modified flag : ?
; modified register : none
; modified memory : SER_BUF and STR_PTR
SSCANS:
    rts


; ********************************************************
; *                   STANDARD LIBRARY                   *
; ********************************************************

MALLOC:
    rts

FREE:
    rts

RAND:
    rts

FOPEN:
    rts

FCLOSE:
    rts


mul_by_32:
    .word 0, 32, 64, 96, 128
mul_by_40:

IRQ:
    rti 