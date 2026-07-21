.segment "SHELL"

; 16 bit increment
.macro inc16 arg 
        clc 
        lda arg 
        adc #1
        sta arg
        lda arg + 1 
        adc #0
        sta arg + 1
.endmacro

; Print string immediate (string constant)
.macro  printIm  arg
        lda #<arg
        sta STR_PTR
        lda #>arg
        sta STR_PTR + 1
        jsr PRINTS
.endmacro

; print character
.macro putchar arg
        lda arg
        jsr PRINTC
.endmacro

; Pascal style string
.macro  PString Arg
        .byte   .strlen(Arg), Arg
.endmacro
  
; Set the MSB of the last char of a string to indicate the end.
.macro Cmd arg 
        .repeat	.strlen(arg)-1,I
		.byte	.strat(arg,I)
	.endrep
	.byte	.strat(arg,.strlen(arg)-1) | $80
.endmacro

SHELL_NAME_VER:     PString "JP6502 OS v0.0.1"
SHELL_CMD_NOT_FND:      PString "No command found"
SHELL_CMD:          
        Cmd "clr"  
        Cmd "dump" 
        Cmd "help" 
        Cmd "info" 
        Cmd "mon"  
        Cmd "run"  
        Cmd "card" 
        Cmd "ser"  
        Cmd "rst"  
        Cmd "col" 
        Cmd "asm"  
        Cmd "load" 
        .byte $00
        
SHELL_CMD_ADDR:                 ; RTS style jump table
        .word CMD_CLR - 1   ; clear screen
        .word CMD_DUMP -1   ; hexdump memory
        .word CMD_HELP -1  ; help
        .word CMD_INFO -1  ; information
        .word CMD_MON  -1  ; enter monitor
        .word CMD_RUN  -1  ; run executable
        .word CMD_CARD -1  ; Expansion card
        .word CMD_SER  -1  ; Serial things
        .word CMD_RST  -1  ; resets the system
        .word CMD_COL  -1  ; Changes color of the terminal
        .word CMD_ASM  -1  ; Enters assmenbly editor
        .word CMD_LOAD -1  ; Load program from serial
SHELL_START:
; TODO : memory check, VDP check
; TODO : Serial only shell?
        printIm SHELL_NAME_VER
        putchar #$0A 
        putchar #'@'
        putchar #' '
        lda #'_'
        jsr SETC                                        ; Setup cursor
        lda #$00
        sta KB_RPTR                                     ; Reset read write pointer
        sta KB_WPTR
        sta READ_PTR
        sta READ_END_PTR

        lda #'H'
        sta ACIA_DATA
        cli 
SHELL_LOOP:
        jsr GETC                                        ; Get character. Carry set if new key, otherwise no.
        bcc SHELL_LOOP                                  ; New key input? Carry set yes, otherwise no.
        cmp #$08                                        ; Backspace?
        beq input_backspace
        jsr PRINTC                                      ; Echo the key to the output 
        cmp #$0A                                        ; Is the key LF? (i.e. is enter pressed?)
        beq input_line_feed
        lda #'_'
        jsr SETC
        jmp SHELL_LOOP                                  ; Keep getting characters
input_backspace:                                        ; Processing backspace.
        sei 
        lda KB_WPTR
        beq SHELL_LOOP                                  ; Write pointer == 0, cant backspace further.
        dec KB_WPTR
        dec KB_RPTR
        cli 
        jmp SHELL_LOOP

input_line_feed:                                        ; LF pressed(aka Enter key). Start comparing input string to commands
        sei                                             
        lda KB_WPTR
        sta READ_END_PTR
        ldy #$FF                                        ; Set Y to 0 as command line starts at buffer index 0 (here sets $FF because of future iny)
        ldx #$00                                        ; X indicates which command is matched

        lda #<SHELL_CMD
        sta CMD_PTR
        lda #>SHELL_CMD
        sta CMD_PTR + 1

command_compare_loop:
        iny 
        sec 
        lda (CMD_PTR), Y 
        sbc KB_BUF, Y                                   ; do (CMD_PTR),Y minus KB_BUF
        beq command_compare_loop                        ; If result zero keep comparing
        cmp #%10000000                                  ; If two char are only off by bit 7, check if KB_BUF next char is space or LF
        beq check_next_space_LF
        jmp current_compare_not_match                   ; Character not match

