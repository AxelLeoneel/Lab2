;
; Prelab2.asm
;
; 11/02/2025
; Author : Axel Leonel González Castillo
;


// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.cseg
.org 0x0000
.def    COUNTER = R20
 /****************************************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
/****************************************/
// Configuracion MCU
SETUP:
    // Configurar Prescaler "Principal"
    LDI     R16, (1 << CLKPCE)	// Se setea el bit 7 del registro de clock (CLKPCE) para habilitar prescalers (ver Datasheet)
    STS     CLKPR, R16          // Habilitar cambio de PRESCALER
    LDI     R16, 0b00000111		// Codigo para prescaler de 128
    STS     CLKPR, R16          // Configurar Prescaler a 128 F_cpu = 125kHz

    // Inicializar timer0
    CALL    INIT_TMR0

    // Configuracion Puerto Salida C
	LDI     R16, 0xFF
    OUT     DDRC, R16   // PD0-PD7 OUT (leds)
    LDI     R16, 0x00
    OUT     PORTC, R16	// PD0-PD7 LOW

    // Deshabilitar serial (esto apaga los demás LEDs del Arduino)
    LDI     R16, 0x00
    STS     UCSR0B, R16

    
    LDI     COUNTER, 0x00
/****************************************/
// Loop Infinito
MAIN_LOOP:
    IN      R16, TIFR0          // Leer registro de interrupción de TIMER 0
    SBRS    R16, TOV0           // Salta si el bit 0 está "set" (TOV0 bit)
    RJMP    MAIN_LOOP           // Reiniciar loop
    SBI     TIFR0, TOV0         // Limpiar bandera de "overflow"
    LDI     R16, 61            
    OUT     TCNT0, R16          // Volver a cargar valor inicial en TCNT0
    //INC     COUNTER
    //CPI     COUNTER, 16            // (TCINT0) = 100ms
    //BRNE    MAIN_LOOP
    //CLR     COUNTER
    CALL	INCREMENTO
    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines

INCREMENTO:
	INC		R17		// Incrementar R19 (sumar uno)
	CPI		R17, 0b00010000		// Si R19 supera 0x0F entonces volver a 0
	BREQ	SETCERO		
	OUT		PORTC, R17		// Mostrar en PORTD
	RET

SETCERO:
	LDI		R17, 0x00	// Reinicia el contador a 0x00
	RET

INIT_TMR0:
    LDI     R16, (1<<CS01) | (1<<CS00)
    OUT     TCCR0B, R16         // Setear prescaler del TIMER 0 a 64
    LDI     R16, 61            // Se comienza a contar los ciclos (normalmente 0-255) en 60 a 255. Para que a los 195 ciclos se reinicie
    OUT     TCNT0, R16          // Cargar valor inicial en TCNT0
    RET
/****************************************/
// Interrupt routines

/****************************************/