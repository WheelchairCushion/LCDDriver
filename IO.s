; IO.s
; Student names: change this to your names or look very silly
; Last modification date: change this to the last modification date or look very silly

; Runs on LM4F120 or TM4C123
; EE319K lab 7 device driver for the switch and LED
; You are allowed to use any switch and any LED, 
; although the Lab suggests the SW1 switch PF4 and Red LED PF1

; As part of Lab 7, students need to implement these three functions

;  This example accompanies the book
;  "Embedded Systems: Introduction to ARM Cortex M Microcontrollers"
;  ISBN: 978-1469998749, Jonathan Valvano, copyright (c) 2013
;
;Copyright 2013 by Jonathan W. Valvano, valvano@mail.utexas.edu
;   You may use, edit, run or distribute this file
;   as long as the above copyright notice remains
;THIS SOFTWARE IS PROVIDED "AS IS".  NO WARRANTIES, WHETHER EXPRESS, IMPLIED
;OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
;MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE.
;VALVANO SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL,
;OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
;For more information about my classes, my research, and my books, see
;http://users.ece.utexas.edu/~valvano/

; negative logic SW2 connected to PF0 on the Launchpad
; red LED connected to PF1 on the Launchpad
; blue LED connected to PF2 on the Launchpad
; green LED connected to PF3 on the Launchpad
; negative logic SW1 connected to PF4 on the Launchpad

        EXPORT   IO_Init
        EXPORT   IO_Touch
        EXPORT   IO_HeartBeat

GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
GPIO_PORTF_AMSEL_R EQU 0x40025528
GPIO_PORTF_PCTL_R  EQU 0x4002552C
GPIO_LOCK_KEY      EQU 0x4C4F434B  ; Unlocks the GPIO_CR register

SYSCTL_RCGC2_R     EQU 0x400FE108

        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB

;------------IO_Init------------
; Initialize GPIO Port for a switch and an LED
; Input: none
; Output: none
; Invariables: This function must not permanently modify registers R4 to R11
IO_Init ;SW1 switch PF4 and Red LED PF1
	LDR R1, =SYSCTL_RCGC2_R       ; activate clock
	LDR R0, [R1]
	ORR R0, R0, #0x20
	STR R0, [R1]
	NOP
	NOP
	LDR R1, =GPIO_PORTF_LOCK_R     ; unlock the lock register
	LDR R0, =0x4C4F434B
	STR R0, [R1]
	LDR R1, =GPIO_PORTF_CR_R      ; enable commit for Port F
	MOV R0, #0xFF                 ; 1 means allow access
	STR R0,[R1]
	LDR R1, =GPIO_PORTF_AMSEL_R   ; disable analog
	MOV R0, #0
	STR R0, [R1]
	LDR R1, =GPIO_PORTF_PCTL_R
	MOV R0, #0x00000000           ; configure Port F as GPIO
	STR R0, [R1]
	LDR R1, =GPIO_PORTF_DIR_R
	MOV R0, #0x02                 ; PF1 output, PF4 input
	LDR R1, =GPIO_PORTF_AFSEL_R   ; disable alternate function
	MOV R0, #0
	STR R0, [R1]
	LDR R1, =GPIO_PORTF_PUR_R     ; enable resistors for PF1 and PF4
	MOV R0, #0x12
	STR R0, [R1]
	LDR R1, =GPIO_PORTF_DEN_R     ; enable digital port
	MOV R0, #0xFF
    STR R0, [R1] 
    BX  LR      
;* * * * * * * * End of IO_Init * * * * * * * * 

;------------IO_HeartBeat------------
; Toggle the output state of the  LED on PF1
; Input: none
; Output: none
; Invariables: This function must not permanently modify registers R4 to R11
IO_HeartBeat
	LDR R1, =GPIO_PORTF_DATA_R
	LDR R3, [R1]
	AND R2, R3, #0x02             ; check status of LED
	CMP R2, #0x02
	BNE TurnOn
	AND R3, #0xFD                 ; turn off LED
	STR R3, [R1]
	B Done
TurnOn ORR R3, #0x02
	 STR R3, [R1]
Done BX  LR

;* * * * * * * * End of IO_HeartBeat * * * * * * * * 

;------------IO_Touch------------
; wait for release and touch of the switch
; Input: none
; Output: none
; This is a public function
; Invariables: This function must not permanently modify registers R4 to R11

; negative logic SW1 connected to PF4 on the Launchpad 
IO_Touch 
    LDR R1, =GPIO_PORTF_DATA_R
	LDR R1, [R1] 
	AND R2, R1, #0x10
	CMP R2, #0x00
	BNE IO_Touch
Release                          
	LDR R1, =GPIO_PORTF_DATA_R
	LDR R1, [R1]
	ADD R2, R1, #0
	AND R2, #0x10		; require release of SW1 (PF4=1) to slow input 
	CMP R2, #0x00
	BEQ Release
	BX  LR      
;* * * * * * * * End of IO_Touch * * * * * * * * 

    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file