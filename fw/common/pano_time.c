/*
 *  VerilogBoy
 *
 *  Copyright (C) 2019  Wenting Zhang <zephray@outlook.com>
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms and conditions of the GNU General Public License,
 *  version 2, as published by the Free Software Foundation.
 *
 *  This program is distributed in the hope it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 *  more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin St - Fifth Floor, Boston, MA 02110-1301 USA.
 */
#include <stdint.h>
#include "pano_io.h"

uint32_t ticks() {
   uint32_t cycles;
   asm volatile ("rdcycle %0" : "=r"(cycles));
   return cycles;
}

uint32_t ticks_us() {
    return ticks() / CYCLE_PER_US;
}

uint32_t ticks_ms() {
    return ticks() / CYCLE_PER_US / 1000;
}

void delay_us(uint32_t us) {
    uint32_t start = ticks(); 
    while ((ticks() - start) < (CYCLE_PER_US * us));
}

void delay_ms(uint32_t ms) {
    while (ms--) { delay_us(1000); }
}

