
#include "gpio.h"
#include "timer.h"
#include "sys_platform.h"
#include "i2c_controller.h"

#ifdef I2CM_USE_HARD_IP
#define ADDR_I2C1	(0x01<<6)
#define ADDR_I2C2	(0x03<<6)

#define CMDR_STA (0x80)
#define CMDR_STO (0x40)
#define CMDR_RD  (0x20)
#define CMDR_WR  (0x10)
#define CMDR_ACK (0x08)
#define CMDR_CKSDIS (0x04) // clock stretch disable
#define CMDR_RBUFDIS (0x02) // Read command with buffer disable.

#define IRQEN_INTCLREN	(0x80)	// auto clear int by read flag
#define IRQEN_INTFRC	(0x40)	// force interrupt
#define IRQEN_ARBLEN	(0x08)	// int en for arbitration lost
#define IRQEN_TRRDYEN	(0x04)	// Tx or Rx ready
#define IRQEN_TROEEN	(0x02)	// Tx overrun or NACK
#define	IRQEN_HGCEN		(0x01)	// general call received

#define IRQ_ARBL		(0x08)	// arbitration lost
#define IRQ_TRRDY		(0x04)	// tx ready
#define IRQ_TROE		(0x02)	// overrun or nack
#define IRQ_HGC			(0x01)	// gc in slave mode interrupt

struct i2cm_dev {
	volatile unsigned rsvd0			;
	volatile unsigned rsvd1			;
	volatile unsigned rsvd2			;
	volatile unsigned I2CSADDR		;
	volatile unsigned rsvd4			;
	volatile unsigned rsvd5			;
	volatile unsigned I2CIRQ		;
	volatile unsigned I2CIRQEN		;
	volatile unsigned I2CCR1		;
	volatile unsigned I2CCMDR		;
	volatile unsigned I2CBRLSB		;
	volatile unsigned I2CBRMSB		;
	volatile unsigned I2CSR			;
	volatile unsigned I2CTXDR		;
	volatile unsigned I2CRXDR		;
	volatile unsigned I2CGCDR		;
};

volatile struct i2cm_dev *dev = (volatile struct i2cm_dev *)(I2CM_INST_BASE_ADDR | ADDR_I2C1);

void i2c_bus_set(enum I2C_BUS_NUM n)
{
	if(n==I2C_BUS1)
	{
		dev = (volatile struct i2cm_dev *)(I2CM_INST_BASE_ADDR | ADDR_I2C1);
	}
	else if(n==I2C_BUS2)
	{
		dev = (volatile struct i2cm_dev *)(I2CM_INST_BASE_ADDR | ADDR_I2C2);
	}
}
int i2c_init(struct gpio_instance *gpio, uint32_t sys_clock_freq)
{
    uint32_t prescale = sys_clock_freq / 400000 / 4; // div (400kHz*4) will be the target speed

    dev=(volatile struct i2cm_dev *)(I2CM_INST_BASE_ADDR | ADDR_I2C1);
    dev->I2CCR1   = 0x8C;
    dev->I2CBRLSB = prescale;
    dev->I2CBRMSB = prescale>>8;
    dev->I2CIRQEN = IRQEN_INTCLREN | IRQEN_ARBLEN | IRQEN_TRRDYEN | IRQEN_TROEEN ;

    dev=(volatile struct i2cm_dev *)(I2CM_INST_BASE_ADDR | ADDR_I2C2);
    dev->I2CCR1   = 0x0C; // 0x8C; // bit7=1 to enable
    dev->I2CBRLSB = prescale;
    dev->I2CBRMSB = prescale>>8;

    dev=(volatile struct i2cm_dev *)(I2CM_INST_BASE_ADDR | ADDR_I2C1);
    return 0;
}
static uint8_t i2c_start(uint8_t slave)
{
	volatile uint8_t val;
    dev->I2CIRQ = 0;
	dev->I2CTXDR = slave;
	dev->I2CCMDR = CMDR_STA | CMDR_WR ;
	do{
		val = dev->I2CIRQ;
	}while((val & IRQ_TRRDY) == 0);
	return val & (IRQ_ARBL | IRQ_TROE);
}
static void i2c_stop()
{
    dev->I2CIRQ = 0;
	dev->I2CCMDR = CMDR_STO ;
	//while((dev->I2CIRQ & IRQ_TRRDY) == 0);
}
static int i2c_write_byte(uint8_t byte)
{
	volatile uint8_t val;
    dev->I2CIRQ = 0;
	dev->I2CTXDR = byte;
	dev->I2CCMDR = CMDR_WR ;
	do{
		val = dev->I2CIRQ;
	}while((val & IRQ_TRRDY) == 0);
	return val & (IRQ_ARBL | IRQ_TROE);
}
static uint8_t i2c_read_byte(int ack)
{
	volatile uint8_t val;
    dev->I2CIRQ = 0;
    if(ack){
    	dev->I2CCMDR = CMDR_RD | CMDR_ACK;
    }else{
    	dev->I2CCMDR = CMDR_RD ;
    }
    while((dev->I2CIRQ & IRQ_TRRDY) == 0);
    val = dev->I2CRXDR;
	return val ;
}
#elif defined I2CM_USE_CUSTOM_IP
struct i2cm_dev {
	volatile unsigned dt               ;// data for lower 8bits, 9th bit for ACK output
	volatile unsigned inta             ;// b0: done, b1: ack status
	volatile unsigned start            ;// b0: start, b1: byte, b2: stop
	volatile unsigned rsvd             ;//
	volatile unsigned t_hd_start       ;// hold time of START conditio
	volatile unsigned t_low            ;// minimum 1.3us
	volatile unsigned t_high           ;// minimum 0.6us
	volatile unsigned t_su_start       ;// setup time for repeated START condition
	volatile unsigned t_su_data        ;// data hold time, 100ns
	volatile unsigned t_hd_data        ;// data hold time, 100ns
	volatile unsigned t_su_stop        ;// setup time for STOP condition
	volatile unsigned t_buf            ;// bus free time btween STOP and START, min 1.3us
};

