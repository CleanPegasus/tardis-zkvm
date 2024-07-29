pragma circom 2.1.6;

// Dot product
template EscalarProduct(w) {
    signal input in1[w];
    signal input in2[w];
    signal output out;
    signal aux[w];
    var lc = 0;
    for (var i=0; i<w; i++) {
        aux[i] <== in1[i]*in2[i];
        lc = lc + aux[i];
    }
    out <== lc;
}

template Decoder(w) {
    signal input inp;
    signal output out[w];
    signal output success;
    var lc=0;

    for (var i=0; i<w; i++) {
        out[i] <-- (inp == i) ? 1 : 0;
        out[i] * (inp-i) === 0;
        lc = lc + out[i];
    }

    lc ==> success;
    success * (success -1) === 0;
}

template QuinSelector(n) {
  signal input inp[n];
  signal input selector;
  signal output out;

  component decoder = Decoder(n);
  decoder.inp <== selector;

  component scalar_product = EscalarProduct(n);
  scalar_product.in1 <== inp;
  scalar_product.in2 <== decoder.out;

  out <== scalar_product.out;
}

template Multiplexer(wIn, nIn) {
    signal input inp[nIn][wIn];
    signal input sel;
    signal output out[wIn];
    component dec = Decoder(nIn);
    component ep[wIn];

    for (var k=0; k<wIn; k++) {
        ep[k] = EscalarProduct(nIn);
    }

    sel ==> dec.inp;
    for (var j=0; j<wIn; j++) {
        for (var k=0; k<nIn; k++) {
            inp[k][j] ==> ep[j].in1[k];
            dec.out[k] ==> ep[j].in2[k];
        }
        ep[j].out ==> out[j];
    }
    dec.success === 1;
}

// template QuinSelector2(r, c) {
//   signal input in[r][c];
//   signal input row;
//   signal input column;

//   signal output out;

//   component rowDecoder = Decoder(r);
//   rowDecoder.in <== row;

//   component columnDecoder = Decoder(c);
//   columnDecoder.in <== column;

//   var acc;
//   signal selector[r*c];
//   for(var i; i<r; i++) {
//     for(var j; j<c; j++) {
//       selector[i * j] <== rowDecoder.out[i] * columnDecoder.out[j]
//       acc += in[i][j] * selector[i * j];
//     }
//   }
//   out <== acc;
// }
