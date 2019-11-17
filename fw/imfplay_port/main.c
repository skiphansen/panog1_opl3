#include <stdint.h>
#include "pano_io.h"
#include "pano_time.h"
#include "printf.h"
#include "audio.h"

#define DEBUG_LOGGING
// #define VERBOSE_DEBUG_LOGGING
#define LOG_TO_BOTH
#include "log.h"

#define SIN_TEST

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

void Opl3WriteReg(uint8_t chip,uint16_t RegOffset,uint8_t Data)
{
   volatile uint8_t *p;

   p = (volatile uint8_t *)(OPL3_ADR + (RegOffset << 2));
   LOG("0x%02x -> 0x%02x ( 0x%x)\n",Data,RegOffset,p);
   *p = Data;
}

const uint8_t OpOffset[] = {
   0x0,0x1,0x2,0x3,0x4,0x5,
   0x8,0x9,0xa,0xb,0xc,0xd,
   0x10,0x11,0x12,0x13,0x14,0x15
};

#define NUM_OPS_PER_BANK   18
#define NUM_BANKS          2
#define REG_ADR(x,y)       ((x << 8) + y)

#define BANK   0
// initialize OPL3 registers for a 1kHz sine wave
struct {
   uint8_t Bank;
   uint8_t Reg;
   uint8_t Value;
} InitData[] = {
//    {1, 0x05, 0x01 }, // enable OPL3 mode

   {BANK,  0x20, 0x21 }, // OP1 Control Flags/Multiplier
   {BANK,  0x23, 0x21 }, // OP2 Control Flags/Multiplier
   {BANK,  0x28, 0x21 }, // OP3 Control Flags/Multiplier
   {BANK,  0x2b, 0x21 }, // OP4 Control Flags/Multiplier

   {BANK,  0x40, 0x08 }, // OP1 KSL/TL
#if 0                         //
   {BANK,  0x43, 0x3f }, // OP2 KSL/TL (muted)
   {BANK,  0x48, 0x3f }, // OP3 KSL/TL (muted)
   {BANK,  0x4b, 0x3f }, // OP4 KSL/TL (muted)
#endif

   {BANK,  0x60, 0x88 }, // OP1 AR/DR
   {BANK,  0x63, 0x88 }, // OP2 AR/DR
   {BANK,  0x68, 0x88 }, // OP3 AR/DR
   {BANK,  0x6b, 0x88 }, // OP4 AR/DR

   {BANK,  0x80, 0x00 }, // OP1 SL/RR
   {BANK,  0x83, 0x00 }, // OP2 SL/RR
   {BANK,  0x88, 0x00 }, // OP3 SL/RR
   {BANK,  0x8b, 0x00 }, // OP4 SL/RR

   {BANK,  0xe0, 0x00 }, // OP1 Waveform
   {BANK,  0xe3, 0x00 }, // OP2 Waveform
   {BANK,  0xe8, 0x00 }, // OP3 Waveform
   {BANK,  0xeb, 0x00 }, // OP4 Waveform

   {BANK,  0xc0, 0x01 }, // Channels/Connections/Feedback
   {BANK,  0xc3, 0x00 }, // Channels/Connections/Feedback

// FNUM        $freq = ($fnum / (1 << (20-$block))) * 49715.0;

   {BANK,  0xa0, 0xa4 }, // FNUM        $freq = ($fnum / (1 << (20-$block))) * 49715.0;
   {BANK,  0xb0, 0x3c }, // KON/Block/FNUM_H

#if 0
#undef BANK
#define BANK   1

   {BANK,  0x20, 0x21 }, // OP1 Control Flags/Multiplier
   {BANK,  0x23, 0x21 }, // OP2 Control Flags/Multiplier
   {BANK,  0x28, 0x21 }, // OP3 Control Flags/Multiplier
   {BANK,  0x2b, 0x21 }, // OP4 Control Flags/Multiplier

   {BANK,  0x40, 0x00 }, // OP1 KSL/TL
   {BANK,  0x43, 0x3f }, // OP2 KSL/TL (muted)
   {BANK,  0x48, 0x3f }, // OP3 KSL/TL (muted)
   {BANK,  0x4b, 0x3f }, // OP4 KSL/TL (muted)

   {BANK,  0x60, 0x88 }, // OP1 AR/DR
   {BANK,  0x63, 0x88 }, // OP2 AR/DR
   {BANK,  0x68, 0x88 }, // OP3 AR/DR
   {BANK,  0x6b, 0x88 }, // OP4 AR/DR

   {BANK,  0x80, 0x00 }, // OP1 SL/RR
   {BANK,  0x83, 0x00 }, // OP2 SL/RR
   {BANK,  0x88, 0x00 }, // OP3 SL/RR
   {BANK,  0x8b, 0x00 }, // OP4 SL/RR

   {BANK,  0xe0, 0x00 }, // OP1 Waveform
   {BANK,  0xe3, 0x00 }, // OP2 Waveform
   {BANK,  0xe8, 0x00 }, // OP3 Waveform
   {BANK,  0xeb, 0x00 }, // OP4 Waveform

   {BANK,  0xc0, 0x31 }, // Channels/Connections/Feedback
   {BANK,  0xc3, 0x30 }, // Channels/Connections/Feedback

// FNUM        $freq = ($fnum / (1 << (20-$block))) * 49715.0;

   {BANK,  0xa0, 0xa4 }, // FNUM        $freq = ($fnum / (1 << (20-$block))) * 49715.0;
   {BANK,  0xb0, 0x38 }, // KON/Block/FNUM_H
#endif
   {0xff}   // end of table
};

void SinTest()
{
   int i;
   int j;

   for(i = 0; i < NUM_BANKS; i++) {
      for(j = 0; j < NUM_OPS_PER_BANK; j++) {
         Opl3WriteReg(0,REG_ADR(i,0x40+OpOffset[j]),0x3f);   // KSL/TL (muted)
      }
   }

   for(i = 0; InitData[i].Bank != 0xff; i++) {
      Opl3WriteReg(0,InitData[i].Reg + (InitData[i].Bank << 8) ,InitData[i].Value);
   }
}

#define CAPTURE_BUF_LEN 1000
uint32_t CaptureBuf[CAPTURE_BUF_LEN];

void CaptureData()
{
   int i;
   uint32_t Status;
   int Captured;
   int16_t Sample1;
   int16_t Sample2;


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
#if 0
      if((i & 0x7) == 0) {
         LOG_R("\n");
      }
#endif
#if 1
      Sample1 = (int16_t) (CaptureBuf[i] & 0xffff);
      Sample2 = (int16_t) ((CaptureBuf[i] >> 16) & 0xffff);
      LOG_R("%d,%d\n",Sample1,Sample2);
#else
      LOG_R("0x%x,",CaptureBuf[i]);
#endif
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

void irq_handler(uint32_t pc) 
{
   // External logic is required to connect fault signal to IRQ line,
   // and ENABLE_IRQ_QREGS should be turned off.
   ELOG("\nHARD FAULT PC = 0x%x\n",pc);
   while(1);
}

