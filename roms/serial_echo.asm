.define CR $0D
.define LF $0A
; VIA destination
PORTA     = $6001
PORTB     = $6000
DIR_PORTA = $6003
DIR_PORTB = $6002

; individual pin values on PORTA for screen
PINA_RS = $20
PINA_RW = $40
PINA_EN = $80

; ACIA destination
UART_DATA = $5000
UART_STAT = $5001
UART_COMM = $5002
UART_CTRL = $5003

; status register constants
UART_STAT_RDRF = $08      ; RX reg full
UART_STAT_TDRE = $10      ; TX reg empty

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

  lda #$00
  sta UART_STAT           ; soft reset

  lda #%00011111          ; N-8-1 (8 data, 1 stop) @ 19200
  sta UART_CTRL

  lda #%00001011          ; no parity, no echo, no interrupts
  sta UART_COMM

connected:
  ldy #0
connected_send_msg:
  ldx connected_message,y
  beq connected_send_msg_done
  jsr send_uart_char
  iny
  jmp connected_send_msg
connected_send_msg_done:

rx_wait:
  lda UART_STAT
  and #UART_STAT_RDRF     ; rx buffer flag check
  beq rx_wait
  ldx UART_DATA
  jsr send_lcd_data
  jsr send_uart_char
  jmp rx_wait

; parameter x -> char
send_uart_char:
  pha
  jsr tx_delay
  stx UART_DATA
tx_wait:
  lda UART_STAT
  and #UART_STAT_TDRE
  beq tx_wait             ; loop until tx is not empty
  jsr tx_delay            ; hardware bug :(
  pla
  rts

tx_delay:
  phx
  ldx #200                ; theoretically ~1040 cycles @ 2mhz needed for 520us, more in reality
tx_delay_1:
  dex
  bne tx_delay_1
  plx
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

connected_message: .byte "[CONNECTED]", CR, LF, $00

.segment "VECTORS"
.word $0000   ; NMI
.word reset   ; reset
.word $0000   ; IRQ
