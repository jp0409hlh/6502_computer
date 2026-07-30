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

; print control character
.macro putctrlchar arg 
        lda arg 
        jsr PRINTCCTRL
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
SHELL_CMD_NOT_FND:      PString "CMD NOT FOUND"
SHELL_CMD:          
        Cmd "clr"  
        Cmd "help" 
        Cmd "info" 
        Cmd "mon"  
        Cmd "run"  
        Cmd "card" 
        Cmd "ser"  
        Cmd "rst"  
        Cmd "col" 
        Cmd "asm"  
        Cmd "rx" 
        .byte $00
        
SHELL_CMD_ADDR:                 ; RTS style jump table
        .word CMD_CLR - 1  ; clear screen
        .word CMD_HELP -1  ; help
        .word CMD_INFO -1  ; information
        .word CMD_MON  -1  ; enter monitor
        .word CMD_RUN  -1  ; run executable
        .word CMD_CARD -1  ; Expansion card
        .word CMD_SER  -1  ; Serial things
        .word CMD_RST  -1  ; resets the system
        .word CMD_COL  -1  ; Changes color of the terminal
        .word CMD_ASM  -1  ; Enters assmenbly editor
        .word CMD_RX   -1  ; Load program from serial
SHELL_START:
; TODO : memory check, VDP check
; TODO : Serial only shell?
        printIm SHELL_NAME_VER
        putctrlchar #$0A 
        putchar #'@'
        putchar #' '
        lda #'_'
        jsr SETC                        ; Setup cursor
        lda #$00
        sta KB_RPTR                     ; Reset read write pointer
        sta KB_WPTR
        sta READ_PTR
        sta READ_END_PTR

        lda #'H'                        ; debug purpose
        sta ACIA_DATA
        cli 
SHELL_LOOP:
        jsr GETC                        ; Get character. Carry set if new key, otherwise no.
        bcc SHELL_LOOP                  ; New key input? Carry set yes, otherwise no.
        cmp #$08                        ; Backspace?
        beq input_backspace
        cmp #$0A                        ; Is the key LF? (i.e. is enter pressed?)
        beq input_line_feed
        jsr PRINTC                      ; Echo the key to the output 
        lda #'_'
        jsr SETC
        jmp SHELL_LOOP                  ; Keep getting characters
input_backspace:                        ; Processing backspace.
        sei 
        lda KB_WPTR
        beq SHELL_LOOP                  ; Write pointer == 0, cant backspace further.
        dec KB_WPTR
        dec KB_RPTR
        cli 
        jmp SHELL_LOOP

input_line_feed:                        ; LF pressed(aka Enter key). Start comparing input string to commands
        sei    
        jsr PRINTCCTRL                                         
        lda KB_WPTR
        sta READ_END_PTR
        ldy #$FF                        ; Set Y to 0 as command line starts at buffer index 0 (here sets $FF because of future iny)
        ldx #$00                        ; X indicates which command is matched

        lda #<SHELL_CMD
        sta CMD_PTR
        lda #>SHELL_CMD
        sta CMD_PTR + 1

command_compare_loop:
        iny 
        sec 
        lda (CMD_PTR), Y 
        sbc KB_BUF, Y                   ; do (CMD_PTR),Y minus KB_BUF
        beq command_compare_loop        ; If result zero keep comparing
        cmp #%10000000                  ; If two char are only off by bit 7, check if KB_BUF next char is space or LF
        beq check_next_space_LF
        jmp current_compare_not_match   ; Character not match

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
@loop:                                  ; Keep incrementing CMD_PTR until char bit 7 is 1
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
        rts                             ; Get the Xs command and do a RTS jump
        
no_command_found:
        pla 
        tax 
        cli 
        printIm SHELL_CMD_NOT_FND

input_process_done:
        putctrlchar #$0A
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


.proc CMD_CARD
        jmp input_process_done
.endproc 

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

; MONITOR
; wozmon style monitor, orginally written by Steve Wozniak
.proc CMD_MON
        iny 
        lda KB_BUF, Y 
        cmp #' '
        beq CMD_MON                     ; Loops until non space character
wozmon_starts:
        dey 
        lda #$00                        ; For XAM mode
        tax                             ; X = 0
setblock:
        asl 
setstor:
        asl                             ; Leaves $7B if STOR mode
        sta MON_MODE
blskip:
        iny                             ; Next character
