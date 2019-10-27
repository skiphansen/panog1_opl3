#include <stdint.h>
#include "pano_io.h"
#include "printf.h"
#include "audio.h"

#define DEBUG_LOGGING
#define VERBOSE_DEBUG_LOGGING
#include "log.h"

uint8_t gCrtRow = 3;
uint8_t gCrtCol;
volatile uint32_t *gVram = VRAM;

void term_clear(void);
void _putchar(char c);
void SetVramPtr(void);
int imfplay(char *filename);

void main() 
{
   LEDS = LED_RED;
   SetVramPtr();
   printf("imfplay compiled " __DATE__ " " __TIME__ "\n");
   audio_init();
   printf("Calling imfplay\n");
   printf("imfplay returned %d\n",imfplay("dummy"));
   LEDS = LED_GREEN;
   for( ; ; );
}


void term_clear() 
{
   gVram = VRAM;
   for(int i = 0; i < SCREEN_X * SCREEN_Y; i++) {
      *gVram++ = 0x20;
   }
   gVram = VRAM;
   gCrtRow = 0;
   gCrtCol = 0;
}

void SetVramPtr()
{
   gVram = VRAM + gCrtCol + (gCrtRow * SCREEN_X);
}

void _putchar(char c)
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

void LogPutc(char c,void *arg)
{
   int LogFlags = (int) arg;

   if(!(LogFlags & LOG_DISABLED)) {
#if 0
      if(LogFlags & LOG_SERIAL) {
         UartPutc(c);
      }
#endif

      if(LogFlags & LOG_MONITOR) {
         _putchar(c);
      }
   }
}

void Opl3WriteReg(uint8_t chip,uint8_t RegOffset,uint8_t Data)
{
   LOG("0x%02x -> 0x%02x\n",Data,RegOffset);
   *((volatile uint8_t *)(OPL3_ADR + (RegOffset << 2))) = Data;
}


