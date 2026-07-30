.segment "KERNEL"

.include "graphic.s"
.include "math.s"
.include "memory.s"
.include "misc.s"
.include "stdio.s"
.include "string.s"
.include "time.s"
.include "interrupt.s"

.segment "VECTOR"
    .word NMI
    .word RESET
    .word IRQ