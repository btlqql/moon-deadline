.syntax unified
.cpu cortex-m3
.thumb
.global SVC_Handler
.type SVC_Handler,%function
.thumb_func
SVC_Handler:
  cpsid i
  bl port_first
  ldmia r0!,{r4-r11}
  msr psp,r0
  movs r0,#2
  msr control,r0
  isb
  ldr lr,=0xfffffffd
  cpsie i
  bx lr
.size SVC_Handler,.-SVC_Handler

.global PendSV_Handler
.type PendSV_Handler,%function
.thumb_func
PendSV_Handler:
  cpsid i
  mrs r0,psp
  stmdb r0!,{r4-r11}
  push {r3,lr}
  bl port_switch
  pop {r3,lr}
  ldmia r0!,{r4-r11}
  msr psp,r0
  cpsie i
  bx lr
.size PendSV_Handler,.-PendSV_Handler

// Instrumentation: all eight callee-saved registers must survive hardware
// interrupts and context switches while the task never calls yield/sleep.
.global port_canary
.type port_canary,%function
.thumb_func
port_canary:
  push {r4-r11,lr}
  sub sp,sp,#4
  movs r4,#44
  movs r5,#55
  movs r6,#66
  movs r7,#77
  movs r8,#88
  movs r9,#99
  movs r10,#110
  movs r11,#121
  ldr r1,=port_ticks
1:
  ldr r2,[r1]
  cmp r2,r0
  blo 1b
  cmp r4,#44
  bne 2f
  cmp r5,#55
  bne 2f
  cmp r6,#66
  bne 2f
  cmp r7,#77
  bne 2f
  cmp r8,#88
  bne 2f
  cmp r9,#99
  bne 2f
  cmp r10,#110
  bne 2f
  cmp r11,#121
  bne 2f
  movs r0,#1
  b 3f
2:
  movs r0,#0
3:
  add sp,sp,#4
  pop {r4-r11,pc}
.size port_canary,.-port_canary
