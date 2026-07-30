; ASSEMBLER
; Built-in assembler and disassembler
.proc CMD_ASM
        lda ASM_MODE
        bne asm_entry
asm_init:
        tay 
        tax 
        lda #<SOURCE_START
        sta ASM_SRC_PTR
        lda #>SOURCE_START
        sta ASM_SRC_PTR + 1
@loop:                                  ; Setting up the dummy byte
        lda #$00
        sta (ASM_SRC_PTR,X)
        iny
        inc16 ASM_SRC_PTR
        cpy #24
        bne @loop

asm_entry:
        putctrlchar #$0A
        lda #ASM_CMD_MODE                ; Enter command mode
        sta ASM_MODE
main_loop:
        lda ASM_MODE
        cmp #ASM_ED_MODE                ; Is in edit mode?
        beq edit_mode
        putchar #'/'                    ; '/' prompt
        jmp cmd_input_start
edit_mode:
        lda ASM_CUR_LINE
        sta ARG0_VAL
        lda ASM_CUR_LINE + 1
        sta ARG0_VAL + 1
        jsr HTOA                        ; Convert current line number into string

        lda RET_STR + 5
        jsr PRINTC
        lda RET_STR + 6
        jsr PRINTC
        lda RET_STR + 7
        jsr PRINTC
        lda RET_STR + 8
        jsr PRINTC
        putchar #':'

cmd_input_start:
        lda #'_'
        jsr SETC
        lda #$00
        sta KB_RPTR                     ; Reset keyin read write pointer
        sta KB_WPTR
        sta READ_PTR
        sta READ_END_PTR

cmd_input_loop:
        jsr GETC                        ; Get character. Carry set if new key, otherwise no.
        bcc cmd_input_loop                  ; New key input? Carry set yes, otherwise no.
        cmp #$08                        ; Backspace?
        beq cmd_input_bs
        cmp #$0A                        ; Is the key LF? (i.e. is enter pressed?)
        beq cmd_input_lf
        cmp #$1B
        beq cmd_input_esc
        jsr PRINTC                      ; Echo the key to the output 
        lda #'_'
        jsr SETC
        jmp cmd_input_loop              ; Keep getting characters
cmd_input_bs:                           ; Processing backspace.
        sei 
        lda KB_WPTR
        beq cmd_input_loop              ; Write pointer == 0, cant backspace further.
        dec KB_WPTR
        dec KB_RPTR
        cli 
        jmp cmd_input_loop

cmd_input_esc:
        lda ASM_MODE
        cmp #ASM_ED_MODE
        bne @return
        jmp CMD_ASM
@return:
        jmp cmd_input_loop

save_to_source_jmp:
        jmp save_to_source

cmd_input_lf:                           ; LF pressed(aka Enter key). Start comparing input string to commands
        lda ASM_MODE
        cmp #ASM_ED_MODE
        beq save_to_source_jmp          ; If in edit mode save input to source memory
        sei    
        jsr PRINTCCTRL                                         
        lda KB_WPTR
        sta READ_END_PTR
        ldy #$FF                        ; Set Y to 0 as command line starts at buffer index 0 (here sets $FF because of future iny)
        ldx #$00                        ; X indicates which command is matched

        lda #<ASM_CMD
        sta CMD_PTR
        lda #>ASM_CMD
        sta CMD_PTR + 1

cmd_compare_loop:
        iny 
        sec 
        lda (CMD_PTR), Y 
        sbc KB_BUF, Y                   ; do (CMD_PTR),Y minus KB_BUF
        beq cmd_compare_loop            ; If result zero keep comparing
        cmp #%10000000                  ; If two char are only off by bit 7, check if KB_BUF next char is space or LF
        beq chk_next_space_lf
        jmp compare_not_match           ; Character not match

chk_next_space_lf:
        iny 
        lda KB_BUF, Y 
        cmp #' '
        beq compare_match
        cmp #$0A 
        beq compare_match

compare_not_match:
        txa 
        pha 
        ldx #0
@loop:                                  ; Keep incrementing CMD_PTR until char bit 7 is 1
        inc16 CMD_PTR
        lda (CMD_PTR,X)
        bpl @loop 
        inc16 CMD_PTR
        lda (CMD_PTR,X)
        beq no_cmd_found
        pla 
        tax 
        inx 
        ldy #$FF
        jmp cmd_compare_loop

compare_match:
        txa 
        asl A 
        tax 
        inx 
        lda ASM_CMD_ADDR,x 
        pha 
        dex 
        lda ASM_CMD_ADDR, x 
        pha 
        cli 
        rts                             ; Get the Xs command and do a RTS jump
        
