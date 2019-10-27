/*
 *  VerilogBoy
 *
 *  This source code is adapted from:
 *    PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *  Copyright (C) 2019  Wenting Zhang <zephray@outlook.com>
 *  Copyright (C) 2019  Skip Hansen
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

// This is the bootloader for the PicoRV32 core inside Pano G1
// It will copy 256KB data from SPI Flash to the LPDDR RAM, and jump to the RAM

#include <stdint.h>
#include <stdbool.h>
#include "pano_io.h"

// a pointer to this is a null pointer, but the compiler does not
// know that because "sram" is a linker symbol from sections.lds.
extern uint32_t sram;

#define spi_select() SPI_CSN = 0
#define spi_deselect() SPI_CSN = 1


volatile uint32_t *gVRAM;
volatile uint32_t *DDR_ptr;
uint32_t enable_uart = 0;

uint8_t gCrtRow;
uint8_t gCrtCol;

void term_clear() {
   gVRAM = VRAM;
   for(int i = 0; i < SCREEN_X * SCREEN_Y; i++) {
      *gVRAM++ = 0x20;
   }
   gVRAM = VRAM;
   gCrtRow = 0;
   gCrtCol = 0;
}

void SetVRAMPtr()
{
   gVRAM = VRAM + gCrtCol + (gCrtRow * SCREEN_X);
}

void term_putchar(char p)
{
   if(p == '\n') {
      gCrtRow++;
      if(gCrtRow >= SCREEN_Y) {
         gCrtRow = 0;
      }
      gCrtCol = 0;
      SetVRAMPtr();
   }
   else if(p == '\r') {
      gCrtCol = 0;
      SetVRAMPtr();
   }
   else {
      *gVRAM++ = p;
      gCrtCol++;
      if(gCrtCol >= SCREEN_X) {
         term_putchar('\n');
      }
   }
   if(enable_uart) DEBUG_UART = p;
}

void term_print(const char *cp)
{
   while(*cp) {
      term_putchar(*cp++);
   }
}

void uart_print(const char *p)
{
   while(*p)
      DEBUG_UART = *p++;
}


void term_print_hex(uint32_t v, int digits)
{
   for(int i = 7; i >= 0; i--) {
      char c = "0123456789abcdef"[(v >> (4*i)) & 15];
      if(c == '0' && i >= digits) continue;
      term_putchar(c);
      digits = i;
   }
}

void term_print_dec(uint32_t v)
{
   int mul_index;
   int cmp;
   int i;
   int match;
   const int cmp_start[5] = {90000, 9000, 900, 90, 9};
   const int cmp_dec[5] = {10000, 1000, 100, 10, 1};
   if(v >= 100000) {
      term_print(">=100000");
      return;
   }
   for(mul_index = 0; mul_index < 5; mul_index++) {
      cmp = cmp_start[mul_index];
      match = 0;
      for(i = 0; i < 9; i += 1) {
         if(v >= cmp) {
            term_putchar('9' - i);
            v -= cmp;
            match = 1;
            break;
         }
         cmp -= cmp_dec[mul_index];
      }
      if(!match) term_putchar('0');
   }
}

void irq_handler(uint32_t pc) 
{
   // External logic is required to connect fault signal to IRQ line,
   // and ENABLE_IRQ_QREGS should be turned off.
   enable_uart = 1;
   term_print("\nHARD FAULT PC = ");
   term_print_hex(pc, 8);
   while(1);
}

uint32_t DDR_generate_test_word(uint32_t input) {
   return(input << 24) | (input << 12) | input;
}

void DDR_memtest()
{
   volatile uint32_t *ptr;
   volatile uint8_t *base_byte = (uint8_t *)DDR;
   int i;

   int counter;
   ptr = DDR;
   counter = 0;
   term_print("Testing DDR\n");
   term_print("Filling memory wtih test pattern\n");
   for(int i = 0; i < (DDR_TOTAL/1024); i++) {
      //ptr = DDR + i * (1024/4); 
      for(int j = 0; j < (1024/4); j++) {
         *ptr++ = DDR_generate_test_word(counter);
         counter ++;
      }
      term_print("\r");
      term_print_dec(i + 1);
   }
   ptr = DDR;
   counter = 0;
   term_print("\nChecking test pattern\n");
   for(i = 0; i < (DDR_TOTAL/1024); i++) { // (DDR_TOTAL/1024)
      for(int j = 0; j < (1024/4); j++) { // (1024/4)
         uint32_t dat = *ptr;
         if(dat != DDR_generate_test_word(counter)) {
            term_print("\nFailed at word ");
            term_print_hex((uint32_t)ptr, 8);
            term_print(": ");
            term_print_hex((uint32_t)(dat), 8);
            term_print(" Expected: ");
            term_print_hex((uint32_t)(DDR_generate_test_word(counter)), 8);
            term_print("\n");
            for( ; ; );
         }
         ptr++;
         counter++;
      }
      term_print("\r");
      term_print_dec(i + 1);
   }
   term_print("\nMemory test passed.\n");
}

void spi_send_byte(unsigned char b) {
   SPI_CLK = 1;
   for(int i = 0; i < 8; i++) {
      SPI_CLK = 0;
      SPI_DO = b >> 7;
      b = b << 1;
      SPI_CLK = 1;
   }
}

unsigned char spi_recv_byte() {
   unsigned char b = 0;
   for(int i = 0; i < 8; i++) {
      SPI_CLK = 0;
      b = b << 1;
      SPI_CLK = 1;
      b |= SPI_DI;
   }
   return b;
}

bool check_id() 
{
   bool Ret = true;  // Assume the best
   // read SPI flash device id
   spi_select();
   spi_send_byte(0x9f);
   uint8_t mem_mfg = spi_recv_byte();
   uint8_t mem_typ = spi_recv_byte();
   uint8_t mem_cap = spi_recv_byte();
   spi_deselect();
   if(mem_mfg != 0x20 || mem_typ != 0x20 || mem_cap != 0x14) {
      term_print("SPI Memory ID check failed, read: ");
      term_print_hex(mem_mfg, 2);
      term_print_hex(mem_typ, 2);
      term_print_hex(mem_cap, 2);
      term_print("\n");
      Ret = false;
   }

   return Ret;
}

bool copy_loop(bool bVerify)
{
   DDR_ptr = DDR;  
   unsigned long aDDRess;
   uint32_t Value;
   uint32_t Data;
   bool Ret = true;

   if(bVerify) {
      term_print("verifying");
   }
   else {
      term_print("Loading");
   }
   term_print(" application, ");
   for(int i = 0; i < 256; i++) {
      aDDRess = i * 1024 + 0xC0000;
      spi_select();
      spi_send_byte(0x03);
      spi_send_byte((aDDRess >> 16)&0xFF);
      spi_send_byte((aDDRess >> 8)&0xFF);
      spi_send_byte((aDDRess)&0xFF);
      for(int j = 0; j < 1024/4; j++) {
         unsigned long b1 = (unsigned long)spi_recv_byte();
         unsigned long b2 = (unsigned long)spi_recv_byte();
         unsigned long b3 = (unsigned long)spi_recv_byte();
         unsigned long b4 = (unsigned long)spi_recv_byte();
         Value = (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
         if(bVerify) {
            if(Value != (Data = *DDR_ptr++)) {
               term_print("\nVerify error @ 0x");
               term_print_hex(aDDRess + (j * 4),4);
               term_print(", is 0x");
               term_print_hex(Data,4);
               term_print(", should be 0x");
               term_print_hex(Value,4);
               term_print("\n");
               Ret = false;
               break;
            }
         }
         else {
            *DDR_ptr++ = Value;
         }
      }
      spi_deselect();
      if(!Ret) {
         break;
      }
   }

   return Ret;
}

int main()
{
   uint32_t DLY_TAP_was = DLY_TAP;

   // Set interrupt mask to zero (enable all interrupts)
   // This is a PicoRV32 custom instruction 
   asm(".word 0x0600000b");

   DLY_TAP = 0x03;

   SPI_CLK = 1;
   SPI_CSN = 1;
   LEDS = LED_GREEN;
   enable_uart = 0;
   term_clear();
   term_print("Bootloader compiled " __DATE__ " " __TIME__ "\n");
#if 0
   term_print("DLY_TAP was ");
   term_print_hex(DLY_TAP_was, 8);
   DLY_TAP_was = DLY_TAP;
   term_print("\nDLY_TAP is ");
   term_print_hex(DLY_TAP_was, 8);
   term_print("\n");
#endif

   if(!check_id()) {
      for( ; ; );
   }

   for( ; ; ) {
      copy_loop(false);
      if(!copy_loop(true)) {
         DDR_memtest();
      }
      else {
         term_print("done.\n");
         break;
      }
   }
   LEDS = LED_RED;
   term_print("Running application...\n");
   return gCrtRow;
}
