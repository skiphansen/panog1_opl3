#include <stdint.h>
#include "pano_io.h"

// ;; initialize OPL3 registers for a 1kHz sine wave

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

   {0xc0, 0x11 }, // Channels/Connections/Feedback
   {0xc3, 0x00 }, // Channels/Connections/Feedback

   {0xa0, 0xa4 }, // FNUM        $freq = ($fnum / (1 << (20-$block))) * 49715.0;
   {0xb0, 0x3c }, // KON/Block/FNUM_H
   {0}            // end of table
};

void Opl3WriteReg(uint8_t RegOffset,uint8_t Data);

void main() 
{
   int i;
   uint32_t Status;
   uint32_t Sample;

   for(i = 0; InitData[i].Reg != 0; i++) {
      Opl3WriteReg(InitData[i].Reg,InitData[i].Value);
   }

   Sample = OPL3_OUTPUT;
   Sample = OPL3_OUTPUT;

   for( ; ; ) {
      Status = OPL3_STATUS;
      if(Status & OPL3_STATUS_OVFL) {
         break;
      }
   }

   Sample = OPL3_OUTPUT;
   Sample = OPL3_OUTPUT;

   for( ; ; ) {
      Status = OPL3_STATUS;
      if(Status & OPL3_STATUS_OVFL) {
         break;
      }
      if(Status & OPL3_STATUS_RDY) {
         Sample = OPL3_OUTPUT;
      }
   }
   for( ; ; );
}

void Opl3WriteReg(uint8_t RegOffset,uint8_t Data)
{
   volatile uint8_t *p;

   p = (volatile uint8_t *)(OPL3_ADR + (RegOffset << 2));
   *p = Data;
}


void irq_handler(uint32_t pc) 
{
   while(1);
}

