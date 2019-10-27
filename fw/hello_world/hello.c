#include <stdint.h>

#define SCREEN_X     80
#define SCREEN_Y     30

#define LED_RED      0x1
#define LED_GREEN    0x2
#define LED_BLUE     0x4

#define LEDS_ADR     0x03000004

// For VRAM, only the lowest byte in each 32bit word is used
#define vram         ((volatile uint32_t *)0x08000000)
#define leds         *((volatile uint32_t *)LEDS_ADR)

uint8_t gCrtRow = 3;
uint8_t gCrtCol;
volatile uint32_t *gVram = vram;

void term_clear(void);
void term_putchar(char c);
void term_print(const char *cp);
void SetVramPtr(void);

void main() 
{
   leds = LED_RED;
   SetVramPtr();
   term_print("Hello Pano World!\n");
   leds = LED_GREEN;
   for( ; ; );
}



void term_clear() 
{
   gVram = vram;
   for(int i = 0; i < SCREEN_X * SCREEN_Y; i++) {
      *gVram++ = 0x20;
   }
   gVram = vram;
   gCrtRow = 0;
   gCrtCol = 0;
}

void SetVramPtr()
{
   gVram = vram + gCrtCol + (gCrtRow * SCREEN_X);
}

void term_putchar(char c)
{
   if(c == '\n') {
      gCrtRow++;
      if(gCrtRow >= SCREEN_Y) {
         gCrtRow = 0;
      }
      gCrtCol = 0;
      SetVramPtr();
   }
   else if(c == '\r') {
      gCrtCol = 0;
      SetVramPtr();
   }
   else {
      *gVram++ = c;
   }
}

void term_print(const char *cp)
{
   while(*cp) {
      term_putchar(*cp++);
   }
}

