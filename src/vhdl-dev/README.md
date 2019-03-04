# SPSP - Firmware decomposed

Each of the directories here is a standalone project with one part of the system - isolated (as much as possible) for testing purposes.  
Each project contains:
* a runnable test entity, allowing to deploy it to hardware and test
* a complete testbench aimed at covering all of the main component features (with hardware related components mocked at different levels of abstraction)

### Entity diagram

![entity diagram](../../img/VHDL-entity-layout.png)
