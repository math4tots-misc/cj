class Base {
    toJSON() {
        const ret = {}
        for (const prop in this) {
            if (!prop.startsWith('F')) {
                throw new Error(`Invalid property name ${prop}`)
            }
            ret[prop.slice('F'.length)] = this[prop];
        }
        return ret;
    }
    toString() {
        return JSON.stringify(this);
    }
}
function panic(message) { throw new Error(message) }
