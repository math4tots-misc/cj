class MC$cj$AIO {
    M$wait(seconds) {
        return new Promise((resolve, reject) => setTimeout(resolve, seconds * 1000));
    }
}