nextitem:
        lda KB_BUF, Y                   ; Get character
        cmp #$0A                        ; LF?
        beq exit_mon1                   ; Yes, exits
        cmp #'.'                        ; "."?
        bcc blskip                      ; skips delimeter
        beq setblock                    ; Set BLOCK XAM mode
        cmp #':'                        ; ":"?
        beq setstor                     ; Set STOR mode
        cmp #'r'                        ; "r"?
        beq run                         ; Run user program
        stx MON_L                       ; $00->L
        stx MON_H                       ; $00->H
        sty MON_YSAV                    ; Saves Y

nexthex:
        lda KB_BUF, Y                   ; Get character for hex test
        eor #$30                        ; Map digits to $0-9
        cmp #$0A                        ; Digit?
        bcc is_digit                    ; Yes 
        adc #$A8                        ; Map letter "a"-"f" to $FA-FF
        cmp #$FA                        ; Hex letter?
        bcc nothex                      ; character not hex
is_digit:
        asl A                           ; Hex digit to MSD
        asl A 
        asl A 
        asl A

        ldx #$04                        ; Shift count
hexshift:
        asl A                           ; Hex digit left, MSB to carry
        rol MON_L                       ; Rotate into LSD
        rol MON_H                       ; Rotate into MSD
        dex                             ; Done 4 shifts?
        bne hexshift                    ; No, keep looping
        iny                             ; Next character
        bne nexthex                     ; jmp to check next hex character

nothex:
        cpy MON_YSAV                    ; Check if L, H empty (no hex digits)
        beq exit                        ; Yes, exits

        bit MON_MODE                    ; Test MODE
        bvc notstor                     ; Bit-6 = 0 is STOR, 1 is XAM and BLOCK XAM

        lda MON_L                       ; LSD's of hex data
        sta (MON_STL,X)                 ; Store current 'store index'
        inc MON_STL                     ; Increment store index
        bne nextitem                    ; Get next item (no carry)
        inc MON_STH                     ; Add carry to 'store index' high order
tonextitem:
        jmp nextitem                    ; Get next command item

exit_mon1:
        jmp exit

run:
        jmp (MON_XAML)                  ; Run at current XAM index

notstor:
        bmi xamnext                     ; Bit-7 = 0 for XAM, 1 for BLOCK XAM

        ldx #$02                        ; Byte count
setadr:
        lda MON_L-1, X                  ; Copy hex data to
        sta MON_STL-1, X                ;  'store index'
        sta MON_XAML-1, X               ;  and to 'XAM index'
        dex 
        bne setadr                      ; Loop until X = 0

nxtprnt:
        bne prdata                      ; Not equal means no address to print
        putctrlchar #$0A                ; Print linefeed
        lda MON_XAMH                    ; Get data byte at 'XAM index'
        jsr prbyte                      ; Output it in hex format
        lda MON_XAML                    ; Low-order 'XAM index' byte
        jsr prbyte                      ; Output it in hex format
        putchar #':'
prdata:
        putchar #' '                    ; Blank
        lda (MON_XAML,X)                ; Get data byte at 'XAM index'
        jsr prbyte
xamnext:
        stx MON_MODE                    ; 0->MODE (XAM mode)
        lda MON_XAML
        cmp MON_L                       ; Compare 'XAM index' to hex data
        lda MON_XAMH                    
        sbc MON_H
        bcs tonextitem                  ; Not less, so no more data to output

        inc MON_XAML
        bne mod8chk                     ; Increment 'XAM index'
        inc MON_XAMH

mod8chk:
        lda MON_XAML                    ; Check low-order 'XAM index' byte
        and #$07                        ; For MOD 8 = 0
        bpl nxtprnt                     ; Always taken

prbyte:
        pha                             ; Save A for LSD
        lsr A                           ; MSD to LSD position
        lsr A 
        lsr A 
        lsr A
        jsr prhex                       ; Output hex digit
        pla                             ; Restore A
prhex:
        and #$0F                        ; Mask LSD for hex print
        ora #$30                        ; Add "0"
        cmp #$3A                        ; Digit?
        bcc echo                        ; Yes, output it
        adc #$06                        ; Add offset for letter
echo:
        jsr PRINTC
        rts 
exit:
        jmp input_process_done
.endproc 


; RESET 
; Soft resets the system
.proc CMD_RST
        jmp RESET
.endproc 



.proc CMD_RUN
        jsr RAM_START
        jmp input_process_done
.endproc 



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