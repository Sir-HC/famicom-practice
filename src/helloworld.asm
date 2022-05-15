.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1

.exportzp player_x, player_y

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  
  ; update tiles after DMA
  JSR update_player
  JSR draw_player
  
  LDA #$00
  STA $2005
  STA $2005
  RTI
.endproc

.import reset_handler

.export main
.proc main
  ; write a palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR
  
  
  LDX #$00
load_palettes:
  LDA palettes, X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palettes
  
  
  ; write sprite data
  LDX #$00
load_sprites:
  LDA sprites, X
  STA SPRITE_BUFFER_START, X ; Y-coord of first sprite
  INX
  CPX #$10
  BNE load_sprites
  
  ; small star 1
  LDX #$2d
  
  LDA PPUSTATUS
  LDA #$20
  STA PPUADDR
  LDA #$48
  STA PPUADDR
  STX PPUDATA
  
  LDA PPUSTATUS
  LDA #$23
  STA PPUADDR
  LDA #$78
  STA PPUADDR
  STX PPUDATA
  
  LDA PPUSTATUS
  LDA #$22
  STA PPUADDR
  LDA #$e4
  STA PPUADDR
  STX PPUDATA
  
  ; small star 2
  LDX #$2e
  
  LDA PPUSTATUS
  LDA #$22
  STA PPUADDR
  LDA #$6f
  STA PPUADDR
  STX PPUDATA
  
  LDA PPUSTATUS
  LDA #$21
  STA PPUADDR
  LDA #$2a
  STA PPUADDR
  STX PPUDATA
  
  
  ; write a nametable
  ; big stars
  LDX #$2f
  
  LDA PPUSTATUS
  LDA #$21
  STA PPUADDR
  LDA #$6b
  STA PPUADDR
  STX PPUDATA
  
  LDA PPUSTATUS
  LDA #$23
  STA PPUADDR
  LDA #$17
  STA PPUADDR
  STX PPUDATA
  
  LDA PPUSTATUS
  LDA #$22
  STA PPUADDR
  LDA #$04
  STA PPUADDR
  STX PPUDATA
  
  
  
  ; attribute table
  LDA PPUSTATUS
  LDA #$23
  STA PPUADDR
  LDA #$d2
  STA PPUADDR
  LDA #%11000000
  STA PPUDATA
  
  
vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK
  
forever:
  JMP forever
.endproc

.proc update_player
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  LDA player_x
  CMP #$e0
  BCC not_at_right_edge
  LDA #$00
  STA player_dir
  JMP direction_set
  
not_at_right_edge:
  LDA player_x
  CMP #$10
  BCS direction_set
  ; if BCS not taken, we are less than 16
  LDA #$01
  STA player_dir 
  
direction_set:
  LDA player_dir
  CMP #$01
  BEQ move_right
  DEC player_x
  DEC player_x
  JMP exit_subroutine
  
move_right:
  INC player_x
  
exit_subroutine:
  
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_player
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  
  LDA #$05
  STA $0201
  LDA #$06
  STA $0205
  LDA #$07
  STA $0209
  LDA #$08
  STA $020d
  
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e
  
  ; top left
  LDA player_y
  STA $0200
  LDA player_x
  STA $0203
  
  ; top right
  LDA player_y
  STA $0204
  LDA player_x
  CLC
  ADC #$08
  STA $0207
  
  ; bot left
  LDA player_y
  CLC
  ADC #$08
  STA $0208
  LDA player_x
  STA $020b
  
  ; bot right
  LDA player_y
  CLC 
  ADC #$08
  STA $020c
  LDA player_x
  CLC
  ADC #$08
  STA $020f
  
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "starfield.chr"

.segment "RODATA"
palettes:
.byte $0d, $21, $11, $01
.byte $0d, $26, $16, $06
.byte $0d, $20, $10, $00
.byte $0d, $27, $17, $29

.byte $1d, $25, $19, $05
.byte $0d, $38, $19, $06
.byte $0d, $1c, $2d, $21
.byte $0d, $24, $19, $29

sprites:
.byte $70, $05, $01, $80,  $70, $06, $01, $88,  $78, $07, $01, $80,  $78, $08, $01, $88
