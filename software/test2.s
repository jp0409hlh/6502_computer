
PORTB = $8200
PORTA = $8201
DDRB = $8202
DDRA = $8203
 .org $8000
 .org $c000
reset:
  ldx #$ff
  txs
  lda #%11111111 ; Set all pins on port B to output
  sta DDRB
  lda #%00000000 ; Set all pins on port A to input
  sta DDRA
  lda #%11001010
  sta PORTB
loop:
  lda #%11001010
  sta PORTB
  jmp loop


nmi:
irq:
 .org $fffa
 .word nmi
 .word reset
 .word irq