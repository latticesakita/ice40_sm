#ifndef _LIB_OV08X_H_
#define _LIB_OV08X_H_

#include "gpio.h"
#include "timer2.h"
#include "sys_platform.h"

#define GPIO_OSC_EN		GPIO7
#define GPIO_SENSOR_RESETN	GPIO6
#define I2C_SLAVE_OV08X (0x36)
struct sensor_i2c_data {
	unsigned short offset;
	unsigned char  val;
};

int ov08x_start(struct gpio_instance *gpio_inst, unsigned char ov08x_slave);
int ov08x_stop(struct gpio_instance *gpio_inst, unsigned char ov08x_slave);

#endif

