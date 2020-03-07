const wasm = import('./bindgenhello');

wasm
    .then(h => h.hello("WASM!"))
    .catch(console.error);