; HELP
; Lists avaliable commands
.proc CMD_HELP
        lda #0
        sta $1000
        tax 
loop:
        inx 
getchr:
        jsr GETC
        bcc getchr
        cmp #$0A
        beq str_ok
        sta $1000,x 
        jsr PRINTC
        jmp loop
str_ok:
        jsr PRINTCCTRL
        dex 
        stx $1000

        lda #<$1000
        sta STR_PTR
        lda #>$1000
        sta STR_PTR + 1

        jsr PRINTS

        jsr ATOH 
        ;bcc error 

        lda RET_VAL
        sta ARG0_VAL
        lda RET_VAL + 1
        sta ARG0_VAL + 1
        lda RET_VAL + 2
        sta ARG0_VAL + 2
        lda RET_VAL + 3
        sta ARG0_VAL + 3
        jsr HTOA
        printIm RET_STR
        jmp input_process_done
error:
        printIm ERROR 
        jmp input_process_done
ERROR:          PString "ERROR"
.endproc