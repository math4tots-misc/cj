package crossj.base;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Iterator;

/**
 * Container for playing with raw bytes
 *
 * By default, assumes little endian for all operations, but will flip to big
 * endian if 'setBigEndian(true)' is called.
 */
public final class Bytes {
    private ByteBuffer buffer;

    private static int u8ToI8(int u8) {
        return Int.toI8(u8);
    }

    private static int i8ToU8(int i8) {
        return Int.toU8(i8);
    }

    private static int u16ToI16(int u16) {
        return Int.toI16(u16);
    }

    private static int i16ToU16(int i16) {
        return Int.toU16(i16);
    }

    private Bytes(ByteBuffer buffer, int size) {
        this.buffer = buffer;
        buffer.limit(size);
        buffer.order(ByteOrder.LITTLE_ENDIAN);
    }

    static Bytes fromByteBuffer(ByteBuffer buffer) {
        return new Bytes(buffer, buffer.limit());
    }

    public static Bytes withCapacity(int capacity) {
        if (capacity < 16) {
            capacity = 16;
        }
        return new Bytes(ByteBuffer.allocate(capacity), 0);
    }

    public static Bytes withSize(int size) {
        return new Bytes(ByteBuffer.allocate(size), size);
    }

    public static Bytes ofU8s(int... u8s) {
        Bytes bytes = withCapacity(u8s.length);
        for (int b : u8s) {
            bytes.addU8(b);
        }
        return bytes;
    }

    public static Bytes ofI8s(int... i8s) {
        Bytes bytes = withCapacity(i8s.length);
        for (int b : i8s) {
            bytes.addI8(b);
        }
        return bytes;
    }

    public static Bytes ofI32LEs(int... i32les) {
        Bytes bytes = withCapacity(i32les.length * 4);
        for (int b : i32les) {
            bytes.addI32(b);
        }
        return bytes;
    }

    public static Bytes ofI32BEs(int... i32bes) {
        Bytes bytes = withCapacity(i32bes.length * 4);
        bytes.useLittleEndian(false);
        for (int b : i32bes) {
            bytes.addI32(b);
        }
        return bytes;
    }

    public static Bytes wrapByteArray(byte[] array) {
        return new Bytes(ByteBuffer.wrap(array), array.length);
    }

    public static Bytes fromI8s(List<Integer> i8s) {
        Bytes bytes = withCapacity(i8s.size());
        for (int b : i8s) {
            bytes.addI8(b);
        }
        return bytes;
    }

    public static Bytes fromU8s(List<Integer> u8s) {
        Bytes bytes = withCapacity(u8s.size());
        for (int b : u8s) {
            bytes.addU8(b);
        }
        return bytes;
    }

    public static Bytes fromI32LEs(List<Integer> i32les) {
        Bytes bytes = withCapacity(i32les.size() * 4);
        for (int i32le : i32les) {
            bytes.addI32(i32le);
        }
        return bytes;
    }

    public static Bytes fromI32BEs(List<Integer> i32bes) {
        Bytes bytes = withCapacity(i32bes.size() * 4);
        bytes.useLittleEndian(false);
        for (int i32be : i32bes) {
            bytes.addI32(i32be);
        }
        return bytes;
    }

    public static Bytes fromASCII(String data) {
        Bytes bytes = withCapacity(data.length());
        for (int i = 0; i < data.length(); i++) {
            bytes.addI8(data.charAt(i));
        }
        return bytes;
    }

    public int size() {
        return buffer.limit();
    }

    private int capacity() {
        return buffer.capacity();
    }

    private void setNewSize(int newSize) {
        int oldSize = buffer.limit();
        int cap = capacity();
        if (cap < newSize) {
            int newCap = newSize * 2;

            ByteBuffer newBuffer = ByteBuffer.allocate(newCap);
            newBuffer.limit(oldSize);
            buffer.position(0);
            newBuffer.put(buffer);

            buffer = newBuffer;
        }
        buffer.limit(newSize);
    }

    public void useLittleEndian(boolean littleEndian) {
        if (littleEndian) {
            buffer.order(ByteOrder.LITTLE_ENDIAN);
        } else {
            buffer.order(ByteOrder.BIG_ENDIAN);
        }
    }

    public boolean usingLittleEndian() {
        return buffer.order().equals(ByteOrder.LITTLE_ENDIAN);
    }

