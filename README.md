# Timed-Electronic-safe-
A model of an electronic safe that has a time limit in which user have to enter the password.The project is based on finite state machines and beign programmed in Verilog using Quartus II 13.0 as the development platform. And the target board was an Altera DE 2 board. 
******************************Working of the project**************************************
The safe is programmed to have following functionalities:- 
  1. The safe will give 30 seconds time to enter the password. In case if password is not entered within 30 seconds the safe will reset             automatically. 
  2. If password is entered within the time limit but the password is wrong the safe will wait 30 seconds before reset and give another chance to enter the password. 
  3. The safe has 3 modes : a) Locked mode 
                             b) Entry mode 
                             c) Unlocked mode 
  4. The Seven segment display are being used to display the input and output from the safe. 

P.S. The project has several modules in different files. all of them are called by the top level module which is timed_electronic_safe. all files must be in the project for a successful compilation. 
