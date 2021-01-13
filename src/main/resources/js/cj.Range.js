class MC$cj$Range {
    M$of(start, end) {
        return this.iter([start, end, start <= end ? 1 : -1]);
    }
    M$upto(end) {
        return this.iter([0, end, 1]);
    }
    M$withStep(start, end, step) {
        if (step === 0) {
            throw new Error("Range does not permit '0' step");
        }
        return this.iter([start, end, step]);
    }
    *iter(range) {
        const [start, end, step] = range;
        if (step >= 0) {
            for (let i = start; i < end; i += step) {
                yield i;
            }
        } else {
            for (let i = start; i > end; i += step) {
                yield i;
            }
        }
    }
}
