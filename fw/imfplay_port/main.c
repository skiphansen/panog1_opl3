#include <stdint.h>
#include "pano_io.h"
#include "pano_time.h"
#include "printf.h"
#include "audio.h"

// #define DEBUG_LOGGING
// #define VERBOSE_DEBUG_LOGGING
#define LOG_TO_BOTH
#include "log.h"

// #define SIN_TEST

uint8_t gCrtRow = 3;
uint8_t gCrtCol;
volatile uint32_t *gVram = VRAM;

void term_clear(void);
void _putchar(char c);
void SetVramPtr(void);
int imfplay(char *filename);
void SinTest(void);
void CaptureData(void);

int Index = 0;

void main() 
{
   LEDS = LED_RED;
   SetVramPtr();
   ALOG("imfplay compiled " __DATE__ " " __TIME__ "\n");
   audio_init();
#ifdef SIN_TEST
   SinTest();
   CaptureData();
#else
   ALOG("Calling imfplay\n");
   ALOG("imfplay returned %d\n",imfplay("dummy"));
   ALOG("%d samples captured\n",Index);
#endif
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

void UartPutc(char c)
{
   UART = (uint32_t) c;
}

void LogPutc(char c,void *arg)
{
   int LogFlags = (int) arg;

   if(!(LogFlags & LOG_DISABLED)) {
      if(LogFlags & LOG_SERIAL) {
         UartPutc(c);
      }

      if(LogFlags & LOG_MONITOR) {
         _putchar(c);
      }
   }
}

void Opl3WriteReg(uint8_t chip,uint8_t RegOffset,uint8_t Data)
{
   volatile uint8_t *p;

   p = (volatile uint8_t *)(OPL3_ADR + (RegOffset << 2));
   LOG("0x%02x -> 0x%02x ( 0x%x)\n",Data,RegOffset,p);
   *p = Data;
}

// initialize OPL3 registers for a 1kHz sine wave
struct {
   uint8_t Reg;
   uint8_t Value;
} InitData[] = {
   {0x20, 0x21 }, // OP1 Control Flags/Multiplier
   {0x23, 0x21 }, // OP2 Control Flags/Multiplier
   {0x28, 0x21 }, // OP3 Control Flags/Multiplier
   {0x2b, 0x21 }, // OP4 Control Flags/Multiplier

   {0x40, 0x00 }, // OP1 KSL/TL
   {0x43, 0x3f }, // OP2 KSL/TL (muted)
   {0x48, 0x3f }, // OP3 KSL/TL (muted)
   {0x4b, 0x3f }, // OP4 KSL/TL (muted)

   {0x60, 0x88 }, // OP1 AR/DR
   {0x63, 0x88 }, // OP2 AR/DR
   {0x68, 0x88 }, // OP3 AR/DR
   {0x6b, 0x88 }, // OP4 AR/DR

   {0x80, 0x00 }, // OP1 SL/RR
   {0x83, 0x00 }, // OP2 SL/RR
   {0x88, 0x00 }, // OP3 SL/RR
   {0x8b, 0x00 }, // OP4 SL/RR

   {0xe0, 0x00 }, // OP1 Waveform
   {0xe3, 0x00 }, // OP2 Waveform
   {0xe8, 0x00 }, // OP3 Waveform
   {0xeb, 0x00 }, // OP4 Waveform

   {0xc0, 0xf1 }, // Channels/Connections/Feedback
   {0xc3, 0xf0 }, // Channels/Connections/Feedback

   {0xa0, 0xa4 }, // FNUM        $freq = ($fnum / (1 << (20-$block))) * 49715.0;
   {0xb0, 0x3c }, // KON/Block/FNUM_H
   {0}            // end of table
};

void SinTest()
{
   int i;

   for(i = 0; InitData[i].Reg != 0; i++) {
      Opl3WriteReg(0,InitData[i].Reg,InitData[i].Value);
   }
}

#define CAPTURE_BUF_LEN 7000000
uint32_t CaptureBuf[CAPTURE_BUF_LEN];

void CaptureData()
{
   int i;
   uint32_t Status;
   int Captured;
   int16_t Sample;


   for(i = 0; i < CAPTURE_BUF_LEN; i++) {
      CaptureBuf[i] = (uint32_t) i;
   }

   Status = OPL3_OUTPUT;
   Status = OPL3_OUTPUT;
   LOG("Initial status: 0x%x\n",Status);
   LOG("Capturing %d samples...",CAPTURE_BUF_LEN);
   Status = OPL3_OUTPUT;
   Status = OPL3_OUTPUT;

   for(i = 0; i < CAPTURE_BUF_LEN; i++) {
      for( ; ; ) {
         Status = OPL3_STATUS;
         if(Status & OPL3_STATUS_OVFL) {
            LOG_R("\nOverflow error\n");
            break;
         }
         if(Status & OPL3_STATUS_RDY) {
            CaptureBuf[i] = OPL3_OUTPUT;
            break;
         }
      }
      if(Status & OPL3_STATUS_OVFL) {
         break;
      }
   }

   Captured = i;
   LOG("\nCaptured %d samples\n",Captured);

   for(i = 0; i < Captured; i++) {
      if((i & 0x7) == 0) {
         LOG_R("\n");
      }
      Sample = (int16_t) (CaptureBuf[i] & 0xffff);
      LOG_R("%d,",Sample);
   }
}


#if 0
void TimerDelay(uint32_t us)
{
   uint32_t start = ticks(); 
   uint32_t Status;

   if(Index == 0) {
      Status = OPL3_OUTPUT;
      Status = OPL3_OUTPUT;
   }

   while ((ticks() - start) < (CYCLE_PER_US * us)) {
      if(Index < CAPTURE_BUF_LEN) {
         Status = OPL3_STATUS;
         if(Status & OPL3_STATUS_OVFL) {
            ELOG("Overflow error\n");
         }
         if(Status & OPL3_STATUS_RDY) {
            CaptureBuf[Index++] = OPL3_OUTPUT;
         }
         if(Index == CAPTURE_BUF_LEN) {
            ALOG("Capture buffer filled\n");
         }
      }
   }
}
#else
void TimerDelay(uint32_t us)
{
   uint32_t start = ticks(); 

   while ((ticks() - start) < (CYCLE_PER_US * us));
}
#endif
