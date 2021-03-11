function cj$Iterator$nextOrElse(self, f) {
    const { done, value } = self.next();
    return done ? f() : value;
}
