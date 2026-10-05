import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const exts = ['', '.js', '.jsx', '.mjs', '.ts', '.tsx', '.json'];
const sourceExts = new Set(['.js','.jsx','.mjs','.ts','.tsx']);
const importRe = /(?:from\s+|import\s*\()(['"])(\.\.?\/[^'"]+)\1/g;
const failures = [];

function existsModule(base) {
  return exts.some(ext => fs.existsSync(base + ext) && fs.statSync(base + ext).isFile()) ||
    exts.some(ext => fs.existsSync(path.join(base, `index${ext}`)) && fs.statSync(path.join(base, `index${ext}`)).isFile());
}
function walk(dir) {
  for (const ent of fs.readdirSync(dir, {withFileTypes:true})) {
    if (['node_modules','.next','.git'].includes(ent.name)) continue;
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) walk(p);
    else if (sourceExts.has(path.extname(ent.name))) {
      const text = fs.readFileSync(p,'utf8');
      let m;
      while ((m = importRe.exec(text))) {
        const spec = m[2];
        const base = path.normalize(path.join(path.dirname(p), spec));
        if (!existsModule(base)) failures.push({file:path.relative(root,p), import:spec, resolved:path.relative(root,base)});
      }
    }
  }
}
walk(root);
const result = {checked_at:new Date().toISOString(), failures, passed:failures.length===0};
fs.mkdirSync(path.join(root,'docs'),{recursive:true});
fs.writeFileSync(path.join(root,'docs/RELATIVE_IMPORT_AUDIT.json'), JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify(result,null,2));
process.exitCode = result.passed ? 0 : 1;
