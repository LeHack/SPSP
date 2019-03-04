# SPSP - Firmware

### Code layout :zap:

* drivers - low level code interfacing directly with the external devices
  * de0nano_adc - reads data from the DE0Nano Analog to Digital converter, used for reading PM10 levels (analog)
  * dht11 - drives the humidity sensor
  * eeprom - drives the internal EEPROM memory of DE0Nano
  * gp2y1010 - drives the PM10 sensor
  * lps331ap - drives from the pressure and temperature sensor
  * rn4020 - drives the Bluetooth transceiver
  * sdram - drives the internal SDRAM memory of DE0Nano
  * shift_reg - used by sm410564 driver to control the display
  * sm410564 - drives the display
* ext - external code and modules, usually from Quartus or eewiki
  * mult, div - arithmetic multiplication and division modules (signed 24 bit, unsigned 24 bit and unsigned 16 bit)
  * sdram_clk_pll - SDRAM clock signal generator (100MHz and 100Mhz + 4us)
  * i2c_master - I2C implementation
  * spi master - SPI implementation
  * uart - UART implementation
* modules - implement main system operation logic
* simulation - integration tests using ModelSim
* utils
  * clock_divider - clock divider used by drivers to generate different clock signals from DE0Nano's internal 50MHz
  * types - internal data structure definitions and some helper methods for type conversion

### Entity diagram

![entity diagram](../../img/VHDL-entity-layout.png)