check_next_space_LF:
        iny 
        lda KB_BUF, Y 
        cmp #' '
        beq current_compare_match
        cmp #$0A 
        beq current_compare_match

current_compare_not_match:
        txa 
        pha 
        ldx #0
@loop:                                                  ; Keep incrementing CMD_PTR until char bit 7 is 1
        inc16 CMD_PTR
        lda (CMD_PTR,X)
        bpl @loop 
        inc16 CMD_PTR
        lda (CMD_PTR,X)
        beq no_command_found
        pla 
        tax 
        inx 
        ldy #$FF
        jmp command_compare_loop

current_compare_match:
        txa 
        asl A 
        tax 
        inx 
        lda SHELL_CMD_ADDR,x 
        pha 
        dex 
        lda SHELL_CMD_ADDR, x 
        pha 
        cli 
        rts                                             ; Get the Xs command and do a RTS jump
        
no_command_found:
        pla 
        tax 
        cli 
        printIm SHELL_CMD_NOT_FND

input_process_done:
        putchar #$0A
        lda #$00
        sta KB_RPTR
        sta KB_WPTR
        sta READ_PTR
        sta READ_END_PTR
        putchar #'@'
        putchar #' '
        lda #'_'
        jsr SETC
shell_no_input:
not_line_feed:
        cli 
        jmp SHELL_LOOP







CMD_ASM:
        jmp input_process_done


CMD_CARD:
        jmp input_process_done


CMD_CLR:
        lda #$00
        sta VDP_REG
        lda #($00 | $40)
        sta VDP_REG
        ldy #25
cmd_clr_loop:
        ldx SCREEN_WIDTH
cmd_clr_loop1:
        lda #' '                            ; Space
        sta VDP_RAM
        dex
        bne cmd_clr_loop1
        dey
        bne cmd_clr_loop
 
        lda #$00
        sta CURSOR_X
        sta CURSOR_Y
        lda #$00
        sta VDP_REG
        lda #$00
        ora #$40
        sta VDP_REG
        jmp input_process_done


CMD_COL:
        ldx #$FE 
cmd_col_get_arg:
        iny                                     ; get argument
        lda KB_BUF, Y 
        eor #$30                                ; Map char '0'-'9' to $0-9
        cmp #$0A                                ; Is digit?
        bcc cmd_col_is_digit                    ; Yes
        adc #$88                                ; Map char 'A'-'F' to $FA-$FF
        cmp #$FA                                ; Is Hex char?
        bcc cmd_col_arg_err                     ; No
        sec 
        sbc #$F0
cmd_col_is_digit:
cmd_col_shift_msd:
        inx 
        beq cmd_col_get_arg_done
        asl A 
        asl A 
        asl A 
        asl A 
        sta ZPR0
        jmp cmd_col_get_arg
cmd_col_get_arg_done:
        clc 
        adc ZPR0
        sta VDP_REG
        lda #VDP_REG7
        sta VDP_REG
        jmp input_process_done
cmd_col_arg_err:
        printIm cmd_col_arg_err_msg
cmd_col_return:
        jmp input_process_done

cmd_col_arg_err_msg: PString "ARG ERR"


CMD_DUMP:
        jmp input_process_done


CMD_HELP:
        jmp input_process_done


CMD_INFO:
        jmp input_process_done


; LOAD PROGRAM FROM SERIAL (XMODEM)
CMD_LOAD:
        printIm cmd_load_listening_msg
        lda #<RAM_START                                 ; Setup pointer for loading byte
        sta LOAD_PTR                                    ; as well as the previous pointer
        sta LAST_LOAD_PTR
        lda #>RAM_START
        sta LOAD_PTR + 1
        sta LAST_LOAD_PTR + 1
        ldx #$00                                                ; Set previous blknum to 0
        stx LAST_BLK_NUM
        stx ZPR3
cmd_load_start:
        printIm cmd_load_send_NAK_msg
        lda #NAK                                                ; Send NAK
        jsr SPRINTC
        lda #$0A                                                ; New line
        jsr PRINTC 
get_SOH_loop:
        jsr SGETC
        bcc get_SOH_loop
        cmp #SOH                                                ; Got SOH?
        beq received_SOH                                        ; Yes
        cmp #EOT                                                ; Got EOT?
        beq end_of_transfer                                     ; Yes, end of transfer
        jmp get_SOH_loop                                        ; Otherwise, keep listening
