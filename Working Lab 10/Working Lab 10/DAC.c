// dac.c
// Angel Gonzalez and Alfonso Reyes
#include <stdint.h>
#include "tm4c123gh6pm.h"
// Code files contain the actual implemenation for public functions
// this file also contains an private functions and private data


// **************DAC_Init*********************
// Initialize 4-bit DAC, called once 
// Input: none
// Output: none
void DAC_Init(void){
	
	GPIO_PORTB_DIR_R |= 0x0F;		//PB0 thru PB3 are outputs
	GPIO_PORTB_DEN_R |= 0x0F;
	GPIO_PORTB_AMSEL_R &= ~0x0F; 
  GPIO_PORTB_PCTL_R &= ~0x000000FF; 
  GPIO_PORTB_AFSEL_R &= ~0x0F; 
	
}




// **************DAC_Out*********************
// output to DAC
// Input: 4-bit data, 0 to 15 
// Output: none
void DAC_Out(uint32_t data){
	
	GPIO_PORTB_DATA_R &= 0x00;
	GPIO_PORTB_DATA_R |= data;
		
}
