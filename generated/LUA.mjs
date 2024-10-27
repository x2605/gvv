export default class LUA {
  static stringify(obj, replacer, space = 0) {
    const nl = space ? "\n" : "";
    const sp = " ".repeat(space);
    const nlsp = nl + sp;
    const sep = `,${nlsp}`;

    if (Array.isArray(obj)) {
      if (obj.length === 0) return '{}'
      const ctn = obj.map(e => LUA.stringify(e).replaceAll(nl, nlsp)).join(sep)
      return `{${nlsp}${ctn}${nl}}`;
    } else if (typeof obj === 'object') {
      if (Object.keys(obj).length === 0) return '{}'
      const ctn = Object.entries(obj).map(([key, value]) =>
        `${key}=${LUA.stringify(value, replacer, space).replaceAll(nl, nlsp)}`
      ).join(sep)
      return `{${nlsp}${ctn}${nl}}`;
    } else {
      return JSON.stringify(obj);
    }
  }
}