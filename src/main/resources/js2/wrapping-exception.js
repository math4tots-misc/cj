class WrappingException extends Error {
    constructor(typeId, data) {
        super(data);
        this.typeId = typeId;
        this.data = data;
    }
}
