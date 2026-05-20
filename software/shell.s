.segment "SHELL"

; print string from a fixed memory location
.macro  printIm  arg
        lda #<arg
        ldx #>arg
        jsr PRINTS
.endmacro

; print string
.macro  print arg
        lda arg
        ldx arg + 1
        jsr PRINTS
.endmacro

; print character
.macro putchar arg
        lda arg
        jsr PRINTC
.endmacro

.macro scan
        

SHELL_NAME_VER:     .asciiz "Test Shell V0.0.1\n"
SHELL_HELP_PROMPT:  .asciiz "Type 'help' for list of commands\n"
SHELL_INFO_PROMPT:  .asciiz "Type 'info' for informations\n"
SHELL_CMD:          
        .asciiz "cd"   .word CMD_CD     ; change directory
        .asciiz "clr"  .word CMD_CLR    ; clear screen
        .asciiz "copy" .word CMD_COPY   ; copy file
        .asciiz "list" .word CMD_LIST   ; list directory
        .asciiz "del"  .word CMD_DEL    ; delete file
        .asciiz "dump" .word CMD_DUMP   ; hexdump file
        .asciiz "ed"   .word CMD_ED     ; edit file
        .asciiz "help" .word CMD_HELP   ; help
        .asciiz "info" .word CMD_INFO   ; information
        .asciiz "mkd"  .word CMD_MKD    ; create directory
        .asciiz "mkf"  .word CMD_MKF    ; create file
        .asciiz "move" .word CMD_MOVE   ; move file
        .asciiz "mon"  .word CMD_MON    ; enter monitor
        .asciiz "rmd"  .word CMD_RMD    ; remove directory
        .asciiz "rmf"  .word CMD_RMF    ; remove file
        .asciiz "run"  .word CMD_RUN    ; run executable
SHELL_START:
; TODO : memory check, VDP check
        printIm SHELL_NAME_VER
        printIm SHELL_HELP
        printIm SHELL_INFO
SHELL_LOOP:
        putchar '>'
        jmp SHELL_LOOP

; *****************************************************************
; CD : Change directory                                           *
; *****************************************************************
CMD_CD:
        rts

; *****************************************************************
; CLR : Clears the screen                                         *
; *****************************************************************
CMD_CLR:
        rts

; *****************************************************************
; COPY : Copy a file to destinatiion                              *
; *****************************************************************
CMD_COPY:
        rts

; *****************************************************************
; LIST : List directory contents                                  *
; *****************************************************************
CMD_LIST:
        rts

; *****************************************************************
; DEL : Deletes a file                                            *
; *****************************************************************
CMD_DEL:
        rts

; *****************************************************************
; DUMP : Hex dump a file                                          *
; *****************************************************************
CMD_DUMP:
        rts

; *****************************************************************
; ED : Edits a file                                               *
; *****************************************************************
CMD_ED:
        rts

; *****************************************************************
; HELP : Prints info about commands                               *
; *****************************************************************
CMD_HELP:
        rts

; *****************************************************************
; INFO : Prints the information about the system                  *
; *****************************************************************
CMD_INFO:
	printIm OS_INFO
	rts
    OS_INFO:    .asciiz "Model: JP/65\nOS: JpsfOS 0.0.1\nShell: JPShell 0.0.1\nCPU: 6502\nVDP: tms9918\nMemory: 32 KB\n"

; *****************************************************************
; MKD : Create a new directory                                    *
; *****************************************************************
CMD_MKD:
        rts

; *****************************************************************
; MKF : create a new file                                         *
; *****************************************************************
CMD_MKF:
        rts

; *****************************************************************
; MOVE : Moves a file to another directory                        *
; *****************************************************************
CMD_MOVE:
        rts

; *****************************************************************
; MON : Enters monitor program                                    *
; *****************************************************************
CMD_MON:
        rts

; *****************************************************************
; RMD : Removes a directory                                       *
; *****************************************************************
CMD_RMD:
        rts

; *****************************************************************
; RMF : Removes a file                                            *
; *****************************************************************
        rts

; *****************************************************************
; RUN : Run an executable                                         *
; *****************************************************************

DIR_NOT_FOUND_ERR_MSG:
        .asciiz "!DIR NOT FOUND"
FILE_NOT_FOUND_ERR_MSG:
        .asciiz "!FILE NOT FOUND"
NAME_EXIST_ERR_MSG:
        .asciiz "!THIS DIR/FILE ALR EXISTS"
NOT_EXECUTABLE_ERR_MSG:
        .asciiz "!THIS FILE IS NOT EXECUTABLE"



    





