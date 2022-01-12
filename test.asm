    SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
    DEVICE ZXSPECTRUM128

    include "consts.asm"


stack_top               EQU 0x8100
Code_Start              EQU 0x8100

    MACRO BORDERCOLOR color
    ld a, color
    ld c, 254
    out (c), a
    ENDM

    org Code_Start
    di
    ld sp, stack_top
    ei

    ;call DrawLine ; 6760
    ;call DrawLine2 ; 22949

    ; Switch memory 0xC000..0xFFFF to RAM7 - second screen bank
    ld bc, 32765
    ld a, %00010111
    out (c), a

    ; clear pixels on second screen
    xor a
    ld (SecScreenStart), a
    ld hl, SecScreenStart
    ld de, SecScreenStart+1
    ld bc, ScreenLen
    ldir

    ; clear attributes on second screen
    ld a, %00111000
    ld (SecAttrStart), a
    ld hl, SecAttrStart
    ld de, SecAttrStart+1
    ld bc, AttrLen
    ldir

Loop:
    halt

    BORDERCOLOR BLACK
    ld a, 2
    call ROM_OPEN_CHANNEL
    call PrintFrames ; 10372

    BORDERCOLOR BLUE
    call PrintLastKey ; 19301

    BORDERCOLOR RED
    call PrintMouseCoords ; 10374

    BORDERCOLOR MAGENTA
    call DrawCursor

    BORDERCOLOR GREEN
    call ProcessKeyboard

    BORDERCOLOR CYAN
    call DrawLine ; 6760

    BORDERCOLOR YELLOW
    jr Loop

; Drawing vertical line from top to bottom screen
DrawLine:
    ;ld a, 0x80  ; draw first pixel in cell row
    ld hl, ScreenStart ; start cell address
    ld b, 3     ; blocks count
DrawBlock:
    push bc
    push hl
    ld b, 8     ; rows count
DrawRow:
    push bc
    push hl
    ld b, 8     ; cell height
DrawPixelCell:
    ld a, (hl) ; Invert first bit
    xor 0x80
    ld (hl), a
    inc h
    djnz DrawPixelCell
    ; Next row
    pop hl
    ld bc, 0x0020 ; next row offset
    add hl, bc
    pop bc
    djnz DrawRow
    ; Next block
    pop hl
    ld bc, 0x0800 ; next block offset
    add hl, bc
    pop bc
    djnz DrawBlock
    ret

; Pixel address:
; 15| 14| 13| 12| 11| 10| 9 | 8 || 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0
; 0   1   0   y7  y6  y2  y1  y0 | y5  y4  y3  x4  x3  x2  x1  x0
DrawLine2:
    ld b, 191   ; lines count
DrawLine2Next:
    push bc
    ld a, b
    and %00000111
    or %01000000
    ld h, a
    ld a, b
    .3 rra
    and %00011000
    or h
    ld h, a

    ld a, b
    .2 rla
    and %11100000
    ld l, a

    ld (hl), 0x80

    pop  bc
    djnz DrawLine2Next

    ret


PrintFrames:
    ; Get frame counter
    ld hl, (0x5C78)
    ld a, h
    call NumToHex
    ld (CoordsStr+3), de
    ld a, l
    call NumToHex
    ld (CoordsStr+6), de

    ; Text coords
    ld de, #0001
    ld (CoordsStr+1), de

    ; Printing
    ld de, CoordsStr
    ld bc, CoordsStrLen
    call ROM_PRINT
    ret

PrintLastKey:
    ld a, (0x5C08) ; Get last key
    ld (LastKeyCodeStr+13), a

    ; Printing
    ld de, LastKeyCodeStr
    ld bc, LastKeyCodeStrLen
    call ROM_PRINT
    ret

; Includes ProcessKeyboard
PrintKeyboard:
    ld de, #0003 ; Text coords
    ld (NumStr+1), de
    
    ld bc, 32766
    in a, (c)
    call NumToHex
    ld (NumStr+3), de
    
    ld de, NumStr ; Printing
    ld bc, NumStrLen
    call ROM_PRINT
    
