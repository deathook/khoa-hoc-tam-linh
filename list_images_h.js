const fs = require('fs');

const hFiles = fs.readdirSync('F:/App/KHTL/horizontal');
console.log('Sample from middle of horizontal:');
console.log(hFiles.slice(25, 45));
console.log('\nSample from end of horizontal:');
console.log(hFiles.slice(-25));
