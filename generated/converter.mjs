// need node.js 22.0.0 or later
import fs from 'fs';
import patcher from './patcher.mjs';
import shortener from './shortener.mjs';
import LUA from './LUA.mjs';

const [jsonFile] = process.argv.slice(2);
if (!jsonFile) {
  console.log('Usage: node converter.mjs <json file>');
  process.exit(1);
}

const raw = fs.readFileSync(jsonFile, 'utf8')

const data = JSON.parse(raw)
const patched = patcher(data);
const shortened = shortener(patched)
const serialized = 'return ' + LUA.stringify(shortened, null, 2);

const luaFile = jsonFile.replace(/\.json$/, '.lua');
fs.writeFileSync(luaFile, serialized);

console.log(`Conversion done from ${jsonFile} to ${luaFile}`);