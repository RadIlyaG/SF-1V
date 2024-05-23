import subprocess
from subprocess import CalledProcessError, check_output
import re
import os.path
import sqlite3
from sqlite3 import Error
#import requests
import socket
import ssl
import paramiko, getpass, time

# print(ra.check_mac.__doc__)
# help(ra.check_mac)

RadAppsPath = 'C:/RLFiles/Tools/RadApps'

def check_mac(b, m):
    """ check_mac
    Inputs: ID barcode
            MAC address
    Outputs: True, if the ID barcode has not link to any MAC or if the ID barcode and the MAC are connected
            "BARCODE already connected to MAC, if the Id barcode already connected to other MAC"
             """
    # FB1000F5815 0020D2268EAA

    global RadAppsPath
    pa = os.path.join(RadAppsPath, 'CheckMAC.jar')
    # print(f'RadAppsPath:{RadAppsPath}  pa:{pa}')
    process = subprocess.run("java.exe -jar  " + pa + " " + b + " " + m,
                             shell=False, check=True, stdout=subprocess.PIPE, universal_newlines=True,
                             stderr=subprocess.PIPE)
    stdout = process.stdout.rstrip()
    # returncode = process.returncode
    # print(f'output: {b}, {m}')
    # print(f'process: {process}')
    # print(f'stdout: {stdout}')
    # print(f'returncode: {returncode}')#, end='_'
    stderr = process.stderr.rstrip()
    # print(f'stderr: "{stderr}"')
    # if stdout == "":
    #     return True
    if stderr != '0' and stderr != "":
        return "Error"
    if stdout == "" and stderr == '0':
        # return(f'OK, or the {b} has no any MAC, or it has {m}')
        return "noLink"
    else:
        m = re.search('(\w+$)', stdout)  # $ at the end Anchors a match at the end of a string, also \Z
    #     # print(f'm is {m}')
        if m:
            ma = m.group(1)
            # print(f'{barcode} already connectred to {ma}')
            # return(f'{b} already connected to {ma}')
            return (ma)
        return False


def get_dbr_name(barcode):
    """ get_dbr_name returns DBR name for barcode """
    # b = 'DE1005790454'
    res_file = 'MarkNam_' + barcode + '.txt'
    if os.path.exists(res_file) == True:
        os.remove(res_file)
    pa = os.path.join(RadAppsPath, 'oi4barcode.jar')
    print(f'pa:{pa} BARCODE: {barcode} ')
    try:
        # subprocess.run('"java.exe -jar  " + pa + " " + barcode')
        output = check_output("java.exe -jar  " + pa + " " + barcode)
        returncode = 0
        try:
            # res_file = 'MarkNam_' + barcode + '.txtt'
            with open(res_file) as oi:
                oi4 = oi.read()
            stat = True
        except Exception as err:
            oi4 = err
            stat = False
    except CalledProcessError  as err:
        # print(f'err:{err} output:{err.output} returncode:{err.returncode} stdout:{err.stdout} stderr:{err.stderr}')
        oi4 = err
        stat = False

    # oi4 = "eeeee"
    # stat = False
    # print(f'oi4barcode DE1005790454: {oi4}')
    return stat, str(oi4)

def mac_reg(mac1, barcode, mac2="", sp1="DISABLE", sp2="DISABLE", sp3="DISABLE", sp4="DISABLE",
            sp5="DISABLE", sp6="DISABLE", sp7="DISABLE", sp8="DISABLE", imei1="", imei2=""):
    pa = os.path.join(RadAppsPath, 'MACReg_2Mac_2IMEI.exe')
    print(f'pa:{pa} MAC:{mac1} MAC2:{mac2} BARCODE:{barcode} SP1:{sp1}')
    try:
        process = subprocess.run(
            pa + " " + "/" + mac1 + " /" + mac2 + " /" + barcode + " /" + sp1 + " /" + sp2 +
            " /" + sp3 + " /" + sp4 + " /" + sp5 + " /" + sp6 + " /" + sp7 + " /" + sp8 + " /" + imei1 + " /" + imei2,
            shell=False, check=True, stdout=subprocess.PIPE, universal_newlines=True,
            stderr=subprocess.PIPE)
        return True
    except Exception as error:
        print(f'mac_reg error: {error}')
        return False

def get_dbr_sw(barcode):
    pa = os.path.join(RadAppsPath, 'SWVersions4IDnumber.jar')
    print(f'pa:{pa} BARCODE:{barcode}')
    try:
        process = subprocess.run("java.exe -jar " + pa + " " + barcode,
                                 shell=False, check=True, stdout=subprocess.PIPE, universal_newlines=True,
                                 stderr=subprocess.PIPE)
        print(f'process: {process}')
        stderr = process.stderr.rstrip()
        print(f'stderr: "{stderr}"')
        stdout = process.stdout.rstrip()
        print(f'stdout: {stdout}')
        returncode = process.returncode
        print(f'returncode: {returncode}')
    except Exception as error:
        print(f'error: {error}')
        return False


