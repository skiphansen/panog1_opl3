#ifndef I2C_H
#define I2C_H

#include "pano_io.h"

#define MCP23017_I2C_ADR      0x40
#define WM8750L_I2C_ADR       0x34

void i2c_init(int Port);
void i2c_dly();
void i2c_start(int Port);
void i2c_stop(int Port);
unsigned char i2c_rx(int Port, char ack);
int i2c_tx(int Port, unsigned char d);
int i2c_write_buf(int Port, uint8_t addr, uint8_t* data, int len);
int i2c_read_buf(int Port, uint8_t addr, uint8_t *data, int len);
int i2c_write_reg_nr(int Port, uint8_t addr, uint8_t reg_nr);
int i2c_write_reg(int Port, uint8_t addr, uint8_t reg_nr, uint8_t value);
int i2c_write_regs(int Port, uint8_t addr, uint8_t reg_nr, uint8_t *values, int len);
int i2c_read_reg(int Port, uint8_t addr, uint8_t reg_nr, uint8_t *value);
int i2c_read_regs(int Port, uint8_t addr, uint8_t reg_nr, uint8_t *values, int len);

#endif
