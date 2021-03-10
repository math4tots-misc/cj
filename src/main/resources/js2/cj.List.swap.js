function cj$List$swap(self, i, j) {
    const tmp = self[i];
    self[i] = self[j];
    self[j] = tmp;
}
