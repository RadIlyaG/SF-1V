import serial
import time
import re

class RLCom:
    def __init__(self, com, baudrate=9600, bytesize=8, parity='N', stopbits=1, xonxoff=0, rtscts=0,
                inter_byte_timeout=2):
        self.com = com
        self.baudrate = baudrate
        self.bytesize = bytesize
        self.parity = parity
        self.stopbits = stopbits
        self.xonxoff = xonxoff
        self.rtscts = rtscts
        self.inter_byte_timeout = inter_byte_timeout

    def open(self):
        try:
            self.ser = serial.Serial(self.com, self.baudrate, self.bytesize, self.parity,
                                self.stopbits, self.xonxoff, self.rtscts, self.inter_byte_timeout)
            self.ser.reset_input_buffer()
            self.ser.reset_output_buffer()
        except Exception as exc:
            print(f'open_com exc:{exc}')
            self.ser = False

        return self.ser

    def close(self):
        self.ser.close()

    def read(self):
        data_bytes = self.ser.in_waiting
        if data_bytes:
            return self.ser.read(data_bytes)
        else:
            return b''

    def send(self, sent, exp='', timeout=10):
        return self.my_send(sent, False, exp, timeout)

    def send_slow(self, sent, letterDelay, exp='', timeout=10):
        return self.my_send(sent, letterDelay, exp, timeout)

    def my_send(self, sent, letterDelay, exp, timeout):
        start_time = time.time()
        self.ser.reset_input_buffer()
        self.ser.reset_output_buffer()
        if letterDelay:
            for by in sent:
                self.ser.write(by.encode())
                time.sleep(letterDelay / 1000)
        else:
            self.ser.write(sent.encode())

        self.ser.flush()
        res = 0

        if exp:
            rx = ''
            res = -1
            startTime = time.time()
            while True:
                if not self.ser.writable() or not self.ser.readable():
                    self.ser.close()
                    break

                data_bytes = self.ser.in_waiting
                if data_bytes:
                    rx = rx + self.ser.read(data_bytes).decode()

                if re.search(exp, rx):
                    res = 0
                    break

                timeNow = time.time()
                runTime = timeNow - startTime
                if runTime > float(timeout):
                    break

            send_time = "--- %.7s seconds ---" % (time.time() - start_time)
            # print("--- %.7s seconds ---" % (time.time() - start_time))
            # print('<'+rx+'>')
            self.buffer = rx
            return res
        else:
            return res


def open_com(port="COM1", baudrate=9600, bytesize=8, parity='N', stopbits=1, xonxoff=0, rtscts=0,
                inter_byte_timeout=2):
    try:
        ser = serial.Serial(port, baudrate, bytesize, parity, stopbits, xonxoff, rtscts, inter_byte_timeout)
        ser.reset_input_buffer()
        ser.reset_output_buffer()
    except Exception as exc:
        print(f'open_com exc:{exc}')
        ser = False

    # ser.open()
    return ser

def close_com(ser):
    ser.close()

# rlcom.read returns buffer in bytes
def read(ser):
    data_bytes = ser.in_waiting
    if data_bytes:
        return ser.read(data_bytes)
    else:
        return b''


# rlcom.send return True if in justs sends something
# if it expects to something and it has been received - also True
# if expected did not received - the function returns False
# To achieve the buffer - use rlcom.buffer
def send(ser, sent, exp='', timeout=10):
    return _Send(ser, sent, False, exp, timeout)


def send_slow(ser, sent, letterDelay, exp='', timeout=10):
    return _Send(ser, sent, letterDelay, exp, timeout)

def _Send(ser, sent, letterDelay, exp, timeout):
    global buffer, send_time
    start_time = time.time()
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    if letterDelay:
        for by in sent:
            ser.write(by.encode())
            time.sleep(letterDelay / 1000)
    else:
        ser.write(sent.encode())

    ser.flush()
    res = 0

    if exp:
        rx = ''
        res = -1
        startTime = time.time()
        while True:
            if not ser.writable() or not ser.readable():
                ser.close()
                break

            data_bytes = ser.in_waiting
            if data_bytes:
                rx = rx + ser.read(data_bytes).decode()

            if re.search(exp, rx):
                res = 0
                break

            timeNow = time.time()
            runTime = timeNow - startTime
            if runTime > float(timeout):
                break

        send_time = "--- %.7s seconds ---" % (time.time() - start_time)
        # print("--- %.7s seconds ---" % (time.time() - start_time))
        # print('<'+rx+'>')
        buffer = rx
        return res
    else:
        return res
