import os
from datetime import datetime
import time
import asyncio
import re
import subprocess
from subprocess import CalledProcessError, check_output
import glob

from RL import Lib_RadApps

# https://petri.com/how-to-back-up-and-restore-wireless-network-profiles
# C:\Temp

def sftp_server_side():
    print(f'sftp_server_side, {my_time()}')
    loop = asyncio.get_event_loop()
    sftp_loop(loop)
    try:
        loop.run_forever()
    finally:
        loop.close()
    # loop.close()

def sftp_loop(loop):
    sftp = Lib_RadApps.Sftp('ftp.rad.co.il', 'ate', 'ate2009')
    ret = sftp.Open()
    print(f'\n\n{my_time()} sftp_loop sftp.Open ret {ret}')
    if ret is False:
        #sftp.Close()
        loop.call_later(30, sftp_loop, loop)
        return None
    
    list_files = sftp.ListOfFiles()
    # print(f'\n\n{my_time()} sftp_loop, {my_time()}, list_files:{list_files}')
    print(f'{my_time()} sftp_loop, list_files:{list_files}')
    meas = 0
    for fil in list_files:
        if re.search('startmeasur', fil):
            meas = 1
            break
    if meas == 0:
        print(f'No start_measurement')
    else:
        process = subprocess.run("netsh.exe wlan show interfaces",
                                             shell=False, check=True, stdout=subprocess.PIPE, universal_newlines=True,
                                             stderr=subprocess.PIPE)
     
        if len(list_files) > 0 :
            all_interfaces = ""
            for fil in list_files:
                if re.search('startmeasur', fil):
                    all_interfaces = process.stdout.rstrip()
                    #print(f'all_interfaces: {all_interfaces}')
                    break
                    
            list_interfaces = all_interfaces.split('\n\n')
            qty_interfaces = len(list_interfaces)
            if qty_interfaces != 9:
                print(f'\nQty of on interfaces should be 7!! Now is {qty_interfaces-2} !!!\n')
              
            pc_intf_mac_dict = {}
            for interface in all_interfaces.split('\n\n')[1:8]:
                m = re.search(f'Name[:\s]+(Wi-Fi\s?\d?)([A-Za-z0-9\\s\\#\\-\:]+)Physical address\\s+\\:\\s+([a-f0-9\:]+)\s', interface)
                m = re.search(f'Name[:\s]+(Wi-Fi\s?\d*)([A-Za-z0-9\\s\\#\\-\:]+)Physical address\\s+\\:\\s+([a-f0-9\:]+)\\s+State\\s+\\:\\s+([a-z]+)', interface)
                if m != None:
                    pc_intf_name = m.group(1).rstrip()
                    pc_intf_mac  = m.group(3).rstrip()
                    pc_intf_state  = m.group(4).rstrip()
                    print(f'"{pc_intf_name}", "{pc_intf_mac}", "{pc_intf_state}"')
                    pc_intf_mac_dict[pc_intf_mac] = pc_intf_name
                    pc_intf_mac_dict[pc_intf_name] = {}
                    pc_intf_mac_dict[pc_intf_name]["state"] = pc_intf_state
                    
                else:
                    print(f'\nbad interface:{interface}\n')
                    
            print(pc_intf_mac_dict)
            
            for fil in list_files:
                if re.search('startmeasur', fil):
                    wifi_net = fil[17:]            
                    if wifi_net == 'at-secfl1v-1-10_1':
                        rsrv_mac = '28:ee:52:1c:7b:4c'
                    elif wifi_net == 'at-secfl1v-2-10_1':
                        rsrv_mac = 'd0:37:45:6a:48:29'
                    elif wifi_net == 'at-etx1p-1-10_1':
                        rsrv_mac = '7c:c2:c6:1c:5d:10'
                    elif wifi_net == 'at-etx1p-1-10_2':
                        rsrv_mac = '7c:c2:c6:11:e1:0a'
                    elif wifi_net == 'at-secfl1v-3-10_1':
                        rsrv_mac = 'd0:37:45:6c:82:1d'
                    elif wifi_net == 'at-sf1p-1-10_1':
                        rsrv_mac = '28:ee:52:18:17:ee'
                    elif wifi_net == 'at-sf1p-1-10_2':
                        rsrv_mac = '28:ee:52:18:18:17'
                    else:
                        intf = 'NA'
                        rsrv_mac = 'NA'
                        
                    print(f'fil:{fil} rsrv_mac:{rsrv_mac}')
                        
                    try:
                        intf_name =  pc_intf_mac_dict[rsrv_mac]
                    except Exception as ex:
                        print(f'\nwrong MAC: {ex} !!!')
                        sftp.Close()
                        loop.call_later(30, sftp_loop, loop)
                        return False
                    state = pc_intf_mac_dict[intf_name]["state"]
                    print(f'\n{my_time()} sftp_loop, wifi_net:{wifi_net}, rsrv_mac:{rsrv_mac}, intf_name:{intf_name}, state:{state}')
                    
                    if state == 'connected':
                        ret = 0
                    else:    
                        try:
                            process = subprocess.run(f'netsh.exe wlan connect RAD_TST1_{wifi_net} interface="{intf_name}"',
                                                         shell=False, check=True, stdout=subprocess.PIPE, universal_newlines=True,
                                                         stderr=subprocess.PIPE) 
                            connect_res = process.stdout.rstrip()
                            ret = 0
                        except Exception as ex:
                            connect_res = ex
                            ret = -1                   
                        print(f'{my_time()} sftp_loop connect_res: {connect_res}')
                    
                    if ret == 0:
                        read_wifi(wifi_net, intf_name)
            
            for report_file in  glob.glob("WifiReport*.txt"):
                try:
                    sftp.UploadFile(report_file)
                except Exception as ex:
                    print(f'{my_time()} sftp_loop Error when upload to ftp {report_file}')
            time.sleep(1)
            for report_file in  glob.glob("WifiReport*.txt"):
                os.remove(report_file)
            
    sftp.Close()

    loop.call_later(30, sftp_loop, loop)  # call itself in 30 second
    
    return None

def read_wifi(wifi_net, intf_name):    
    report_file = f'wifiReport_{wifi_net}.txt'
    print(f'\n{my_time()} read_wifi {report_file} {wifi_net} {intf_name}')
    if os.path.exists(report_file):
        os.remove(report_file)
    time.sleep(1)
    
    process = subprocess.run("netsh.exe wlan show interfaces",
                                shell=False, check=True, stdout=subprocess.PIPE, universal_newlines=True,
                                stderr=subprocess.PIPE)
    all_interfaces = process.stdout.rstrip()
    list_interfaces = all_interfaces.split('\n\n')
    
    for intf in list_interfaces:
        if re.search(f'{intf_name}\s+Description', intf) != None:
            print(f'intf:{intf}')
            with open(report_file, 'w') as outfile:
                outfile.write(intf)



def my_time():
    now = datetime.now()
    return now.strftime("%Y-%m-%d %H:%M:%S")

# sftp = Lib_RadApps.Sftp('ftp.rad.co.il', 'ate', 'ate2009')
sftp_server_side()