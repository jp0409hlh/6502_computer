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


.include "clr.s"  
.include "help.s" 
.include "info.s" 
.include "mon.s"  
.include "run.s"  
.include "card.s" 
.include "ser.s"  
.include "rst.s"  
.include "col.s" 
.include "asm.s"  
.include "rx.s" 