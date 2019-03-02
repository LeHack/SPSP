import logging
import time
from bluepy.btle import Peripheral, BTLEException
from bitstring import BitArray
from enum import Enum
from time import sleep


class BTHandler:
    logger      = logging.getLogger('API.BTHandler')
    addr        = None
    connected   = False
    device      = None
    control     = None
    guid        = 1
    auto_reset_uid = False

    class CmdDataType(Enum):
        STRING = 1
        NUMBER = 2
        SIGNED = 3
        RECORD = 4
        STORED = 5

    class UnknownDataType(BaseException):
        pass

    class CommandTimeout(TimeoutError):
        pass

    def __init__(self, addr, reset_uid_on_connect=False):
        self.addr = addr
        self.auto_reset_uid = reset_uid_on_connect

    def connect(self):
        try:
            if not self.connected:
                self.logger.debug("Connecting to device at: " + str(self.addr))
            else:
                self.logger.debug("Re-connecting to device at: " + str(self.addr))
            self.device = Peripheral(self.addr, iface=0)
            # self.dump_bt_state(per)
            service = self.device.getServiceByUUID("0cc3e289-7a82-448e-bd8b-9d3552f53800")
            self.control = service.getCharacteristics("0cc3e289-7a82-448e-bd8b-9d3552f5380a")[0]
            self.data = []
            for i in range(1, 9):
                self.data.append(service.getCharacteristics("0cc3e289-7a82-448e-bd8b-9d3552f5380" + str(i))[0])

            self.connected = True

            # TODO: Remove after we hook up the new board with active BT connection pin
            if self.auto_reset_uid:
                '''
                    Auto-Reset UID
                    This will break communications if multiple API instances will be working at the same time.
                '''
                self.send_cmd("RESETUID", uid=0)
                self.guid = 1
        except Exception as e:
            self.cleanup()
            raise e

    def cleanup(self):
        if not self.connected:
            return

        self.logger.debug("Disconnecting from device at: " + str(self.addr))
        self.connected = False
        if self.device:
            self.device.disconnect()

    def dump_bt_state(self):
        if not self.connected:
            self.connect()

        for s in self.device.getServices():
            print("Service %s:" % str(s.uuid))
            for c in s.getCharacteristics():
                print("Characteristic %s: %s" % (str(c.uuid), c.propertiesToString()))
                if c.supportsRead():
                    try:
                        print("\tvalue: %s" % c.read())
                    except BTLEException:
                        pass

    def print_data_records(self, data):
        print("Base timestamp: %d" % (data['timestamp']))
        for r in data['records']:
            print("Offset: %02d [s]\tPressure: %04d [hPa]\tHumidity: %02d [%%]\tTemperature: %02d [C]\tPM10: %03d [ug/m3]" % (r['offset'], r['pressure'], r['humidity'], r['temperature'], r['pm10']))

    def build_cmd(self, command, arg, uid, data_type):
        cmd = command.encode(encoding="utf-8")
        if len(command) < 10:
            cmd += bytes(10 - len(command))
        # add data padding
        if arg is None:
            cmd += int(0).to_bytes(8, byteorder='big')
        elif data_type is self.CmdDataType.NUMBER or data_type is self.CmdDataType.RECORD:
            cmd += int(arg).to_bytes(8, byteorder='big')
        elif data_type is self.CmdDataType.SIGNED:
            cmd += int(arg).to_bytes(8, byteorder='big', signed=True)
        elif data_type is self.CmdDataType.STRING:
            cmd += self.str2bit(arg)
        elif data_type is self.CmdDataType.STORED:
            ba = BitArray()
            ba += [0] * 38
            ba.append( BitArray( int(arg['resolution']).to_bytes(1, byteorder='big') )[2:] )
            ba.append( BitArray( int(arg['offset']).to_bytes(3, byteorder='big') )[4:] )
            cmd += ba.tobytes()
        else:
            self.logger.debug("Unhandled data type: %s" % (str(data_type)))
            raise self.UnknownDataType("Unhandled data type: %s" % str(data_type))

        # add index
        cmd += uid.to_bytes(2, byteorder='big')

        return cmd

    def send_cmd(self, command, arg=0, uid=None, data_type=CmdDataType.NUMBER):
        r = None
        retries = 3
        if uid is None:
            uid = self.guid
            self.guid = uid + 1

        if command == "RESETUID":
            self.guid = 1

        # auto-connect
        if not self.connected:
            self.connect()

        self.logger.debug("Executing command: %s, arg: %s, uid: %s" % (command, str(arg), str(uid)))

        while retries > 0 and r is None:
            cmd = self.build_cmd(command, arg, uid, data_type)
            try:
                self.control.write(cmd, withResponse=True)
                r = self.control.read()
                wait_time = 0
                r_uid = int.from_bytes(r[18:], byteorder='big')
                cmd_uid = int.from_bytes(cmd[18:], byteorder='big')
                while r_uid <= cmd_uid and uid != 0:
                    if wait_time > 3:
                        self.guid = cmd_uid + 1
                        r = None
                        retries -= 1
                        if retries == 0:
                            self.logger.error("Command timeout after 3 retries")
                            raise self.CommandTimeout("Command didn't respond after 3 retries")
                        break

                    wait_time += 1
                    time.sleep(.1 * wait_time)
                    r = self.control.read()
                    r_uid = int.from_bytes(r[18:], byteorder='big')

                # update guid, to use the next int value
                if r is not None:
                    self.guid = int.from_bytes(r[18:], byteorder='big') + 1
            except BTLEException as ce:
                if "Device disconnected" in repr(ce) or "Helper not started" in repr(ce):
                    # try to reconnect
                    sleep(1)
                    self.connect()
                else:
                    raise ce
            except Exception as e:
                self.cleanup()
                raise e

        return r

    def get_value(self, raw, signed=False):
        return int.from_bytes(raw, byteorder='big', signed=signed)

    def fetch_value(self, command, arg=None, uid=None, data_type=CmdDataType.NUMBER):
        r = self.send_cmd(command, arg, uid, data_type)
        out = None
        if data_type is self.CmdDataType.STRING:
            out = self.bit2str(r[10:18])
        elif data_type is self.CmdDataType.NUMBER or data_type is self.CmdDataType.STORED:
            out = self.get_value(r[10:18])
        elif data_type is self.CmdDataType.SIGNED:
            out = self.get_value(r[10:18], signed=True)
        elif data_type is self.CmdDataType.RECORD:
            out = self.parse_record(r[10:15])
            out['timestamp'] = self.get_value(r[15:18])
        else:
            self.logger.debug("Unhandled data type: %s" % (str(data_type)))
            raise self.UnknownDataType("Unhandled data type: %s" % str(data_type))

        return out

    def parse_record(self, record, warn=True):
        ba = BitArray(record)
        data = {
            'pressure':     ba[29:40].uint,
            'pm10':         ba[20:29].uint,
            'humidity':     ba[13:20].uint,
            'temperature':  ba[ 6:13].uint,
            'checksum':     ba[ 0: 6].uint,
        }
        partialsum = (42 + data['pressure'] + data['pm10'] + data['humidity'] + data['temperature'])
        checksum = partialsum % 61
        if (checksum != data['checksum']):
            data['crc_error'] = True
            if partialsum > 42 and warn:
                # only warn, where there is any data
                self.logger.warning("Warning, incorrect checksum for record: %s, expected: %s" % (repr(data), str(checksum)))

        # remove temperature offset (we have signed ints here)
        data['temperature'] -= 40

        return data

    def fetch_data(self, records = 31, warn = True, filter_invalid = False):
        # auto-connect
        if not self.connected:
            self.connect()

        self.logger.debug("Fetching %d records" % records)
        out = { 'timestamp': None, 'records': [] }
        collected = 0
        last_stamp = 0
        used_freq = None
        for ch in range(0, len(self.data)):
            raw = self.data[ch].read()
            raw_set = [raw[:5], raw[5:10], raw[10:15], raw[15:20]]

            if ch == 0:
                raw_set.pop(0)
                raw_header = BitArray(raw[:5])

                raw_stamp = BitArray("0x0") + raw_header[20:]
                last_stamp = out['timestamp'] = int.from_bytes(raw_stamp.tobytes(), byteorder='big')

                raw_freq  = BitArray([0, 0]) + raw_header[14:20]
                used_freq = out['read_frequency'] = int.from_bytes(raw_freq.tobytes(), byteorder='big')

            for raw_v in raw_set:
                rec = self.parse_record(raw_v, warn=warn)
                if filter_invalid and 'crc_error' in rec:
                    continue

                rec['timestamp'] = last_stamp
                last_stamp += used_freq
                out['records'].append(rec)

                collected += 1
                if collected >= records:
                    break
            if collected >= records:
                break

        return out

    def str2bit(self, arg):
        out = BitArray()

        for c in arg[:10]:
            out.append( BitArray( BTHandler.char2spsp(c).to_bytes(1, byteorder='big') )[2:8] )

        # make sure we always get 6 full bytes (pad with zeros)
        if len(out) < 60:
            out += [0] * (60 - len(out))

        return out.tobytes()

    def bit2str(self, arg):
        out = ""

        for b in BitArray(arg).cut(6):
            # last part is 4 bits only, so we discard it
            if b.len < 6:
                break
            v_in = b.uint
            v_out = 0
            if 1 <= v_in <= 10:
                v_out = v_in + 47
            elif 11 <= v_in <= 36:
                v_out = v_in + 54
            elif v_in == 37:
                v_out = 35
            elif 38 <= v_in <= 42:
                v_out = v_in + 5
            elif v_in == 43:
                v_out = 58
            elif v_in == 44:
                v_out = 64
            elif 45 <= v_in <= 47:
                v_out = v_in + 46
            elif v_in == 48:
                v_out = 95
            elif v_in == 49:
                v_out = 126

            if v_out > 0:
                out += chr(v_out)
            else:
                break

        return out

    @staticmethod
    def char2spsp(char):
        v_in = ord(char.upper())
        v_out = 63
        if 48 <= v_in <= 57:
            v_out = v_in - 47
        elif 65 <= v_in <= 90:
            v_out = v_in - 54
        elif v_in == 35:
            v_out = 37
        elif 43 <= v_in <= 47:
            v_out = v_in - 5
        elif v_in == 58:
            v_out = 43
        elif v_in == 64:
            v_out = 44
        elif 91 <= v_in <= 93:
            v_out = v_in - 46
        elif v_in == 95:
            v_out = 48
        elif v_in == 126:
            v_out = 49

        return v_out
