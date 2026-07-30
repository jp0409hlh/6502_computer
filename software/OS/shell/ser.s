; SERIAL 
; Configures serial things 
.proc CMD_SER
        ldx #$00
@loop:
        lda msg,x
        beq ok
        jsr SPRINTC
        inx 
        jmp @loop
ok: 
        jmp input_process_done
msg:    .asciiz "HELLO WORLD"
.endproc 