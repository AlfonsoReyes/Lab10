; Print.s
; Student names: change this to your names or look very silly
; Last modification date: change this to the last modification date or look very silly
; Runs on LM4F120 or TM4C123
; EE319K lab 7 device driver for any LCD
;
; As part of Lab 7, students need to implement these LCD_OutDec and LCD_OutFix
; This driver assumes two low-level LCD functions
; ST7735_OutChar   outputs a single 8-bit ASCII character
; ST7735_OutString outputs a null-terminated string 

num					EQU   0


    IMPORT   ST7735_OutChar
    IMPORT   ST7735_OutString
    EXPORT   LCD_OutDec
    EXPORT   LCD_OutFix

    AREA    |.text|, CODE, READONLY, ALIGN=2
		PRESERVE8 
    THUMB

 

;-----------------------LCD_OutDec-----------------------
; Output a 32-bit number in unsigned decimal format
; Input: R0 (call by value) 32-bit unsigned number
; Output: none
; Invariables: This function must not permanently modify registers R4 to R11
LCD_OutDec
	PUSH {R4,R5,R6,R7,R8,LR}
	
	MOVS R5,#10
	SUB SP,SP,#40	;allocate space for 10 values on stack
	
	MOV R6,#0
	STR R6,[SP,#num]	;num = 0
	MOV R3,#0x00

;loop1
;divide input by 10 and store remainder in stack every iteration of loop1
loop1
	;LDR R3,[SP,#num]	R3 = n
	LSL R4,R3,#2	;R4 = R3 * 4
	UDIV R1,R0,R5	; R1 = R0/10
	MUL R1,R1,R5	; R1 = R1*10 (right-most first digit is 0)
	SUB R2,R0,R1	;R2 has remainder : R2 = R0 - R1: R2 = R0%10
	UDIV R1,R1,R5	; R1 = R1/10
	MOV R0,R1		;R0 = R1
	ADD R2,#48		;add 48 to digit to get ASCII char value of digit
	STRB R2,[SP,R4]	;store single digit R2 in SP + R4 stack
	;STRB R2,[SP,#num]
	ADD R3,R3,#1
	;STR R3,[SP,#n]		;n = n + 1
	CMP R3,#10
	BLT loop1
	
	MOV R6,#0
	MOV R7,#0		;R7 = 0, no non-zero integer reached yet, keep checking for zeros
					;R7 = 1, have reached non-zero integer, skip checking for zeros
	MOV R8,#1		;keep track of how many non-significant zeros there are in stack, 1 is default	
	
	;loop2
	;print out SIGNIFICANT digits only
	;print out digits of input starting from leftmost significant digit to right -->>>>
loop2
	;LDR R4,[SP,#num]	;R4 = n
	;LSL R4,R4,#2		;R4 = n*4
	;LDRB R0,[SP,R4]	;R0 = [SP+(4*n)]
	LDRB R0,[SP,R4]	;load single digit value from stack
	CMP R4,#0		;are you in first digit of stack? make sure first digit always printed out.
	BEQ no_check	;if on first digit (last iteration), make sure it's ALWAYS printed out, even if all 0's.
	CMP R7,#1
	BEQ no_check	;move to no_check if non-zero int already encountered
	CMP R0,#48
	BNE not_zero	;move to not_zero if non-zero int reached	
	ADD R8,R8,#1	;increment R8 by 1, means non-sig zero on SP
	BL no_print		;if on non-significant zero value, do not print anything, will print null space later.
not_zero
	MOV R7,#1
no_check
	BL ST7735_OutChar
no_print
	SUB R4,R4,#4	;decrement stack to location of next value
	;STR R4,[SP,#num] 	;num = num - 4
	ADD R6,R6,#1
	CMP R6,#10
	BLT loop2

;null print will print AT LEAST one null space
;each non-significant zero from input means another null space printed out
null_print
	MOV R0,#0x00
	BL ST7735_OutChar
	SUBS R8,R8,#1
	CMP R8,#0
	BHI null_print
		
	ADD SP,SP,#40		;reallocate stack
	
	POP {R4,R5,R6,R7,R8,LR}
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

	PUSH {R4,R5,R6,LR}

;ASCII values of * (42), . (46), 0 (48)
	MOV R6,#9999
	CMP R0,R6
	BHI stars	;is R0 > 9999? if so, skip stuff and go to 'done'. do not ccllect $200.

	MOVS R5,#10
	SUB SP,SP,#16		;SP = SP-16, allocate space for 4 values on stack	
	MOVS R3,#0x00
			
	;get first 4 digits of R0 and store in stack
loop3	
	LSL R4,R3,#2	;R4 = R3 * 4
	UDIV R1,R0,R5	; R1 = R0/10
	MUL R1,R1,R5	; R1 = R1*10 (right-most first digit is 0)
	SUB R2,R0,R1	;R2 has remainder : R2 = R0 - R1: R2 = R0%10
	UDIV R1,R1,R5	; R1 = R1/10
	MOV R0,R1		;R0 = R1
	ADDS R2,#48		;add 48 to digit to get ASCII char value of digit
	STR R2,[SP,R4]
	ADD R3,R3,#1
	CMP R3,#4
	BLT loop3
	
	;print out  4th, '.', 3rd, 2nd, 1st digits
	LDRB R0,[SP,R4]
	BL ST7735_OutChar
	SUB R4,R4,#4
	
	MOV R0,#0x2E
	BL ST7735_OutChar
	
	LDRB R0,[SP,R4]
	BL ST7735_OutChar
	SUB R4,R4,#4
	
	LDRB R0,[SP,R4]
	BL ST7735_OutChar
	SUB R4,R4,#4
	
	LDRB R0,[SP,R4]
	BL ST7735_OutChar

	ADD SP,SP,#16		;reallocate stack

	BL done
	
	;print out '*.****' if R0 > 9999.
stars
	MOV R0,#0x2A
	BL ST7735_OutChar
	MOV R0,#0x2E
	BL ST7735_OutChar
	MOV R0,#0x2A
	BL ST7735_OutChar
	MOV R0,#0x2A
	BL ST7735_OutChar
	MOV R0,#0x2A
	BL ST7735_OutChar
	
	BL done
	
done
	
	;move to next line
	MOV R0,#0x0A
	BL ST7735_OutChar
	
	POP {R4,R5,R6,LR}

    BX LR
 
   
;* * * * * * * * End of LCD_OutFix * * * * * * * *

     ALIGN                           ; make sure the end of this section is aligned
     END                             ; end of file
