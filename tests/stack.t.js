const chai = require('chai');
const { wasm } = require('circom_tester');
const path = require("path");
const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);
const chaiAsPromised = require("chai-as-promised");
const wasm_tester = require("circom_tester").wasm;

chai.use(chaiAsPromised);
const expect = chai.expect;


describe("Stack Test", function (){
    this.timeout(100000);

    it("Should model addition", async() => {
        const circuit = await wasm_tester(path.join(__dirname,"../circuits","Stack.circom"));

        await circuit.loadConstraints();
        
        // 1
        // 1 2
        // 1 2
        // 1 2 4
        expect(await circuit.calculateWitness({
          instructions: [1, 1, 0, 1],
          values: [1, 2, 3, 4],
          row: 3,
          column: 2,
          value: 4
        }, true)).to.be.ok;

    });
});
