const unique = (e, i, a) => i === a.indexOf(e)

function inherit(cl, key) {
  if (!cl.parent) return cl[key]
  return [...cl[key], ...inherit(cl.parent, key)].filter(unique)
}

export default function shortener(obj) {

  // convert classes array to object
  obj.classes = Object.fromEntries(obj.classes.map(cl => [cl.name, cl]))
  const cls = obj.classes

  // direct link of parent class
  for (const name in cls) cls[name].parent = cls[cls[name].parent]

  // inherit attributes, operators and methods
  for (const name in cls) {
    const cl = cls[name]
    cl.attributes = inherit(cl, "attributes")
    cl.operators = inherit(cl, "operators")
    cl.methods = inherit(cl, "methods")
  }

  // convert attributes, operators and methods to set
  for (const name in cls) {
    const cl = cls[name]
    cl.attributes = Object.fromEntries(cl.attributes.map(({ name }) => [name, true]))
    cl.methods = Object.fromEntries(cl.methods.map(({ name }) => [name, true]))
    cl.operators = Object.fromEntries(cl.operators.map(({ name }) => [name, true]))
  }

  // limit classes to methods, attributes and operators
  for (const name in cls) {
    const { methods, attributes, operators } = cls[name]
    cls[name] = { methods, attributes, operators }
  }

  // cleanup
  delete obj.events
  delete obj.concepts
  delete obj.defines
  delete obj.global_objects
  delete obj.global_functions

  return obj
}