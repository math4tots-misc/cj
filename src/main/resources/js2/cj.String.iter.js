function *cj$String$iter(self) {
    for (let i = 0; i < self.length; i++) {
        const c = self.codePointAt(i);
        yield c;
        if (self.charCodeAt(i) !== c) {
            i++;
        }
    }
}
