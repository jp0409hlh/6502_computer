; INFORMATION
; Prints system information
.proc CMD_INFO
        lda #$01
        sta ARG0_VAL
        lda #$23
        sta ARG0_VAL + 1
        lda #$45
        sta ARG0_VAL + 2
        lda #$67
        sta ARG0_VAL + 3
        jsr HTOA
        printIm RET_STR
        jmp input_process_done
.endproc 