def get_operator(emp_id):
    pa = os.path.join(RadAppsPath, 'GetEmpName.exe')
    print(f'pa:{pa} EmplID:{emp_id}')
    try:
        process = subprocess.run(pa + " " + emp_id,
                                 shell=False, check=True, stdout=subprocess.PIPE, universal_newlines=True,
                                 stderr=subprocess.PIPE)
        res_file = os.path.join(RadAppsPath, emp_id + '.txt')
        print(f'res_file: {res_file}')
        try:
            with open(res_file) as empNaF:
                emp_name = empNaF.read()
        except Exception as err:
            emp_name = err
        finally:
            os.remove(res_file)
        return str(emp_name).rstrip()
    except Exception as error:
        print(f'get_operator error: {error}')
        return False

def sqlite_create_connection(db_file):
    """ create a database connection to the SQLite database
        specified by the db_file
    :param db_file: database file
    :return: Connection object or None
    """
    conn = None
    try:
        conn = sqlite3.connect(db_file)
    except Error as e:
        print(f'sqlite_create_connection error: {e}')

    return conn

def sqlite_get_empl_name(dbFile, empId):
    conn = sqlite_create_connection(dbFile)
    # print(f'conn: {conn}')
    with conn:
        c = conn.cursor()
        c.execute(''' SELECT count(name) FROM sqlite_master WHERE type='table' AND name='tbl' ''')
        if c.fetchone()[0]==0:
            c.execute("""CREATE TABLE tbl(EmpID, EmpName)""")
            return None

        s = "select EmpName from tbl where EmpID glob " + empId
        print(f's: {s}')
        cur = c.execute(s)
        for row in cur:
            na = row[0]
            return(f'{na}')

def sqlite_add_empl_name(dbFile, empId, empName):
    conn = sqlite_create_connection(dbFile)
    with conn:
        s = "INSERT INTO tbl VALUES (" + empId + "," + "\'" + empName + "\'" + ")"
        print(f'sqlite_add_empl_name: {s}')
        c = conn.cursor()
        c.execute(s)
        conn.commit()
        return True

def get_po_details(traceId='13279858'):
    hostname = '82.166.71.167'
    port = '8443'
    context = ssl.create_default_context()
    global gMessage
    gMessage = ""
    if len(traceId) != 8:
        gMessage = f'Length of the TraceID {traceId} is not 8'
        return False
    if traceId.isnumeric() == False:
        gMessage = f'TraceID {traceId} is not number'
        return False
    try:
        with socket.create_connection((hostname, port)) as sock:
            payload = {'TraceID': traceId}
            url = 'https://' + hostname + ':' + port + '/TraceabilityWS/Trace/ws/getPODetailsByTraceID?'
            headers = {'Authorization': 'Basic d2Vic2VydmljZXM6cmFkZXh0ZXJuYWw='}
            r = requests.get(url, headers=headers, params=payload, verify=False)
            if r.status_code == 200 and r.ok:
                # print(f'txt:{r.text}:')
                m = re.search('"po_number":\s+(\d+)[\,\s]+"qty":\s+(\d+)', r.text)
                if m:
                    # print(f'm:{m}')
                    # print(f'm:{m.group(1)}')
                    # print(f'm:{m.group(2)}')
                    return [m.group(1), m.group(2)]
                else:
                    gMessage = f'Get PO and Qty for {traceId} fail'
                    return False
            else:
                gMessage = f'status_code={r.status_code}, ok_state={r.ok}'
                return False
    except Exception as error:
        gMessage = f'Error during conn: {error}'
        return False

def ssh_connect():
    host = '172.18.94.42'
    port = 22
    username = 'etx-1p'
    password = '123456'
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host, port, username, password)

    # # stdin, stdout, stderr = ssh.exec_command('ls')
    # # #print(stdin, stdout, stderr)
    # # # stdout.channel.recv_exit_status()
    # # # lines = stdout.readlines()
    # # # for line in lines:
    # # #     print(f'line:{line.strip()}:')
    # # #
    # # # out = stdout.read().decode().strip()
    # # # print(f'out:{out}:')
    # # # error = stderr.read().decode().strip()
    # # # print(f'error:{error}:')
    # #
    # # # stdin.write('\n')
    # # # stdin.flush()
    # # output = stdout.read()
    # # print(f'output1:{output}:')
    #
    # stdin, stdout, stderr = ssh.exec_command('pwd')
    # output = stdout.channel.recv(1024)  #stdout.read()
    # print(f'output2:{output}:')
    #
    # # stdin.write('ls')
    # # stdin.flush()
    # # output = stdout.read()
    # # print(f'output3:{output}:')
    #
    # stdin, stdout, stderr = ssh.exec_command('sudo stty -F /dev/ttyUSB3 clocal', get_pty=True)
    # solo_line = stdout.channel.recv(1024)  # Retrieve the first 1024 bytes
    # # data_buffer += solo_line
    # print(f'solo_line1:{solo_line}:')
    # stdin.write('123456\n\r')
    # stdin.flush()
    # output = stdout.channel.recv(1024)
    # print(f'output3:{output}:')
    #
    # stdin, stdout, stderr = ssh.exec_command('pwd')
    # output = stdout.channel.recv(1024)  # stdout.read()
    # print(f'output4:{output}:')
    #
    # stdin, stdout, stderr = ssh.exec_command('sudo minicom -D /dev/ttyUSB3', get_pty=True)
    # solo_line = stdout.channel.recv(1024)  # Retrieve the first 1024 bytes
    # # data_buffer += solo_line
    # print(f'solo_line2:{solo_line}:')
    # stdin.write('123456\n\r')
    # stdin.flush()
    # output = stdout.read()
    # print(f'output5:{output}:')
    #

    ssh.close()

