import pyvisa
import re
import sys

class IP6900:
    def __init__(self, ser_num):
        self.ser_num = ser_num
        self.visa_addr = None
        self.inst = None
        
    def open_instr(self):
        try:
            rm = pyvisa.ResourceManager()
        except Exception as error:
            print(f'open_instr error: {error}')
            return False
            
        resources = rm.list_resources()
        if self.ser_num == 'get_list':
            print(f'{resources}')
            return True
            
        for resource in resources:            
            if re.search(self.ser_num, resource):
                self.visa_addr = resource
                break
        if self.visa_addr:
            self.inst = rm.open_resource(self.visa_addr)
            self.inst.read_termination = "\n"
            return True
        else:
            print(f'No communication to {ser_num}')
            return False
            
    def close_instr(self):
        self.inst.close() 
    
    def exec_cmd(self, cmd, par):
        print(f'cmd:{cmd} par:{par}')
        ret = self.inst.write('*cls')
        #print(f'ret:{ret}')
        ret = None
        if cmd == 'query':
            ret = self.inst.query(par)
        elif cmd == 'write':
            ret = self.inst.write(par)
        elif cmd == 'read':
            ret = self.inst.read(par)
            
        print(f'{ret}')
        return ret
         
         
'''
    set ret [exec python.exe lib_IT6900.py get_list stam stam"]
    set ret [exec python.exe lib_IT6900.py 800772011796710024 write "*cls"]
    set ret [exec python.exe lib_IT6900.py 800772011796710024 write "*rst"]
    set ret [exec python.exe lib_IT6900.py 800772011796710024 write "outp 0"]
    set ret [exec python.exe lib_IT6900.py 800772011796710024 write "volt 11"]
    set ret [exec python.exe lib_IT6900.py 800772011796710024 write "outp 1"]
    
    set ret [exec python.exe lib_IT6900.py 800772011796710024 query *idn?]
    set ret [exec python.exe lib_IT6900.py 800772011796710024 query meas:curr?]
    set ret [exec python.exe lib_IT6900.py 800772011796710024 write "volt 11"]
    set ret [exec python.exe lib_IT6900.py 800772011796710024 query meas:volt?]
'''
if __name__ == '__main__':
    #print(sys.argv)
    ser_num = sys.argv[1]
    cmd = sys.argv[2]
    par = sys.argv[3]
    
    inst = IP6900(ser_num)
    if inst.open_instr():
        if ser_num != 'get_list':
            inst.exec_cmd(cmd, par)
            inst.close_instr()
    