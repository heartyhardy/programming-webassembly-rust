const wasm = import('./bindgenhello');

wasm
    .then(h=> h.hello("World WASM!"))
    .catch(console.error);