ProcessKeyboard:
    ld bc, 32766
    in a, (c)
    and 0xbf ; ZEsarUX support
    cp 0xbe ; Spacebar
    jr z, SpacePressed
    xor a
    ld (SpaceIsPressed), a
    ret

SpacePressed:
    ld a, (SpaceIsPressed)
    or a
    ret nz

    ld a, 1
    ld (SpaceIsPressed), a
    ld bc, 32765
    ld a, (RamMode)
    xor %00001000
    ld (RamMode), a
    out (c), a
    ret

SpaceIsPressed:
    db 0
RamMode:
    db %00010111

PrintMouseCoords:
    ld bc, 0xfbdf ; get mouse X
    in a, (c)
    call NumToHex
    ld (CoordsStr+3), de

    ld b, 0xff ; get mouse Y
    in a, (c)
    call NumToHex
    ld (CoordsStr+6), de

    ; Text coords
    ld de, #0000
    ld (CoordsStr+1), de

    ; Printing
    ld de, CoordsStr
    ld bc, CoordsStrLen
    call ROM_PRINT
    ret

CoordsStr:
    db AT,0,0,"00:00"
CoordsStrLen:  EQU $ - CoordsStr

LastKeyCodeStr:
    db AT,2,0,"Last key: x"
LastKeyCodeStrLen:  EQU $ - LastKeyCodeStr

NumStr:
    db AT,0,0,"00"
NumStrLen:  EQU $ - NumStr

; a - input number
; de - output chars
NumToHex:
    push af ; save a
    and 0x0f
    call HexChar
    ld d, a ; save result
    pop af  ; return original a value
    .4 rrca    ; Shift value to get high oct
    and 0x0f
    call HexChar
    ld e, a ; save result
    ret

; Convert a lower 4bit to hex letter
HexChar:
    cp 10
    jr c, Hex0 ; a < 10 ? return digit
    add 'A'-10
    ret
Hex0:
    add '0'
    ret

; Drawing line on border
; a line color
; d background color
DrawBorderLine:
    ld c, 254
    out (c), a
    ld b, 5
Delay1:
    djnz Delay1
    out (c), d
    ret

DrawCursor:
    ; calculating coords
    ; cell addr = 0x4000 + bn*0x0800 + ln*0x20  +  rn*0x100 + cx
    ;           = 0x4000 + bn << 11  + ln << 5  +  rn << 8  + cx
    ;           = 0x4000 + (cy & 0x18) << 8  + (cy & 7) << 5  +  rn << 8  + cx
    ; cy = y / 8 = y >> 3
    ; bn = cy / 8 = cy >> 3
    ; ln = cy % 8 = cy & 7
    ; rn = y % 8 = y & 7
    ; cx = x / 8
    ld bc, ScreenStart ; bc - cell addr
    ld a, (CursorY)
    .3 rra   ; a = cy = y / 8 = y >> 3
    ld e, a  ; e = cy
    and 0x18 ; a = cy & 0x18
    or b
    ld b, a  ; cell addr = 0x4000 + bn << 11
    ld a, e  ; a = cy
    and 7
    .5 rla   ; a = (cy & 7) << 5
    add a, c
    ld c, a
    jr nc, DrawCursor1
    inc b
DrawCursor1:
    ; bc = cell addr = 0x4000 + bn << 11 + ln << 5
    ; calc x
    ld a, (CursorX)  ; a = x
    .3 rra           ; a = cx = x / 8 = x >> 3
    add c
    ld c, a
    jr nc, DrawCursor2
    inc b
DrawCursor2:
    ; bc = cell addr = 0x4000 + bn << 11 + ln << 5 + cx

    ld de, bc
    ld b, 8
    ld hl, CursorImg
DrawCursorRow:
    ld a, (hl)
    ld (de), a
    inc d
    inc hl
    djnz DrawCursorRow
    ret

CursorX: db 16*8
CursorY: db 10*8
CursorImg:
    dg 1-------
    dg 11------
    dg 1-1-----
    dg 11-1----
    dg 111-1---
    dg 111111--
    dg 1-11----
    dg 11------

    SAVESNA "test.sna", Code_Start
