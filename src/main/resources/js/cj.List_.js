class MC$cj$List_ {
    M$empty(TV$T) {
        return [];
    }
    M$ofSize(TV$T, size, f) {
        const list = [];
        for (let i = 0; i < size; i++) {
            list.push(f(i));
        }
        return list;
    }
}