#define I2C_DATA_NACK   (0x100)
#define I2C_DATA_MASK   (0x0FF)
#define I2C_INT_DONE    (0x0F)
#define I2C_INT_START   (0x01)
#define I2C_INT_BYTE    (0x02)
#define I2C_INT_STOP    (0x04)
#define I2C_INT_NACK    (0x1)
#define I2C_START_START (0x01)
#define I2C_START_BYTE  (0x02)
#define I2C_START_STOP  (0x04)

volatile struct i2cm_dev *dev = (volatile struct i2cm_dev *)(I2CM_INST_BASE_ADDR);
int i2c_init(struct gpio_instance *gpio, uint32_t sys_clock_freq)
{
		return 0;
}
static int i2c_write_byte(uint8_t byte)
{
	volatile unsigned int result;
	dev->dt = I2C_DATA_NACK | byte ;
	dev->start = I2C_START_BYTE;
	do{
		result = dev->inta;
	}while((result & I2C_INT_DONE) == 0 );
	return (result & I2C_INT_NACK) ? 1 : 0;
}
static uint8_t i2c_read_byte(int ack)
{
	uint8_t val;
	dev->dt = ack ? I2C_DATA_NACK : 0;
	dev->start = I2C_START_BYTE;
	while((dev->inta & I2C_INT_DONE) == 0);
	val = (uint8_t) (dev->dt & I2C_DATA_MASK);
	return val;
}
static uint8_t i2c_start(uint8_t slave)
{
	dev->start = I2C_START_START;
	while((dev->inta & I2C_INT_DONE) == 0);
	return i2c_read_byte(slave);
}
static void i2c_stop()
{
	dev->start = I2C_START_STOP;
	while((dev->inta & I2C_INT_DONE) == 0);
}
#else //
#define SDA_PIN GPIO0
#define SCL_PIN GPIO1

#define gpio_set_output(pin)	gpio_set_direction(gpio_inst, pin, GPIO_OUTPUT)
#define gpio_set_input(pin)	gpio_set_direction(gpio_inst, pin, GPIO_INPUT)
#define gpio_write(pin, val)	gpio_output_write(gpio_inst, pin, val)
#define gpio_read(pin, val)		gpio_input_get(gpio_inst, pin, val)
//#define i2c_delay(n)            usleep(n)
#define i2c_delay(n)

