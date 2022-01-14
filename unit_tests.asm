    include "unit_tests.inc"

    ORG 0x5CCB
    UNITTEST_INITIALIZE
    ret

    MODULE TestSuite_Test1

UT_Test1: ; Shift 2 pixels right with overflow
    or a
    ld a, 0x01 ; new coord
    ld b, 0xff ; prev coord
    sub b
    nop ; ASSERTION a == 0

    TC_END

    ENDMODULE