import ctypes
from ctypes.wintypes import DWORD
import pathlib
import os
import time
import ftd2xx
from ftd2xx import FTD2XX
import subprocess
from subprocess import CalledProcessError, check_output
import re

class UsbPio:
    def __init__(self):
        if False:
            self.usbPioDll = ctypes.CDLL(r'C:\Tcl\lib\RL\RLDUsPio')
            self.getChs = self.usbPioDll['RLDLLGetUsbChannels']
            retval = self.getChs()
            print(f'retval:{retval}')
            self.openPio = self.usbPioDll['RLDLLOpenUsbPio']
            self.setPio = self.usbPioDll['RLDLLSetUsbPio']
            self.getPio = self.usbPioDll['RLDLLGetUsbPio']
            self.setCnfPio = self.usbPioDll['RLDLLConfigUsbPio']
            self.closePio = self.usbPioDll['RLDLLCloseUsbPio']
            self.rstPio = self.usbPioDll['RLDLLResetUsbPio']
            self.closeCurPio = self.usbPioDll['RLDLLCloseAllCurrentUsbPio']
            self.closeAllPio = self.usbPioDll['RLDLLCloseAllUsbPio']

        self.pio_port_id = {}

    def retrive_usb_channel(self, box):
        # arr = str(check_output(r'c:\\tcl\\bin\\wish86.exe d:\\StarPacks\\Ilya\\PioUsb\\pio_usb_scr.tcl RetriveUsbChannel'),
        #           'utf-8')
        arr = str(
            check_output(r'c:\\tcl\\bin\\wish86.exe pio_usb_scr.tcl RetriveUsbChannel'),
            'utf-8')
        # arr = str(check_output(r'd:\\StarPacks\Ilya\PioUsb\pio_usb.exe RetriveUsbChannel'), 'utf-8')
        lst = arr.split(" ")
        # print(f'retrive_usb_channel lst:{lst}')
        it_lst = iter(lst)
        channel = None
        for a in it_lst:
            if re.search('SerialNumber', a) and next(it_lst) == box:
                channel = a.split(',')[0]
                # print(f'a:{a} channel:{channel}')
                break
        # print(f'retrive_usb_channel channel:{channel}')
        return channel


    def get_devces(self):
        ld = []
        # listDevices = ftd2xx.listDevices()
        # print(f"get_devces listDevices:{listDevices}")
        for dev in ftd2xx.listDevices():
            dev_str = str(dev, 'utf-8')
            if dev_str != "":
                # print(f"{dev} {str(dev, 'utf-8')}")
                ld.append(dev_str)
        # print(ld)
        return ld

    def osc_pio(self, channel, port, group, value, state='00000000'):
        # print(f'rlusbpio osc_pio self:{self} channel:{channel} port:{port} group:{group} value:{value} state:{state}')

        # RLUsbPio::Open $rb RBA $channel
        # RLUsbPio::Set $gaSet(idPwr$pio) 1
        # RLUsbPio::Close $gaSet(idPwr$rb)

        lin = f'c:\\tcl\\bin\\wish86.exe pio_usb_scr.tcl OpenSetClose {channel} {port} {group} "{value}" {state}'
        # lin = f'c:\\tcl\\bin\\wish86.exe d:\\StarPacks\\Ilya\PioUsb\\pio_usb_scr.tcl OpenSetClose {channel} {port} {group} "{value}" {state}'
        # lin = f'd:\\StarPacks\\Ilya\\PioUsb\\pio_usb.exe OpenSetClose {channel} {port} {group} "{value}" {state}'
        ret = str(check_output(lin), 'utf-8')
        # print(f'rlusbpio osc_pio ret:{ret}')
        return ret

    def open_pio(self, port, group, channel):
        # print(f'rlusbpio open_pio self:{self}')
        # RLUsbPio::Open $rb RBA $channel
        print(f'rlusbpio open_pio port:{port} group:{group} channel:{channel}')
        lin = f'd:\\StarPacks\\Ilya\\PioUsb\\pio_usb.exe RLUsbPio::Open {port} {group} {channel}'
        id = str(check_output(lin), 'utf-8')
        print(f'rlusbpio open_pio id:{id}')
        # handler = self.openPio(n_pioport, n_portsgroup, n_cardnumber)
        # self.pio_port_id[handler] = (n_pioport, n_portsgroup, n_cardnumber)
        # self.pio_port_id[handler] = (handler)
        return id

    def config_pio(self, handler, state):
        # setCnfPio(in_port, 255, nCardNumber)  # in_port as IN
        # setCnfPio(out_port, 0, nCardNumber)  # out_port as OUT
        port, group, cardnumber = self.pio_port_id[handler]
        ret = self.setCnfPio(port, group, state, cardnumber)
        # print(f'config_pio handler:{handler}, state:{state}, ret:{ret}')
        return ret

    def set_pio(self, id, state):
        print(f'rlusbpio set_pio self:{self} id:"{id}" state:{state}')
        # port, group, cardnumber =  self.pio_port_id[handler]
        # # print(f'rlusbpio set_pio handler:{handler}, state:{state}, port:{port}, group:{group}, cardnumber:{cardnumber}')
        # ret = self.setPio(port, group, state, cardnumber)
        # # print(f'set_pio handler:{handler}, state:{state}, ret:{ret}')
        # id = self.pio_port_id[handler]

        lin = f'd:\\StarPacks\\Ilya\\PioUsb\\pio_usb.exe RLUsbPio::Set "{id}" {state}'
        ret = str(check_output(lin), 'utf-8')
        print(f'set_pio id:{id}, ret:{ret}')
        return ret

    def close_pio(self, id):
        print(f'rlusbpio close_pio self:{self} id:"{id}"')
        # port, group, cardnumber = self.pio_port_id[handler]
        # # ret = self.closePio(port, group, cardnumber)
        # ret = self.closeAllPio()
        lin = f'd:\\StarPacks\\Ilya\\PioUsb\\pio_usb.exe RLUsbPio::Close \"{id}\"'
        ret = str(check_output(lin), 'utf-8')
        print(f'close_pio id:{id}, ret:{ret}')
        return ret
