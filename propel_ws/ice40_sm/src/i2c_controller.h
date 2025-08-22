#ifndef _I2C_CONTROLLER_H_
#define _I2C_CONTROLLER_H_
#include "gpio.h"
#include "sys_platform.h"

enum I2C_BUS_NUM {
	I2C_BUS1 = 1,
	I2C_BUS2 = 2
};

void i2c_bus_set(enum I2C_BUS_NUM n);
int i2c_init(struct gpio_instance *gpio, uint32_t sys_clock_freq);
int i2c_write(unsigned char slave, unsigned short offset, unsigned int count, unsigned char *val) ;
int i2c_read(unsigned char slave, unsigned short offset, unsigned int count, unsigned char *val) ;
int i2c_byte_write(unsigned char slave, unsigned short offset, unsigned char val);
int i2c_byte_read(unsigned char slave, unsigned short offset, unsigned char *val);


#endif

