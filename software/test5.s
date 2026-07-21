    .org $0600

    ldx #$00
loop:  
    lda msg,X
    beq done
    jsr $C4AF
    inx 
    jmp loop 

done:
    rts 


msg: .asciiz "HELLO XMODEM!"