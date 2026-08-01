const z = require('zod');
const s = z.union([z.string(), z.number()]);
console.log('string:', s.safeParse('100').success);
console.log('number:', s.safeParse(100).success);
console.log('array:', s.safeParse([]).success);
console.log('version:', z.version || 'unknown');
// Also check if z.string().or() works
const s2 = z.string().or(z.number());
console.log('or-string:', s2.safeParse('100').success);
console.log('or-number:', s2.safeParse(100).success);
