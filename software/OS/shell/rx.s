; RECEIVE
; LOAD PROGRAM FROM SERIAL (XMODEM)
.proc CMD_RX
        printIm listening_msg
        lda #<RAM_START                 ; Setup pointer for loading byte
        sta LOAD_PTR                    ; as well as the previous pointer
        sta LAST_LOAD_PTR
        lda #>RAM_START
        sta LOAD_PTR + 1
        sta LAST_LOAD_PTR + 1
        ldx #$00                        ; Set previous blknum to 0
        stx LAST_BLK_NUM
        stx ZPR3
start:
        printIm send_NAK_msg
        lda #NAK                        ; Send NAK
        jsr SSENDC
        lda #$0A                        ; New line
        jsr PRINTCCTRL
get_SOH_loop:
        jsr SGETC
        bcc get_SOH_loop
        cmp #SOH                        ; Got SOH?
        beq received_SOH                ; Yes
        cmp #EOT                        ; Got EOT?
        beq end_of_transfer             ; Yes, end of transfer
        jmp get_SOH_loop                ; Otherwise, keep listening
end_of_transfer:
        jmp transfer_done
dup_transfer:
        lda #ACK 
        jsr SSENDC
        jmp get_SOH_loop
received_SOH:
get_blknum:
        printIm got_SOH_msg
        jsr SGETC
        bcc get_blknum                   ; Got block number?
        cmp LAST_BLK_NUM                 ; Is it the same as the previous?
        beq send_ACK                     ; Yes, duplicate block, send ACK
        sta ZPR3                         ; Temporarily save block number to ZPR3
        printIm got_blk_num_msg
get_inv_blknum:
        jsr SGETC
        bcc get_inv_blknum               ; Got inverse block number?
        clc 
        adc ZPR3                         ; Add it with block number
        cmp #$FF                         ; Is it 255?
        bne start                        ; No, send NAK and retry
        printIm got_inv_blk_num_cor
                                         ; Otherwise start receiving packet data
        ldy #128
        stx ZPR2                         ; Initialize chksum result to 0
get_packet_data_loop:
get_packet_data:
        jsr SGETC
        bcc get_packet_data               ; Got data?
        sta (LOAD_PTR,X)                  ; Store it to (LOAD_PTR + 0)
        clc 
        adc ZPR2                          ; Add to chksum
        sta ZPR2
        inc16 LOAD_PTR                    ; Increment LOAD_PTR
        dey                     
        bne get_packet_data_loop          ; End of 128 byte transfer?

get_chk_sum:
        jsr SGETC
        bcc get_chk_sum                   ; Get chksum from transeiver
        cmp ZPR2                          ; Is it correct?
        beq chk_sum_correct               ; Yes
        printIm chksum_error
        lda LAST_LOAD_PTR                 ; Otherwise, restore LOAD_PTR and try again
        sta LOAD_PTR
        lda LAST_LOAD_PTR + 1
        sta LOAD_PTR + 1
        jmp start
send_ACK:                                 ; All correct, send ACK
chk_sum_correct:
        lda #ACK                          ; Send ACK
        jsr SSENDC
        printIm send_ACK_msg
        inc LAST_BLK_NUM                  ; Increment previous block number
        lda LOAD_PTR                      ; LAST_LOAD_PTR = LOAD_PTR
        sta LAST_LOAD_PTR
        lda LOAD_PTR + 1
        sta LAST_LOAD_PTR + 1
        jmp get_SOH_loop                  ; Get the next packet
transfer_done:
        lda #ACK                          ; Send ACK
        jsr SSENDC
        lda #$0A
        jsr PRINTCCTRL
        printIm end_of_transfer_msg
        jmp input_process_done

listening_msg: PString "Listening..."
send_NAK_msg: PString "NAK->/"
send_ACK_msg: PString "ACK->/"
got_SOH_msg: PString "<-SOH/"
got_blk_num_msg: PString "<-blknum/ "
got_inv_blk_num_cor: PString "[blknum ok]"
chksum_error: PString "!chksum err!"
end_of_transfer_msg: PString "Ready"
.endproc 