end_of_transfer:
        jmp transfer_done
received_SOH:
get_blknum:
        printIm cmd_load_got_SOH_msg
        jsr SGETC
        bcc get_blknum                                          ; Got block number?
        cmp LAST_BLK_NUM                                        ; Is it the same as the previous?
        beq send_ACK                                            ; Yes, duplicate block, send ACK
        sta ZPR3                                                ; Temporarily save to ZPR3
        printIm cmd_load_got_blk_num_msg
get_inv_blknum:
        jsr SGETC
        bcc get_inv_blknum                                      ; Got inverse block number?
        clc 
        adc ZPR3                                                ; Add it with block number
        cmp #$FF                                                ; Is it 255?
        bne cmd_load_start                                      ; No, send NAK and retry
        printIm cmd_load_got_inv_blk_num_cor
                                                                ; Otherwise start receiving packet data
        ldy #128
        stx ZPR2                                                ; Initialize chksum result to 0
get_packet_data_loop:
get_packet_data:
        jsr SGETC
        bcc get_packet_data                                     ; Got data?
        sta (LOAD_PTR,X)                                        ; Store it to (LOAD_PTR + 0)
        clc 
        adc ZPR2                                                ; Add chksum
        sta ZPR2
        inc16 LOAD_PTR                                          ; Increment LOAD_PTR
        dey                     
        bne get_packet_data_loop                                ; End of 128 byte transfer?

get_chk_sum:
        jsr SGETC
        bcc get_chk_sum                                         ; Get chksum from transeiver
        cmp ZPR2                                                ; Is it correct?
        beq chk_sum_correct                                     ; Yes
        printIm cmd_load_chksum_error
        lda LAST_LOAD_PTR                                       ; Otherwise, restore LOAD_PTR and try again
        sta LOAD_PTR
        lda LAST_LOAD_PTR + 1
        sta LOAD_PTR
        jmp cmd_load_start
send_ACK:                                                       ; All correct, send ACK
chk_sum_correct:
        lda #ACK                                                ; Send ACK
        jsr SPRINTC
        printIm cmd_load_send_ACK_msg
        inc LAST_BLK_NUM                                        ; Increment previous block number
        lda LOAD_PTR                                            ; LAST_LOAD_PTR = LOAD_PTR
        sta LAST_LOAD_PTR
        lda LOAD_PTR + 1
        sta LAST_LOAD_PTR + 1
        jmp get_SOH_loop                                        ; Get the next packet
transfer_done:
        lda #ACK                                                ; Send ACK
        jsr SPRINTC
        lda #$0A
        jsr PRINTC
        printIm cmd_load_end_of_transfer_msg
        jmp input_process_done

cmd_load_listening_msg: PString "Listening..."
cmd_load_send_NAK_msg: PString "NAK->/"
cmd_load_send_ACK_msg: PString "ACK->/"
cmd_load_got_SOH_msg: PString "<-SOH/"
cmd_load_got_blk_num_msg: PString "<-blknum/ "
cmd_load_got_inv_blk_num_cor: PString "[blknum ok]"
cmd_load_chksum_error: PString "!chksum err!"
cmd_load_end_of_transfer_msg: PString "Ready"

; MONITOR
; Orginally written by Steve Wozniak
exit_mon1:
        jmp exit_mon
CMD_MON:
        iny 
        lda KB_BUF, Y 
        cmp #' '
        beq CMD_MON                     ; Loops until non space character
wozmon_starts:
        dey 
        lda #$00                        ; For XAM mode
        tax                             ; X = 0
cmd_mon_setblock:
        asl 
cmd_mon_setstor:
        asl                             ; Leaves $7B if STOR mode
        sta MON_MODE
cmd_mon_blskip:
        iny                             ; Next character
cmd_mon_nextitem:
        lda KB_BUF, Y                   ; Get character
        cmp #$0A                        ; LF?
        beq exit_mon1                   ; Yes, exits
        cmp #'.'                        ; "."?
        bcc cmd_mon_blskip                      ; skips delimeter
        beq cmd_mon_setblock                    ; Set BLOCK XAM mode
        cmp #':'                        ; ":"?
        beq cmd_mon_setstor                     ; Set STOR mode
        cmp #'r'                        ; "r"?
        beq cmd_mon_run                         ; Run user program
        stx MON_L                       ; $00->L
        stx MON_H                       ; $00->H
        sty MON_YSAV                    ; Saves Y

