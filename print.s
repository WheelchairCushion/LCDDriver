; print.s
; Student names: change this to your names or look very silly
; Last modification date: change this to the last modification date or look very silly
; Runs on LM4F120 or TM4C123
; EE319K lab 7 device driver for the Kentec EB-LM4F120-L35
;
; As part of Lab 7, students need to implement these two functions

;  Data pin assignments:
;  PB0-7   LCD parallel data input
;
;  Control pin assignments:
;  PA4     RD  Read control signal             -------------------------
;  PA5     WR  Write control signal            | PA7 | PA6 | PA5 | PA4 |
;  PA6     RS  Register/Data select signal     | CS  | RS  | WR  | RD  |
;  PA7     CS  Chip select signal              -------------------------
;
;  Touchpad pin assignments:
;  PA2     Y-                                  -------------  -------------
;  PA3     X-                                  | PA3 | PA2 |  | PE5 | PE4 |
;  PE4     X+    AIN9                          | X-  | Y-  |  | Y+  | X+  |
;  PE5     Y+    AIN8                          -------------  -------------

    IMPORT   LCD_OutChar
    IMPORT   LCD_Goto
    IMPORT   LCD_OutString
    EXPORT   LCD_OutDec
    EXPORT   LCD_OutFix

    AREA    |.text|, CODE, READONLY, ALIGN=2
    THUMB
    ALIGN          

MAX				EQU 10000
THOUSAND        EQU 1000
fin		        EQU 0xFFFFFFFF
;-----------------------LCD_OutDec-----------------------
; Output a 32-bit number in unsigned decimal format
; Input: R0 (call by value) 32-bit unsigned number 
; Output: none
; Invariables: This function must not permanently modify registers R4 to R11
LCD_OutDec	
	PUSH {R4,R5,R6,LR}  ; save registers
	MOV R5, #10
	MOV R2, #10         ; divisor in mod function
	MOV R3, #0x00		; number of digits counter	
	MOV R1, R0          ; save the value of R0 (input)
Reinit
	MOV R0, R1
NumDiv
	CMP R0, R2       
	BLO AsciiConv
	SUB R0, R0, R2  	; divide R1 by multiples of 10 to find modulo
	B NumDiv
AsciiConv
	UDIV R4, R2, R5 	; R4 = R2/10, R4 is divisor of R0  
	UDIV R0, R0, R4
	ADD R0, R0, #0x30   ; make R0 into ASCII character 
	PUSH {R0}
	ADD R3, R3, #1      ; increment counter 
	MOV R0, R1
	UDIV R0, R0, R2     ; check if it is necessary to continue separating R0
	CMP R0, #0
	BEQ Output
	MUL R2, R2, R5
	LDR R6, =fin
	SUB R6,R6,R1       ; check for final input  
	CMP R6, #0
	BEQ Incase
	B Reinit
Output
	CMP R3, #0x00      ; decrementing counter 
	BEQ Done
	POP	 {R0}
	PUSH {R3}          ; save value before going to new subroutine 
	BL LCD_OutChar
	POP {R3}
	SUB R3, R3, #0x01
	B Output
Incase
	CMP R3, #9         ; check if digits has been reached 
	BEQ Pop4
	B Reinit
Pop4 MOV R0,#4
	ADD R0, R0, #0x30
	PUSH {R0}
	ADD R3,R3,#1
	B Output
Done
	POP {R4,R5,R6,PC} ; restore saved registers 
	BX  LR
;* * * * * * * * End of LCD_OutDec * * * * * * * * 

; -----------------------LCD _OutFix----------------------
; Output characters to LCD display in fixed-point format
; unsigned decimal, resolution 0.001, range 0.000 to 9.999 
; Inputs:  R0 is an unsigned 32-bit number
; Outputs: none
; E.g., R0=0,    then output "0.000 " 
;       R0=3,    then output "0.003 " 
;       R0=89,   then output "0.089 " 
;       R0=123,  then output "0.123 " 
;       R0=9999, then output "9.999 " 
;       R0>9999, then output "*.*** "
; Invariables: This function must not permanently modify registers R4 to R11
LCD_OutFix
    PUSH {R4,R5,R6,R7,LR}
	MOV R1, R0			
	MOV R5, #10 
	MOV R6, #100
	LDR R3, =MAX
	SUBS R4, R0, R3        ; check if R0>9999
	BPL Error
	LDR R7, =fin
	SUB R7, R7, R0
	CMP R7, #0
	BEQ Error                 
	MOV R2, #10
	BL Mod              ; Mod = R0%R2 
	ADD R0, R0, #0x30   ; make number into ASCII character
	PUSH {R0}           
	MOV R0, R1
	MOV R2, #100
	BL Mod
	UDIV R0,R0,R5       ; Hundredth's Digit = (R0%100)/10          
	ADD R0, R0, #0x30    
	PUSH {R0}
	MOV R0,R1
	LDR R2, =THOUSAND
	BL Mod
	UDIV R0,R0,R6       ; Tenths's Digit = (R0%1000)/100 
	ADD R0, R0, #0x30  
	PUSH {R0}
	MOV R0, #0x2E       ; ASCII for '.'
	PUSH {R0}           
	MOV R0,R1
	UDIV R0, R0, R2     ; One's Digit = (R0/1000) 
	ADD R0, R0, #0x30   
	PUSH {R0}
	MOV R2, #5
FixedDisplay CMP R2, #0
	BEQ PopStack
	POP  {R0}
	PUSH {R2}
	BL LCD_OutChar
	POP  {R2}
	SUB R2, #1
	B FixedDisplay
Error               ; subroutine to display "*.***"
	MOV R3, #3      ; counter
	MOV R0, #0x2A	; ASCII for '*'
	PUSH {R3}
	BL LCD_OutChar
	POP {R3}
	MOV R0, #0x2E	; ASCII for '.'
	PUSH {R3}
	BL LCD_OutChar
	POP {R3}
Repeat
	CMP R3, #0
	BEQ PopStack
	MOV R0, #0x2A
	PUSH {R3}
	BL LCD_OutChar
	POP {R3}
	SUB R3,R3, #1
	B Repeat	
PopStack
	POP {R4,R5,R6,R7,PC}
    BX  LR
Mod                   ; performs R0%R2, outputs on R0
	CMP R0, R2
	BLT Finish
	SUB R0, R0, R2
	B Mod
Finish 	
	BX LR

;* * * * * * * * End of LCD_OutFix * * * * * * * * 

   
    ALIGN                           ; make sure the end of this section is aligned
    PRESERVE8                       ; fix for PRES8 
	END                             ; end of file
    