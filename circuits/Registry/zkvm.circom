pragma circom 2.1.6;
include "../../node_modules/circomlib/circuits/comparators.circom";
// include "../node_modules/circomlib/circuits/multiplexer.circom";
include "../QuinSelector.circom";

template ZKVM(wordSize, numRegisters, clocks) {

  signal input instructions[clocks][3];

  signal trace[clocks][numRegisters];
  signal pc[clocks];
  signal clk[clocks];

  


}