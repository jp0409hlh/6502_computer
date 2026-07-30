.proc CMD_CLR
        lda #$00
        sta VDP_REG
        lda #($00 | $40)
        sta VDP_REG
        ldy #25
loop:
        ldx SCREEN_WIDTH
loop1:
        lda #' '                        ; Space
        sta VDP_RAM
        dex
        bne loop1
        dey
        bne loop
 
        lda #$00
        sta CURSOR_X
        sta CURSOR_Y
        lda #$00
        sta VDP_REG
        lda #$00
        ora #$40
        sta VDP_REG
        jmp input_process_done
.endproc