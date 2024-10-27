// convert a json file to a lua file
// Usage: node converter.js <json file>
// example:
// {"a": 1, "b": 2}
// to
// return {["a"]=1, ["b"]=2}

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
if (args.length < 1) {
  console.log('Usage: node converter.js <json file>');
  process.exit(1);
}

const remove=(keys)=>(obj)=>{
  for(key of keys) delete obj[key]
  return obj
}

const exact=(keys)=>{
  const ks=new Set(keys)
  return (obj)=>{
    const os=new Set(Object.keys(obj))
    if(!os.isSubsetOf(ks)) console.log(os.difference(ks))
    return obj
  }
}
const unique=(e,i,a)=>i===a.indexOf(e)
function inherit(cl,key){
  if(!cl.parent) return cl[key]
  return [...cl[key], ...inherit(cl.parent,key)].filter(unique)
}

function shortener(obj){
  delete obj.events
  delete obj.concepts
  delete obj.defines
  delete obj.global_objects
  delete obj.global_functions
  
  obj.classes=Object.fromEntries(obj.classes.map(cl=>[cl.name, cl]))
  const cls=obj.classes

  for(const name in cls) cls[name].parent=cls[cls[name].parent]
  
  for(const name in cls){
    const cl = cls[name]
    cl.attributes=inherit(cl,"attributes")
    cl.operators=inherit(cl,"operators")
    cl.methods=inherit(cl,"methods")
  }
  for(const name in cls){
    const cl = cls[name]
    cl.attributes=Object.fromEntries(cl.attributes.map(({name}) => [name,true]))
    cl.methods=Object.fromEntries(cl.methods.map(({name}) => [name,true]))
    cl.operators=Object.fromEntries(cl.operators.map(({name}) => [name,true]))
  }
  for(const name in cls){
    const {methods,attributes,operators} = cls[name]
    cls[name]={ methods, attributes, operators }
  }
  return obj
}

class LUA {
  static stringify(obj,replacer,space=0) {
    const nl=space?"\n":"";
    const sp=" ".repeat(space);
    const nlsp=nl+sp;
    const sep=`,${nlsp}`;
    
    if (Array.isArray(obj)) {
      if(obj.length===0) return '{}'
      const ctn=obj.map(e=>LUA.stringify(e).replaceAll(nl,nlsp)).join(sep)
      return `{${nlsp}${ctn}${nl}}`;
    } else if (typeof obj === 'object') {
      if(Object.keys(obj).length===0) return '{}'
      const ctn=Object.entries(obj).map(([key,value]) => 
        `${key}=${LUA.stringify(value,replacer,space).replaceAll(nl,nlsp)}`
      ).join(sep)
      return `{${nlsp}${ctn}${nl}}`;
    } else {
      return JSON.stringify(obj);
    }
  }
}

const jsonFile = args[0];
const luaFile = args[0];

const content=JSON.parse(fs.readFileSync(jsonFile, 'utf8'))
const min=shortener(content)
min.classes=Object.fromEntries(
  Object.entries(min.classes)
)
fs.writeFileSync(jsonFile.replace(/\.json$/, '.lua'), 'return ' + LUA.stringify(min,null,2));
process.exit(0);
