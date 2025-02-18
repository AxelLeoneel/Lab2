;
; borradorinho.asm
;
; Created: 14/02/2025 14:25:46
; Author : axell
;

// ATMEGA328P
.include "M328PDEF.inc"
.cseg
.org 0x0000

RJMP SETUP

// Declaracion tablita como valores posibles de display, de 0 a F
//tablita:	.db		0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF // Prueba todos encendidos o apagados
tablita:	.db		0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90, 0x88, 0x83, 0xA7, 0xA1, 0x86, 0x8E

// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16

SETUP:
// Definicion de Puertos de entrada y salida

    // Configuracion Puerto Salida C
	LDI     R16, 0xFF
    OUT     DDRC, R16   // PD0-PD7 OUT (leds)
    LDI     R16, 0x00
    OUT     PORTC, R16	// PD0-PD7 LOW

	// Configuracion Puerto Entrada B
    LDI     R16, 0x00
    OUT     DDRB, R16   // PB0-PB7 IN (pushbuttons)
    LDI     R16, 0xFF
    OUT     PORTB, R16	// PB0-PB7 Pull-ups (habilitados)
	NOP

	// Configuracion Puerto Salida D
    LDI     R16, 0xFF
    OUT     DDRD, R16	// PD0-PD7 OUT (leds)
    LDI     R16, 0x00
    OUT     PORTD, R16	// PD0-PD7 LOW

// Apagar leds TX y RX
    LDI     R16, 0x00
    STS     UCSR0B, R16	// Deshabilitar serial
	NOP
	NOP

// Cargar 0xFF a R16 y R17
	LDI		R16, 0xFF
	LDI		R17, 0xFF

// Contador en cero
	LDI		R19, 0x00

// Guardamos los 8 bits bajos de tablita en ZL, los 8 bits altos en ZH
// Se multiplica por dos para usar la direccion en bytes ... ok?
	LDI		ZL, LOW(tablita << 1)
	LDI		ZH, HIGH(tablita << 1)

MAIN_LOOP:
// Analisis estado de pushbuttons
    IN      R16, PINB	// Cargar PINB a R16
    CP      R17, R16	// Comparar R17 y R16
    BREQ    MAIN_LOOP	// Va a Main Loop si R16 y R17 son iguales (detecta cambios)
    CALL    DELAY	
	// ANTIREBOTE
    IN      R16, PINB   // Leer botones
    CP      R17, R16	
    BREQ    MAIN_LOOP		// Saltar si sigue leyendo 0

	MOV     R17, R16    // Nuevo estado botones
	
	SBRS	R16, 0		// Boton incremento (PB0)
	CALL	INCREMENTO
	SBRS	R16, 1		// Boton decremento (PB1)
	CALL	DECREMENTO

	RJMP    MAIN_LOOP	// Repetir LOOP

INCREMENTO:
// Sumar contador
	INC		R19		// Incrementar R19 (sumar uno)
	CPI		R19, 0b00010000		// Si R19 supera 0x0F entonces volver a 0
	BREQ	CERO		
	
	OUT		PORTC, R19		// Muestra contador en leds PORTC

	ADIW	ZL, 1	// Pasa a siguiente digito en la tabla
	LPM		R20, Z			// Cargar desde memoria de programa
	OUT		PORTD, R20		// Mostrar leds en display
	
	RET	

DECREMENTO:
// Restar contador
	DEC		R19		// Decrementar R19 (restar uno)
	OUT		PORTC, R19		// Muestra contador en leds PORTC

	SBIW	ZL, 1			// Retroceder al elemento anterior en la tabla
	LPM		R20, Z			// Cargar desde memoria de programa
	OUT		PORTD, R20		

	RET	

CERO:
// Volver a cero el contador
	LDI		R19, 0x00
	OUT		PORTC, R19

	LDI		ZL, LOW(tablita << 1)	// Resetear puntero Z a la dirección base
	LDI		ZH, HIGH(tablita << 1)
	LPM		R20, Z			// Cargar el valor de '0'
	OUT		PORTD, R20		

	RET

DELAY:
// Funciona a base de tres overflow de 255
	LDI R18, 0
SUBDELAY1:
	INC R18
	CPI R18, 0
	BRNE SUBDELAY1	//Va a SUBDELAY1 si son diferentes
	LDI R18, 0
SUBDELAY2:
	INC R18
	CPI R18, 0
	BRNE SUBDELAY2	//Va a SUBDELAY2 si son diferentes
	LDI R18, 0
SUBDELAY3:
	INC R18
	CPI R18, 0
	BRNE SUBDELAY3	//Va a SUBDELAY3 si son diferentes
	RET
	//hola