import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const css = fs.readFileSync(path.join(root, 'app/globals.css'), 'utf8');
const shell = fs.readFileSync(path.join(root, 'app/components.js'), 'utf8');
const anaShell = fs.readFileSync(path.join(root, 'components/anaira/AnairaShell.jsx'), 'utf8');

const checks = [
  ['responsive v2 CSS present', css.includes('ANAIRA RESPONSIVE PRO v2')],
  ['mobile navigation toggle present', shell.includes('mobile-nav-toggle')],
  ['mobile navigation backdrop present', shell.includes('mobile-nav-backdrop')],
  ['sidebar open state present', shell.includes("' is-open'")],
  ['navigation closes on pathname change', shell.includes('setMobileNavOpen(false)')],
  ['Anaira platform mobile menu present', anaShell.includes('anaira-mobile-menu')],
  ['tablet grid fallback present', css.includes('repeat(2,minmax(0,1fr)) !important')],
  ['mobile grid fallback present', css.includes('grid-template-columns:minmax(0,1fr) !important')],
  ['modal viewport safety present', css.includes('calc(100vw - 20px)')],
];

let failed = 0;
for (const [name, ok] of checks) {
  console.log(`${ok ? 'PASS' : 'FAIL'} ${name}`);
  if (!ok) failed++;
}
console.log(`Responsive static checks: ${checks.length - failed}/${checks.length} PASS`);
process.exitCode = failed ? 1 : 0;