no_cmd_found:
        pla 
        tax 
        cli 
        printIm ASM_ERR_CMD_NO
        putctrlchar #$0A
        jmp input_ok

save_to_source:                         ; Save input buffer to source
        sei 
        ldy #0
        ldx #0
@loop:
        lda KB_BUF,Y
        sta (ASM_SRC_PTR),Y
        iny 
        cpy #22
        bne @loop 
save_source_done:
        lda ASM_SRC_PTR
        sta ZPR0
        lda ASM_SRC_PTR + 2
        sta ZPR1 

        sec
        lda ASM_SRC_PTR
        sbc #2
        sta ASM_SRC_PTR
        lda ASM_SRC_PTR + 1
        sbc #0
        sta ASM_SRC_PTR + 1

        ldy #0 
        lda ZPR0
        sta (ASM_SRC_PTR),Y
        iny 
        lda ZPR1 
        sta (ASM_SRC_PTR),Y

        clc 
        lda ASM_SRC_PTR
        adc #26
        sta ASM_SRC_PTR
        lda ASM_SRC_PTR + 1
        adc #0
        sta ASM_SRC_PTR + 1

        inc16 ASM_CUR_LINE
        putctrlchar #$0A

input_ok:
        cli
        jmp main_loop

exit:
        jmp input_process_done

ASM_ERR_CMD_NO: PString "CMD NOT FOUND"

ASM_CMD:
        Cmd "ed"
        Cmd "run"
        Cmd "exit"
        Cmd "asm"
        Cmd "dis"
        Cmd "list"
        Cmd "rx"
        Cmd "tx"
        .byte $00
ASM_CMD_ADDR:
        .word cmded - 1
        .word cmdrun - 1
        .word cmdexit - 1
        .word cmdasm - 1
        .word cmddis - 1
        .word cmdlist - 1
        .word cmdrx - 1
        .word cmdtx - 1

cmded:
        lda #ASM_ED_MODE
        sta ASM_MODE
        jmp input_ok

cmdrun:
        jmp input_ok

cmdexit:
        jmp exit

cmdasm:
        jmp input_ok

cmddis:
        jmp input_ok

.proc cmdlist
        ldx #1
        stx ASM_LIST_LINE               ; List line reset to 0
        ldx #0
        stx ASM_LIST_LINE + 1

        lda SOURCE_START + 22           ; Get next pointer
        sta ASM_LIST_PTR
        lda SOURCE_START + 23
        sta ASM_LIST_PTR + 1

list_source:
        putctrlchar #$0A
        lda ASM_LIST_LINE
        sta ARG0_VAL
        lda ASM_LIST_LINE + 1
        sta ARG0_VAL + 1
        jsr HTOA                        ; Convert current line number into string

        lda RET_STR + 5                 ; Display line number
        jsr PRINTC
        lda RET_STR + 6
        jsr PRINTC
        lda RET_STR + 7
        jsr PRINTC
        lda RET_STR + 8
        jsr PRINTC
        putchar #':'
        ldy #0
@loop:
        lda (ASM_LIST_PTR),Y 
        cmp #$0A                        ; Is LF?
        beq line_feed                   ; Yes
        jsr PRINTC                      ; otherwise, print character
        iny                             ; Advance to next character
        cpy #22                         ; End of the line buffer?
        bne @loop
goto_next_ptr:
        lda (ASM_LIST_PTR),Y            ; Get next pointer low byte
        beq list_ptr_low_zero           ; Is 0?
goto_continue:
        sta ZPR0                        ; Store low byte to ZPR0 (temporary)
        iny 
        lda (ASM_LIST_PTR),Y 
        sta ZPR1                        ; Store high byte to ZPR1 (temporary)

        lda ZPR0                        ; Put next pointer in list pointer
        sta ASM_LIST_PTR
        lda ZPR1 
        sta ASM_LIST_PTR + 1

        inc16 ASM_LIST_LINE
        jmp list_source

list_ptr_low_zero:
        iny 
        lda (ASM_LIST_PTR),Y            ; Is next pointer high also 0?
        beq end_of_source               ; Yes, its nullptr, end of listing
        dey  
        jmp goto_continue

line_feed:
        iny 
        cpy #22
        bne line_feed                   ; Advance until pointer to next pointer low byte
        jmp goto_next_ptr

end_of_source:
        putctrlchar #$0A
        jmp input_ok
.endproc 

cmdrx:
        jmp input_ok 

cmdtx:
        jmp input_ok
.endproc