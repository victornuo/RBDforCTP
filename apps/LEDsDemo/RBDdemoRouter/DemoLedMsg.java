/**
 * This class is automatically generated by mig. DO NOT EDIT THIS FILE.
 * This class implements a Java interface to the 'DemoLedMsg'
 * message type.
 */

public class DemoLedMsg extends net.tinyos.message.Message {

    /** The default size of this message type in bytes. */
    public static final int DEFAULT_MESSAGE_SIZE = 2;

    /** The Active Message type associated with this message. */
    public static final int AM_TYPE = 137;

    /** Create a new DemoLedMsg of size 2. */
    public DemoLedMsg() {
        super(DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /** Create a new DemoLedMsg of the given data_length. */
    public DemoLedMsg(int data_length) {
        super(data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new DemoLedMsg with the given data_length
     * and base offset.
     */
    public DemoLedMsg(int data_length, int base_offset) {
        super(data_length, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new DemoLedMsg using the given byte array
     * as backing store.
     */
    public DemoLedMsg(byte[] data) {
        super(data);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new DemoLedMsg using the given byte array
     * as backing store, with the given base offset.
     */
    public DemoLedMsg(byte[] data, int base_offset) {
        super(data, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new DemoLedMsg using the given byte array
     * as backing store, with the given base offset and data length.
     */
    public DemoLedMsg(byte[] data, int base_offset, int data_length) {
        super(data, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new DemoLedMsg embedded in the given message
     * at the given base offset.
     */
    public DemoLedMsg(net.tinyos.message.Message msg, int base_offset) {
        super(msg, base_offset, DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new DemoLedMsg embedded in the given message
     * at the given base offset and length.
     */
    public DemoLedMsg(net.tinyos.message.Message msg, int base_offset, int data_length) {
        super(msg, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
    /* Return a String representation of this message. Includes the
     * message type name and the non-indexed field values.
     */
    public String toString() {
      String s = "Message <DemoLedMsg> \n";
      try {
        s += "  [nodeDest=0x"+Long.toHexString(get_nodeDest())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [value=0x"+Long.toHexString(get_value())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      return s;
    }

    // Message-type-specific access methods appear below.

    /////////////////////////////////////////////////////////
    // Accessor methods for field: nodeDest
    //   Field type: short, unsigned
    //   Offset (bits): 0
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'nodeDest' is signed (false).
     */
    public static boolean isSigned_nodeDest() {
        return false;
    }

    /**
     * Return whether the field 'nodeDest' is an array (false).
     */
    public static boolean isArray_nodeDest() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'nodeDest'
     */
    public static int offset_nodeDest() {
        return (0 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'nodeDest'
     */
    public static int offsetBits_nodeDest() {
        return 0;
    }

    /**
     * Return the value (as a short) of the field 'nodeDest'
     */
    public short get_nodeDest() {
        return (short)getUIntBEElement(offsetBits_nodeDest(), 8);
    }

    /**
     * Set the value of the field 'nodeDest'
     */
    public void set_nodeDest(short value) {
        setUIntBEElement(offsetBits_nodeDest(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'nodeDest'
     */
    public static int size_nodeDest() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'nodeDest'
     */
    public static int sizeBits_nodeDest() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: value
    //   Field type: short, unsigned
    //   Offset (bits): 8
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'value' is signed (false).
     */
    public static boolean isSigned_value() {
        return false;
    }

    /**
     * Return whether the field 'value' is an array (false).
     */
    public static boolean isArray_value() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'value'
     */
    public static int offset_value() {
        return (8 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'value'
     */
    public static int offsetBits_value() {
        return 8;
    }

    /**
     * Return the value (as a short) of the field 'value'
     */
    public short get_value() {
        return (short)getUIntBEElement(offsetBits_value(), 8);
    }

    /**
     * Set the value of the field 'value'
     */
    public void set_value(short value) {
        setUIntBEElement(offsetBits_value(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'value'
     */
    public static int size_value() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'value'
     */
    public static int sizeBits_value() {
        return 8;
    }

}
