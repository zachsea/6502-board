; RS coding for destination
PORTA     = $6001
PORTB     = $6000
DIR_PORTA = $6003
DIR_PORTB = $6002

; individual pin values on PORTA for screen
PINA_RS = $20
PINA_RW = $40
PINA_EN = $80

  .org $8000

reset:
  ; default pins to output
  lda #$ff
  sta DIR_PORTA
  sta DIR_PORTB

; resets screen
init:
  ; ensure no control bits set
  lda #0
  sta PORTA
  ; clear display
  lda #%00000001
  sta PORTB
  ; pulse write
  lda #PINA_EN
  sta PORTA
  lda #0
  sta PORTA
  ; function set
  lda #%00110000
  sta PORTB
  ; pulse write
  lda #PINA_EN
  sta PORTA
  lda #0
  sta PORTA
  ; display off
  lda #%00001000
  sta PORTB
  ; pulse write
  lda #PINA_EN
  sta PORTA
  lda #0
  sta PORTA
  ; entry mode
  lda #%00000110
  sta PORTB
  ; pulse write
  lda #PINA_EN
  sta PORTA
  lda #0
  sta PORTA

ready:
  ; function set
  lda #%00111000
  sta PORTB
  ; pulse write
  lda #PINA_EN
  sta PORTA
  lda #0
  sta PORTA

  ; display control
  lda #%00001111
  sta PORTB
  ; pulse write
  lda #PINA_EN
  sta PORTA
  lda #0
  sta PORTA

  ; write a character
  lda #"R"
  sta PORTB
  ; pulse data write
  lda #(PINA_EN | PINA_RS)
  sta PORTA
  lda #0
  sta PORTA

spinloop:
  nop
  jmp spinloop

  ; reset vector + pad file to 32k
  .org  $fffc
  .word reset
  .word $0000
