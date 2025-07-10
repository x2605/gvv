export default function (obj) {
  conceptToClasses(obj, "DifficultySettings", "LuaDifficultySettings")
  conceptToClasses(obj, "GameViewSettings", "LuaGameViewSettings")
  conceptToClasses(obj, "MapSettings", "LuaMapSettings")

  return obj
}

function conceptToClasses(obj, conceptName, classeName) {
  const concept = obj.concepts.find(c => c.name === conceptName)
  if (!concept) return
  const classe = structuredClone(concept.type)
  classe.name = classeName
  classe.attributes ??= classe.parameters
  classe.methods ??= []
  classe.operators ??= []
  obj.classes.push(classe)
}