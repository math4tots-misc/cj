class MC$cj$Promise {
    M$done() {}
    M$then(self, f) { return self.then(f); }
    M$map(TV$R, self, f) { return self.then(f); }
    M$flatMap(TV$R, self, f) { return self.then(f); }
}