    public void addF64(double value) {
        int pos = buffer.limit();
        setNewSize(pos + 8);
        buffer.putDouble(pos, value);
    }

    public void addF32(double value) {
        int pos = buffer.limit();
        setNewSize(pos + 4);
        buffer.putFloat(pos, (float) value);
    }

    public void addI8(int value) {
        int pos = buffer.limit();
        setNewSize(pos + 1);
        buffer.put(pos, (byte) value);
    }

    public void addI16(int value) {
        int pos = buffer.limit();
        setNewSize(pos + 2);
        buffer.putShort(pos, (short) value);
    }

    public void addI32(int value) {
        int pos = buffer.limit();
        setNewSize(pos + 4);
        buffer.putInt(pos, value);
    }

    public void addBytes(Bytes bytes) {
        int pos = buffer.limit();
        setNewSize(pos + bytes.size());
        buffer.position(pos);
        bytes.buffer.position(0);
        buffer.put(bytes.buffer);
    }

    public void addASCII(String ascii) {
        addBytes(Bytes.fromASCII(ascii));
    }

    public void addU8(int u8) {
        addI8(u8ToI8(u8));
    }

    public void addU16(int u16) {
        addI16(u16ToI16(u16));
    }

    public void setF64(int index, double value) {
        buffer.putDouble(index, value);
    }

    public double getF64(int index) {
        return buffer.getDouble(index);
    }

    public void setF32(int index, double value) {
        buffer.putFloat(index, (float) value);
    }

    public double getF32(int index) {
        return buffer.getFloat(index);
    }

    public void setI8(int index, int value) {
        buffer.put(index, (byte) value);
    }

    public int getI8(int index) {
        return buffer.get(index);
    }

    public void setI16(int index, int value) {
        buffer.putShort(index, (short) value);
    }

    public int getI16(int index) {
        return buffer.getShort(index);
    }

    public void setI32(int index, int value) {
        buffer.putInt(index, value);
    }

    public int getI32(int index) {
        return buffer.getInt(index);
    }

    public void setU8(int index, int u8) {
        setI8(index, u8ToI8(u8));
    }

    public int getU8(int index) {
        return i8ToU8(getI8(index));
    }

    public void setU16(int index, int u16) {
        setI16(index, u16ToI16(u16));
    }

    public int getU16(int index) {
        return i16ToU16(getI16(index));
    }

    public void setBytes(int index, Bytes bytes) {
        buffer.position(index);
        bytes.buffer.position(0);
        buffer.put(bytes.buffer);
    }

    public Bytes getBytes(int start, int end) {
        int limit = buffer.limit();
        buffer.position(start);
        buffer.limit(end);
        Bytes ret = withSize(end - start);
        ret.buffer.put(buffer.slice());
        buffer.limit(limit);
        return ret;
    }

    /**
     * Returns a list of integers representing the unsigned byte values
     *
     * @return
     */
    public List<Integer> list() {
        List<Integer> ret = List.of();
        buffer.position(0);
        for (int i = 0; i < buffer.limit(); i++) {
            ret.add(i8ToU8(buffer.get()));
        }
        return ret;
    }

    private ByteBuffer view() {
        buffer.position(0);
        return buffer.slice();
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof Bytes)) {
            return false;
        }
        Bytes other = (Bytes) obj;
        return view().equals(other.view());
    }

    public XIterator<Integer> asI8s() {
        int len = buffer.limit();
        return XIterator.fromIterator(new Iterator<Integer>() {
            int i = 0;

            @Override
            public boolean hasNext() {
                return i < len;
            }

            @Override
            public Integer next() {
                return (int) buffer.get(i++);
            }
        });
    }

    public XIterator<Integer> asU8s() {
        return asI8s().map(i8 -> i8ToU8(i8));
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("Bytes.ofU8s(");
        boolean first = true;
        for (int u8 : asU8s()) {
            if (!first) {
                sb.append(", ");
            }
            first = false;
            sb.append("" + u8);
        }
        sb.append(")");
        return sb.toString();
    }

    byte[] getByteArray() {
        byte[] array = new byte[size()];
        buffer.rewind();
        buffer.get(array);
        return array;
    }

    public ByteBuffer getUnderlyingByteBuffer() {
        return buffer;
    }

    public Bytes clone() {
        return getBytes(0, size());
    }
}
