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
  ldx #$ff                ; set sp and default ports to output
  txs
  stx DIR_PORTA
  stx DIR_PORTB

; resets screen
init:
  ldx #%00000001          ; clear display
  jsr send_lcd_inst

  ldx #%00110000          ; function set
  jsr send_lcd_inst

  ldx #%00001000          ; display off
  jsr send_lcd_inst

  ldx #%00000110          ; entry mode
  jsr send_lcd_inst

ready:
  ldx #%00111000          ; function set
  jsr send_lcd_inst

  ldx #%00001111          ; display control
  jsr send_lcd_inst

  ldx #"h"
  jsr send_lcd_data
  ldx #"e"
  jsr send_lcd_data
  ldx #"l"
  jsr send_lcd_data
  ldx #"l"
  jsr send_lcd_data
  ldx #"o"
  jsr send_lcd_data
  ldx #"!"
  jsr send_lcd_data
  ldx #"!"
  jsr send_lcd_data
  ldx #"!"

  jmp spinloop

; parameter x -> inst
send_lcd_inst:
  pha                     ; save used registers
  lda #0                  ; clear control bits
  sta PORTA
  stx PORTB               ; use instruction in x
  lda #PINA_EN            ; pulse write
  sta PORTA
  lda #0                  ; re-clear control bits
  sta PORTA
  pla                     ; restore used registers
  rts

; parameter x -> data
send_lcd_data
  pha                       ; save used registers
  lda #0                    ; clear control bits
  sta PORTA
  stx PORTB                 ; use data in x
  lda #(PINA_EN | PINA_RS)  ; pulse write
  sta PORTA
  lda #0                    ; re-clear control bits
  sta PORTA
  pla                       ; restore used registers
  rts

spinloop:
  nop
  jmp spinloop

  ; reset vector + pad file to 32k
  .org  $fffc
  .word reset
  .word $0000