cmd_mon_nexthex:
        lda KB_BUF, Y                   ; Get character for hex test
        eor #$30                        ; Map digits to $0-9
        cmp #$0A                        ; Digit?
        bcc cmd_mon_is_digit            ; Yes 
        adc #$A8                        ; Map letter "a"-"f" to $FA-FF
        cmp #$FA                        ; Hex letter?
        bcc cmd_mon_nothex              ; character not hex
cmd_mon_is_digit:
        asl A                           ; Hex digit to MSD
        asl A 
        asl A 
        asl A

        ldx #$04                        ; Shift count
cmd_mon_hexshift:
        asl A                           ; Hex digit left, MSB to carry
        rol MON_L                       ; Rotate into LSD
        rol MON_H                       ; Rotate into MSD
        dex                             ; Done 4 shifts?
        bne cmd_mon_hexshift            ; No, keep looping
        iny                             ; Next character
        bne cmd_mon_nexthex             ; jmp to check next hex character

cmd_mon_nothex:
        cpy MON_YSAV                    ; Check if L, H empty (no hex digits)
        beq exit_mon                    ; Yes, exits

        bit MON_MODE                    ; Test MODE
        bvc cmd_mon_notstor             ; Bit-6 = 0 is STOR, 1 is XAM and BLOCK XAM

        lda MON_L                       ; LSD's of hex data
        sta (MON_STL,X)                 ; Store current 'store index'
        inc MON_STL                     ; Increment store index
        bne cmd_mon_nextitem            ; Get next item (no carry)
        inc MON_STH                     ; Add carry to 'store index' high order
cmd_mon_tonextitem:
        jmp cmd_mon_nextitem            ; Get next command item

cmd_mon_run:
        jmp (MON_XAML)                  ; Run at current XAM index

cmd_mon_notstor:
        bmi cmd_mon_xamnext             ; Bit-7 = 0 for XAM, 1 for BLOCK XAM

        ldx #$02                        ; Byte count
cmd_mon_setadr:
        lda MON_L-1, X                  ; Copy hex data to
        sta MON_STL-1, X                ;  'store index'
        sta MON_XAML-1, X                    ;  and to 'XAM index'
        dex 
        bne cmd_mon_setadr              ; Loop until X = 0

cmd_mon_nxtprnt:
        bne cmd_mon_prdata              ; Not equal means no address to print
        putchar #$0A                    ; Print linefeed
        lda MON_XAMH                ; Get data byte at 'XAM index'
        jsr cmd_mon_prbyte              ; Output it in hex format
        lda MON_XAML                    ; Low-order 'XAM index' byte
        jsr cmd_mon_prbyte              ; Output it in hex format
        putchar #':'
cmd_mon_prdata:
        putchar #$20                    ; Blank
        lda (MON_XAML,X)                ; Get data byte at 'XAM index'
        jsr cmd_mon_prbyte
cmd_mon_xamnext:
        stx MON_MODE                    ; 0->MODE (XAM mode)
        lda MON_XAML
        cmp MON_L                       ; Compare 'XAM index' to hex data
        lda MON_XAMH                    
        sbc MON_H
        bcs cmd_mon_tonextitem          ; Not less, so no more data to output

        inc MON_XAML
        bne cmd_mon_mod8chk             ; Increment 'XAM index'
        inc MON_XAMH

cmd_mon_mod8chk:
        lda MON_XAML                    ; Check low-order 'XAM index' byte
        and #$07                        ; For MOD 8 = 0
        bpl cmd_mon_nxtprnt             ; Always taken

cmd_mon_prbyte:
        pha                             ; Save A for LSD
        lsr A                           ; MSD to LSD position
        lsr A 
        lsr A 
        lsr A
        jsr cmd_mon_prhex               ; Output hex digit
        pla                             ; Restore A

cmd_mon_prhex:
        and #$0F                        ; Mask LSD for hex print
        ora #$30                        ; Add "0"
        cmp #$3A                        ; Digit?
        bcc cmd_mon_echo                ; Yes, output it
        adc #$06                        ; Add offset for letter
cmd_mon_echo:
        jsr PRINTC
        rts 
exit_mon:
        jmp input_process_done


CMD_RST:
        jmp RESET


CMD_RUN:

        jsr RAM_START
        jmp input_process_done


CMD_SER:
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