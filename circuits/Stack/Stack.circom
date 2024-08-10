pragma circom 2.1.6;
include "../../node_modules/circomlib/circuits/comparators.circom";
// include "../node_modules/circomlib/circuits/multiplexer.circom";
include "../QuinSelector.circom";


// push only
template StackPush(maxStackHeight, maxSteps) {

  signal input pushValues[maxStackHeight];
  signal input row;
  signal input column;
  signal input value;

  // signal output out;
  signal trace[maxSteps][maxStackHeight];

  component condition[maxSteps][maxStackHeight];

  for (var i; i<maxSteps; i++) {
    for (var j; j<maxStackHeight; j++) {
      condition[i][j] = LessEqThan(maxSteps);
      condition[i][j].in[0] <== j;
      condition[i][j].in[1] <== i;
      trace[i][j] <== pushValues[j] * condition[i][j].out;
    }
  }

  component multiplexer = Multiplexer(maxStackHeight, maxSteps);
  multiplexer.inp <== trace;
  multiplexer.sel <== row;

  signal selectedRow[maxStackHeight] <== multiplexer.out;

  component quinSelector = QuinSelector(maxStackHeight);
  quinSelector.inp <== selectedRow;
  quinSelector.selector <== column;

  log(quinSelector.out);

  quinSelector.out === value;

}

template StackPushNop(maxStackHeight, maxSteps) {
  signal input instructions[maxSteps]; // TODO constrain them to be 0 or 1
  signal input values[maxSteps];

  signal input row;
  signal input column;
  signal input value;

  // constrain instructions to be 0 or 1;
  for(var k; k<maxSteps; k++) {
    instructions[k] * (instructions[k] - 1) === 0;
  }

  signal trace[maxSteps][maxStackHeight];

  signal stackPointer[maxSteps + 1]; // added 1 to not mess up the loop
  signal instructionPointer[maxSteps + 1]; // added 1 to not mess up the loop
  instructionPointer[0] <== 0;
  stackPointer[0] <== 0;
  component instructionSelector[maxSteps];
  component valueSelector[maxSteps];
  component conditions[maxSteps][maxStackHeight];
  signal conditionedInstruction[maxSteps][maxStackHeight];
  component isEqualCondition[maxSteps][maxStackHeight];

  // build the first row 
  instructionSelector[0] = QuinSelector(maxSteps);
  instructionSelector[0].inp <== instructions;
  instructionSelector[0].selector <== instructionPointer[0];

  valueSelector[0] = QuinSelector(maxSteps);
  valueSelector[0].inp <== values;
  valueSelector[0].selector <== instructionPointer[0];

  for(var k; k<maxStackHeight; k++) {
    conditions[0][k] = LessEqThan(maxStackHeight);
    conditions[0][k].in[0] <== k;
    conditions[0][k].in[1] <== stackPointer[0];

    conditionedInstruction[0][k] <== conditions[0][k].out * instructionSelector[0].out;
    trace[0][k] <== valueSelector[0].out * conditionedInstruction[0][k];
    // log(trace[0][k]);
  }

  stackPointer[1] <== stackPointer[0] + instructionSelector[0].out;
  instructionPointer[1] <== instructionPointer[0] + 1;

  component lesserThanSpConstrain[maxSteps][maxStackHeight];
  component equalToSpConstrain[maxSteps][maxStackHeight];

  signal instructionValueResult[maxSteps];

  signal temp1[maxSteps][maxStackHeight];
  signal temp2[maxSteps][maxStackHeight];


  for(var i = 1; i<maxSteps; i++) {
    instructionSelector[i] = QuinSelector(maxStackHeight);
    instructionSelector[i].inp <== instructions;
    instructionSelector[i].selector <== instructionPointer[i];

    valueSelector[i] = QuinSelector(maxSteps);
    valueSelector[i].inp <== values;
    valueSelector[i].selector <== instructionPointer[i];

    instructionValueResult[i] <== valueSelector[i].out * instructionSelector[i].out;

    for(var j; j<maxStackHeight; j++) {

      // cond1: j < stackPointer[i] => trace[i][j] <== trace[i - 1][j]
      // cond2 - j == stackPointer[i] => trace[i][j] <== instructionSelector[i].out * value[j]; // TODO: QuinSelector on value
      // cond3 - j > stackPointer[i] => 0

      lesserThanSpConstrain[i][j] = LessThan(maxStackHeight);
      lesserThanSpConstrain[i][j].in <== [j, stackPointer[i]];

      equalToSpConstrain[i][j] = IsEqual();
      equalToSpConstrain[i][j].in <== [j, stackPointer[i]];

      temp1[i][j] <== lesserThanSpConstrain[i][j].out * trace[i - 1][j];
      temp2[i][j] <== equalToSpConstrain[i][j].out * instructionValueResult[i];

      trace[i][j] <== temp1[i][j] + temp2[i][j];

    }

    stackPointer[i + 1] <== stackPointer[i] + instructionSelector[i].out;
    instructionPointer[i + 1] <== instructionPointer[i] + 1;
  }


  component multiplexer = Multiplexer(maxStackHeight, maxSteps);
  multiplexer.inp <== trace;
  multiplexer.sel <== row;

  signal selectedRow[maxStackHeight] <== multiplexer.out;

  component quinSelector = QuinSelector(maxStackHeight);
  quinSelector.inp <== selectedRow;
  quinSelector.selector <== column;

  log(quinSelector.out);

  quinSelector.out === value;


}

