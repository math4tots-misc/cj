class MC$cj$Promise {
    M$done() {}
    M$then(self, f) { return self.then(f); }
    M$map(self, f) { return self.then(f); }
    M$flatMap(self, f) { return self.then(f); }
}
