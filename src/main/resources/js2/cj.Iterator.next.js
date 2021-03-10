function cj$Iterator$next(self) {
    const { done, value } = self.next();
    return done ? null : value;
}
