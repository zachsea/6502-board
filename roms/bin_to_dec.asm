; RS coding for destination
PORTA     = $6001
PORTB     = $6000
DIR_PORTA = $6003
DIR_PORTB = $6002

; individual pin values on PORTA for screen
PINA_RS = $20
PINA_RW = $40
PINA_EN = $80

.segment "CODE"

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

  lda #0                  ; marks end of printing
  pha

  lda temp_number         ; print '-' if negative
  bpl skip_neg
  ldx #'-'
  jsr send_lcd_data
  eor #$ff                ; negate
  inc a
skip_neg:
convert_loop:
  tay                     ; get ones place, push resulting char ascii on stack
  jsr mod_10
  adc #'0'
  pha
  tya
  jsr div_10              ; shift to the next unit
  bne convert_loop
print_loop:
  pla                     ; print off the stack to print in correct order
  beq print_loop_end
  tax
  jsr send_lcd_data
  jmp print_loop
print_loop_end:
  jmp spinloop

; parameter a (positive) -> leaves mod result in a
mod_10:
  cmp #10
  bcc mod_10_end
  sbc #10
  jmp mod_10
mod_10_end:
  rts

; parameter a (positive) -> leaves quotient in a
div_10:
  ldx #0                  ; quotient counter
div_10_loop:
  cmp #10
  bcc div_10_end
  sbc #10
  inx
  bne div_10_loop
div_10_end:
  txa                     ; move quotient to a
  rts

; parameter x -> inst
send_lcd_inst:
  pha                     ; save used registers
  jsr busy_check
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
send_lcd_data:
  pha                       ; save used registers
  jsr busy_check
  lda #0                    ; clear control bits
  sta PORTA
  stx PORTB                 ; use data in x
  lda #(PINA_EN | PINA_RS)  ; pulse write
  sta PORTA
  lda #0                    ; re-clear control bits
  sta PORTA
  pla                       ; restore used registers
  rts

busy_check:
  pha                       ; store used registers
  ; after my own attempt, ben made me realize it's better to have RW set first before pulsing!
  lda #(PINA_RW)
  lda #(PINA_EN | PINA_RW)  ; put busy flag onto bus
  sta PORTA
  lda #%01111111            ; set DB7 to take input
  sta DIR_PORTB
while_busy:
  lda PORTB
  asl                       ; shift DB7 into carry, 1 -> busy
  bcs while_busy
  lda #0                    ; clear control bits
  sta PORTA
  lda #$ff                  ; reset LCD data pins to out
  sta DIR_PORTB
  pla                       ; restore used registers
  rts

spinloop:
  nop
  jmp spinloop

temp_number: .word %10101010

.segment "VECTORS"
.word $0000   ; NMI
.word reset   ; reset
.word $0000   ; IRQ
