/*
 *  pano_io.h
 *
 *  Copyright (C) 2019  Skip Hansen
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
 *
 */
#ifndef _PANO_IO_H_
#define _PANO_IO_H_

#define SCREEN_X    80
#define SCREEN_Y    30

#define CYCLE_PER_US  100

 // GPIO
 // ----------------------------------------------------------------------
 
 // 03000000 (0x0)  - R:  delay_sel_det / W: delay_sel_val
 // 03000004 (0x1)  - W:  leds (0xb0: red, b1: green, b2: blue)
 // 03000008 (0x2)  - W:  not used
 // 0300000c (0x3)  - W: spi_cs_n
 // 03000010 (0x4)  - W:  not used
 // 03000014 (0x5)  - W: spi_do
 // 03000018 (0x6)  - R: spi_di
 // 0300001c (0x7)  - W:  usb_rst_n
 // 03000020 (0x8)  - W:  Wolfson i2c_scl
 // 03000024 (0x9)  - RW: Wolfson i2c_sda
 // 03000028 (0xa)  - W:  VGA DDC i2c_scl
 // 0300002c (0xb)  - RW: VGA DDC i2c_sda

#define DLY_TAP_ADR        0x03000000
#define LEDS_ADR           0x03000004
#define OPL3_OUTPUT_ADR    0x03000008
#define SPI_CSN_ADR        0x0300000C
#define SPI_CLK_ADR        0x03000010
#define SPI_DO_ADR         0x03000014
#define SPI_DI_ADR         0x03000018

#define SCL_OFFSET         0
#define SDA_OFFSET         4

#define USB_RST_ADR        0x0300001c
#define CODEC_I2C_ADR      0x03000020
#define VGA_I2C_ADR        0x03000028
#define OPL3_STATUS_ADR    0x03000030

#define OPL3_STATUS_RDY    0x00000001
#define OPL3_STATUS_OVFL   0x00000002

#define UART_ADR           0x03000100
#define OPL3_ADR           0x03000400
#define VRAM_ADR           0x08000000
#define DDR_ADR            0x0C000000
#define DDR_TOTAL          0x2000000 // 32 MB


// For VRAM, only the lowest byte in each 32bit word is used
#define VRAM               ((volatile uint32_t *)VRAM_ADR)
#define DDR                ((volatile uint32_t *)DDR_ADR)
#define DLY_TAP            *((volatile uint32_t *)DLY_TAP_ADR)
#define LEDS               *((volatile uint32_t *)LEDS_ADR)
#define OPL3_OUTPUT        *((volatile uint32_t *)OPL3_OUTPUT_ADR)

#define SPI_CSN            *((volatile uint32_t *)SPI_CSN_ADR)
#define SPI_CLK            *((volatile uint32_t *)SPI_CLK_ADR)
#define SPI_DO             *((volatile uint32_t *)SPI_DO_ADR)
#define SPI_DI             *((volatile uint32_t *)SPI_DI_ADR)
#define DEBUG_UART         *((volatile uint32_t *)UART_ADR)
#define USB_RST            *((volatile uint32_t *)USB_RST_ADR)
#define OPL3_STATUS        *((volatile uint32_t *)OPL3_STATUS_ADR)

#define OPL3               *((volatile uint8_t *)OPL3_ADR)

#define LED_RED            0x1
#define LED_GREEN          0x2
#define LED_BLUE           0x4

#define UART               *((volatile uint32_t *)UART_ADR)

#endif // _PANO_IO_H_

