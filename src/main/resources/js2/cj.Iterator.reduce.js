//!! cj.Iterator.fold.js
function cj$Iterator$reduce(self, f) {
    const { done, start } = self.next();
    if (done) {
        throw new Error("Reduce on an empty iterator");
    }
    return cj$Iterator$fold(self, start, f);
}
