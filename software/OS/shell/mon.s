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