static struct gpio_instance *gpio_inst;


#if 0
void i2c_delay(int n) 
{
    for (volatile int i = 0; i < n; i++) {
        asm volatile("nop");
    }
}
#endif
int i2c_init(struct gpio_instance *gpio, uint32_t sys_clock_freq)
{
	gpio_inst = gpio;
	return 0;
}

static void i2c_write_bit(int bit) {
    if(bit!=0){
        gpio_set_input(SDA_PIN);
    }
    else{
        gpio_set_output(SDA_PIN);
    }
    i2c_delay(10);
    gpio_set_input(SCL_PIN);
    i2c_delay(10);
    gpio_set_output(SCL_PIN);
}

static int i2c_read_bit() {
    uint16_t bit;
    gpio_set_input(SDA_PIN);
    i2c_delay(10);
    gpio_set_input(SCL_PIN);
    gpio_read(SDA_PIN, &bit);
    i2c_delay(10);
    gpio_set_output(SCL_PIN);
    gpio_set_output(SDA_PIN);
    return bit;
}

static int i2c_write_byte(uint8_t byte) {
    for (int i = 0; i < 8; i++) {
        i2c_write_bit((byte >> (7 - i)) & 1);
    }
    return i2c_read_bit(); // ACK
}

static uint8_t i2c_read_byte(int ack) {
    uint8_t byte = 0;
    for (int i = 0; i < 8; i++) {
        byte = (byte << 1) | i2c_read_bit();
    }
    i2c_write_bit(!ack); // ACK = 0, NACK = 1
    return byte;
}
static uint8_t i2c_start(uint8_t slave)
{
    gpio_set_input(SCL_PIN);
    gpio_set_input(SDA_PIN);
    gpio_write(SDA_PIN, 0);
    gpio_write(SCL_PIN, 0);
    i2c_delay(10);
    gpio_set_output(SDA_PIN);
    i2c_delay(10);
    gpio_set_output(SCL_PIN);
    return i2c_write_byte(slave);
}

static void i2c_stop() {
    gpio_set_output(SDA_PIN);
    gpio_set_input(SCL_PIN);
    i2c_delay(10);
    gpio_set_input(SDA_PIN);
    i2c_delay(10);
}

#endif

int i2c_write(unsigned char slave, unsigned short offset, unsigned int count, unsigned char *val) {

	unsigned char tmp;
    if( i2c_start(slave<<1) ){
    	i2c_stop();
    	return -1;
    }

    // write 2bytes offset
    tmp = (unsigned char)((offset >> 8) & 0xff);
    if (i2c_write_byte(tmp) != 0) {
        i2c_stop();
        return -2;
    }
    tmp = (unsigned char)(offset & 0xff);
    if (i2c_write_byte(tmp) != 0) {
        i2c_stop();
        return -2;
    }

    // output data
    for (unsigned int i = 0; i < count; i++) {
        if (i2c_write_byte(val[i]) != 0) {
            i2c_stop();
            return -3;
        }
    }

    i2c_stop();
    return 0;
}

int i2c_read(unsigned char slave, unsigned short offset, unsigned int count, unsigned char *val) {

	unsigned char tmp;
    if( i2c_start(slave<<1) ){
    	i2c_stop();
    	return -1;
    }

    // write 2bytes offset
    tmp = (unsigned char)((offset >> 8) & 0xff);
    if (i2c_write_byte(tmp) != 0) {
        i2c_stop();
        return -2;
    }
    tmp = (unsigned char)(offset & 0xff);
    if (i2c_write_byte(tmp) != 0) {
        i2c_stop();
        return -2;
    }

    // restart
    if( i2c_start((slave<<1) | 1) ){
    	i2c_stop();
    	return -3;
    }

    // input data
    for (unsigned int i = 0; i < count; i++) {
        val[i] = i2c_read_byte(i < (count - 1)); // NACK at last byte
    }

    i2c_stop();
    return 0;
}


int i2c_byte_write(unsigned char slave, unsigned short offset, unsigned char val)
{
	return i2c_write(slave, offset, 1, &val);
}
int i2c_byte_read(unsigned char slave, unsigned short offset, unsigned char *val)
{
	return i2c_read(slave, offset, 1, val) ;
}

