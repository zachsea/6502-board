  .org $8000

reset:
  lda #$ff
  sta $6002

start:
  lda #$01
loop:
  sta $6000
  asl
  beq start
  jmp loop

  ; reset vector + pad file to 32k
  .org $fffc
  .word reset
  .word $0000
