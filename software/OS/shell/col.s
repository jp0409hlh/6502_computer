; COLOR
; Changes terminal color
; !!! TODO !!! : what will this be in serial mode?
.proc CMD_COL
        ldx #$FE 
get_arg:
        iny                             ; get argument
        lda KB_BUF, Y 
        eor #$30                        ; Map char '0'-'9' to $0-9
        cmp #$0A                        ; Is digit?
        bcc is_digit                    ; Yes
        adc #$A8                        ; Map char 'a'-'f' to $FA-$FF
        cmp #$FA                        ; Is Hex char?
        bcc arg_err                     ; No
        sec 
        sbc #$F0
is_digit:
shift_msd:
        inx 
        beq get_arg_done
        asl A 
        asl A 
        asl A 
        asl A 
        sta ZPR0
        jmp get_arg
get_arg_done:
        clc 
        adc ZPR0
        sta VDP_REG
        lda #VDP_REG7
        sta VDP_REG
        jmp input_process_done
arg_err:
        printIm arg_err_msg
return:
        jmp input_process_done

arg_err_msg: PString "ARG ERR"
.endproc 