template StackPushNopPop(maxStackHeight, maxSteps) {
  signal input instructions[maxSteps];
  signal input values[maxSteps];

  signal input row;
  signal input column;
  signal input value;

  // constrain instructions to be 0, 1 or -1;
  signal temp3[maxSteps];
  // instructions[0] cannot be -1
  instructions[0] * (instructions[0] - 1) === 0;
  for(var k = 1; k<maxSteps; k++) {
    temp3[k] <== instructions[k] * (instructions[k] - 1);
    temp3[k] * (instructions[k] + 1) === 0;
  }

  // trace table
  signal trace[maxSteps][maxStackHeight];

  signal stackPointer[maxSteps];
  signal instructionPointer[maxSteps];

  component instructionSelector[maxSteps];
  component valueSelector[maxSteps];
  component conditions[maxSteps][maxStackHeight];
  signal conditionedInstruction[maxSteps][maxStackHeight];
  component isEqualCondition[maxSteps][maxStackHeight];

  // build the first row 
  instructionPointer[0] <== 0;
  instructionSelector[0] = QuinSelector(maxSteps);
  instructionSelector[0].inp <== instructions;
  instructionSelector[0].selector <== instructionPointer[0];

  stackPointer[0] <== -1 + instructionSelector[0].out;

  valueSelector[0] = QuinSelector(maxSteps);
  valueSelector[0].inp <== values;
  valueSelector[0].selector <== instructionPointer[0];

  for(var k; k<maxStackHeight; k++) {
    conditions[0][k] = LessEqThan(maxStackHeight);
    conditions[0][k].in[0] <== k;
    conditions[0][k].in[1] <== stackPointer[0];

    conditionedInstruction[0][k] <== conditions[0][k].out * instructionSelector[0].out;

    trace[0][k] <== valueSelector[0].out * conditionedInstruction[0][k];
    // log(trace[0][k]);
  }
  component lesserThanSpConstrain[maxSteps][maxStackHeight];
  component equalToSpConstrain[maxSteps][maxStackHeight];

  signal instructionValueResult[maxSteps];
  component isPop[maxSteps];

  signal temp1[maxSteps][maxStackHeight];
  signal temp2[maxSteps][maxStackHeight];
  signal temp4[maxSteps][maxStackHeight];

  for(var i = 1; i<maxSteps; i++) {
    instructionPointer[i] <== instructionPointer[i - 1] + 1;
    instructionSelector[i] = QuinSelector(maxSteps);
    instructionSelector[i].inp <== instructions;
    instructionSelector[i].selector <== instructionPointer[i];

    stackPointer[i] <== stackPointer[i - 1] + instructionSelector[i].out;

    valueSelector[i] = QuinSelector(maxSteps);
    valueSelector[i].inp <== values;
    valueSelector[i].selector <== instructionPointer[i];

    isPop[i] = LessEqThan(maxStackHeight);
    isPop[i].in <== [0, instructionSelector[i].out];

    instructionValueResult[i] <== valueSelector[i].out * instructionSelector[i].out;

    for(var j; j<maxStackHeight; j++) {

      lesserThanSpConstrain[i][j] = LessEqThan(maxStackHeight);
      lesserThanSpConstrain[i][j].in <== [j, stackPointer[i]];

      equalToSpConstrain[i][j] = IsEqual();
      equalToSpConstrain[i][j].in <== [j, stackPointer[i]];

      temp1[i][j] <== lesserThanSpConstrain[i][j].out * trace[i - 1][j];
      temp2[i][j] <== equalToSpConstrain[i][j].out * instructionValueResult[i];
      temp4[i][j] <== temp2[i][j] * isPop[i].out;

      trace[i][j] <== temp1[i][j] + temp4[i][j];
    }
  }

  log(trace[3][0]);
  log(trace[3][1]);

  component multiplexer = Multiplexer(maxStackHeight, maxSteps);
  multiplexer.inp <== trace;
  multiplexer.sel <== row;

  signal selectedRow[maxStackHeight] <== multiplexer.out;

  component quinSelector = QuinSelector(maxStackHeight);
  quinSelector.inp <== selectedRow;
  quinSelector.selector <== column;

  quinSelector.out === value;

}

component main = StackPushNopPop(5, 5);