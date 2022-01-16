
ReadMouseCoords:
    ld bc, 0xfbdf ; get mouse X
    in a, (c)
    ld hl, PrevMouseX
    ld b, (hl)
    ld (PrevMouseX), a
    ld hl, CursorX
    ld c, (hl)
    call CalcCursorPosX
    ld (CursorX), a

    ld bc, 0xffdf ; get mouse Y
    in a, (c)   ; swap a anb b, for invert shift sign
    ld hl, PrevMouseY
    ld b, (hl)
    ld (PrevMouseY), a
    ld hl, CursorY
    ld c, (hl)
    call CalcCursorPosY
    ld (CursorY), a
    ret

; Calculating cursor position
; a - current mouse value
; b - previous mouse value
; c - current cursor coord
; Result:
; a - new cursor coord
CalcCursorPosX:
    sub b              ;  a = shift. flag C if left
    jr z, CCPX_NoMove  ; curr == prev. return
    cp 0x80
    jr nc, CCPX_Left    ; diff >= 128 ? move left
    add c              ; a = new coord (not limited) = curr coord + shift
    cp c
    ret nc ; return if a >= c (coord not overflowed)
    ld a, 0xff
    ret
CCPX_Left:
    add c              ; a = new coord (not limited) = curr coord + shift
    cp c
    ret c ; return if a < c (coord not overflowed)
    ld a, 0
    ret
CCPX_NoMove:
    ld a, c
    ret

; Calculating cursor position
; a - current mouse value
; b - previous mouse value
; c - current cursor coord
; Result:
; a - new cursor coord
CalcCursorPosY:
    ld d, a ; swap a and b
    ld a, b
    ld b, d
    sub b    ;  a = shift. flag C if left
    jr z, CCPX_NoMove  ; curr == prev. return
    cp 0x80
    jr nc, CCPY_Up    ; diff >= 128 ? move up

    add c
    cp c
    jr c, CCPY_Max ; go to CCPY_Max if a < c and value overflowed
    cp 8*8*3
    ret c
CCPY_Max:
    ld a, 8*8*3-1 ; max y value
    ret
CCPY_Up:
    add c
    cp c
    ret c ; return if a < c
    ld a, 0
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
    jr nc, CalcCursorX
    inc b
CalcCursorX:
    ; bc = cell addr = 0x4000 + bn << 11 + ln << 5
    ; calc x
    ld a, (CursorX)  ; a = x
    .3 rra           ; a = cx = x / 8 = x >> 3
    and 0x1f
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
    ld a, (de)
    ld c, (hl) ; get cursor image row
    xor c
    ld (de), a ; load row into screen memory
    inc d
    inc hl
    djnz DrawCursorRow
    ret

PrevMouseX: db 0
PrevMouseY: db 0

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