def ate_decryptor(kc, type):
    pa = os.path.join(RadAppsPath, 'atedecryptor.exe')
    print(f'ate_decryptor kc:{kc} type:{type}')
    try:
        process = subprocess.run(pa + " " + kc + " " + type,
                                 shell=False, check=True, stdout=subprocess.PIPE, universal_newlines=True,
                                 stderr=subprocess.PIPE)
        return process.stdout.rstrip()
    except Exception as err:
        print(f'ate_decryptor err:{err}')
        return None

def macserver(qty):
    res_file = 'c:\\temp\\mac.txt'
    if os.path.exists(res_file) == True:
        os.remove(res_file)
    pa = os.path.join(RadAppsPath, 'MACServer.exe')
    # print(f'macserver pa:{pa}, {os.path.exists(res_file)}, {os.path.exists(pa)}')
    try:
        output = check_output(pa + " 0 " + str(qty) + " " + res_file + " 1")
        returncode = 0
        try:
            with open(res_file) as ms:
                buffer = ms.read()
                # print(f'macserver buffer:{buffer}, {type(buffer)}')
            mac = buffer.split(" ")[0]
            if re.search("ERROR", buffer):
                mac = "MACServer ERROR"
                stat = False
            stat = True
        except Exception as err:
            mac = err
            stat = False
    except CalledProcessError  as err:
        # print(f'err:{err} output:{err.output} returncode:{err.returncode} stdout:{err.stdout} stderr:{err.stderr}')
        mac = err
        stat = False

    return stat, str(mac)

class Sftp:
    def __init__(self, host, username, password, port=22, folder="sf1v"):
        self.host = host
        self.username = username
        self.password = password
        self.port = port
        self.folder = folder
        # try:
            # self.transport = paramiko.Transport(self.host, self.port)
            # self.transport.connect(None, self.username, self.password)
            # self.sftp = paramiko.SFTPClient.from_transport(self.transport)
            # self.sftp.chdir(f"/{folder}") 
        # except Exception as excpt:
            # print(excpt)            
            
        return None

    def Open(self):
        try:
            self.transport = paramiko.Transport((self.host, self.port))
            self.transport.connect(None, self.username, self.password)
            self.sftp = paramiko.SFTPClient.from_transport(self.transport)
            self.sftp.chdir(f"/{self.folder}") 
        except Exception as excpt:
            print(f'Sftp.Open.Exp:{excpt}') 
            return False
        return True

    def UploadFile(self, fil):
        # dest = "/" + self.folder + "/" + fil
        # print(dest)
        # ret = 'na'
        try:
            SFTPAttributes = self.sftp.put(fil, fil)
            ret = 0
        except Exception as ret:
            print(f'exp1:{ret}')
        return ret


    def ListOfFiles(self):
        l = self.sftp.listdir()
        return l

    def FileExists(self, fil):
        if fil in self.sftp.listdir():
            ret = 1
        else:
            ret = -1
        return ret

    def GetFile(self, remFil, locFil):
        # l = self.sftp.listdir()
        if remFil in self.sftp.listdir():
            self.sftp.get(remFil, locFil)
            ret = 1
        else:
            ret = -1
        return ret

    def DeleteFile(self, fil):
        self.sftp.remove(fil)

    def Close(self):
        if self.transport:
            self.transport.close()
        if self.sftp:
            self.sftp.close()









# 1. V Digital Scope - KeysightDsoxScope.py
# 2. V Web service
# 3. V GetEmpName
# 4. V SqLite db
# 5. SSH (ETX-1P, ttl)

if __name__ == '__main__':
    # dd = check_mac(barcode, mac)
    # print(f'dd of {barcode} is : {dd}')
    barcode = 'DE1005790454'
    mac = '0020D2268EAA'
    # dbrName = get_dbr_name(barcode)
    # print(f'dbrName of {barcode} is : {dbrName}')

    #get_po_details('09390399')

    # ssh_connect()
    stat, mac = macserver(1)
    print(stat, mac)





