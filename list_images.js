const fs = require('fs');

const hFiles = fs.readdirSync('F:/App/KHTL/horizontal');
const vFiles = fs.readdirSync('F:/App/KHTL/vertical');

console.log('Horizontal count:', hFiles.length);
console.log('Vertical count:', vFiles.length);

console.log('\n--- First 20 Horizontal ---');
hFiles.slice(0, 20).forEach(f => console.log(f));

console.log('\n--- First 20 Vertical ---');
vFiles.slice(0, 20).forEach(f => console.log(f));
