'''
email_addrs: list of 2 lists - To and Cc
     [['ilya_g@rad.com', "alex_f@rad.com"], []] = me and Alex in To
      ['ilya_g@rad.com', "alex_f@rad.com"] = [['ilya_g@rad.com'], ["alex_f@rad.com"]] = me in To and Alex in Cc
'''

import os
import re
import time
import subprocess
import smtplib
from email.message import EmailMessage
import socket
from dirsync import sync
from pathlib import Path

class AutoSync():
    def __init__(self, sour_dest_list, no_check_dirs="", no_check_files="", email_addrs="", rad_net=1):
        self.rad_net = rad_net
        self.sour_dest_list = sour_dest_list
        self.no_check_dirs = no_check_dirs
        self.no_check_files = no_check_files
        self.email_addrs = email_addrs
        self.jar = 'C:\\RLFiles\\Tools\\RadApps\\AutoSyncApp.jar'
        # print(f'{self.sour_dest_list}, {rad_net}')
        # self.check_sour_dest_list()

    def check_sour_dest_list(self):
        for d in self.sour_dest_list:
            print(f'check_sour_dest_list {d}, {os.path.isdir(d)}, {os.path.exists(d)}')
            if os.path.exists(d) is False:
                return f"{d} doesn't exists", False

            # print(d, {os.path.isfile(d)})
        return "", True

    def java(self):
        sdn_list = ""
        for d in self.sour_dest_list:
            sdn_list += f"{d} "
        sdn_list = sdn_list.rstrip(" ")


        cmd = "java.exe -jar " + self.jar + " " + "\"" + sdn_list + "\""
        if self.no_check_files != "":
            cmd += " \"-noCheckFiles{" + self.no_check_files + "}\""
        if self.no_check_dirs != "":
            cmd += " \"-noCheckDirs{" + self.no_check_dirs + "}\""

        # print(sdn_list)
        print(cmd)
        try:
            process = subprocess.run(cmd, shell=False, check=True, stdout=subprocess.PIPE, universal_newlines=True,
                             stderr=subprocess.PIPE)
            stdout = process.stdout.rstrip()
            # print(f'stdout: {stdout}')
            # if process.returncode == 0:
            #     ret = True
        except subprocess.CalledProcessError as e:
            # print(e)
            return e, False

        else:
            if self.email_addrs != "":
                msg = EmailMessage()
                cont = ""
                for lin in stdout.split('\n'):
                  cont += lin + "\n\r"
                msg.set_content(cont)
                msg['Subject'] = f'{socket.gethostname().upper()}: Message from Tester'
                msg['From'] = os.getlogin()+'@rad.com'
                msg['To'] = self.email_addrs[0]
                if len(self.email_addrs) == 2:
                    msg['Cc'] = self.email_addrs[1]

                s = smtplib.SMTP('exrad-il.ad.rad.co.il')
                s.send_message(msg)
                s.quit()
            return "", True

    def auto_sync(self):
        msg, ret = self.check_sour_dest_list()
        if ret is True:
            # print(f'ausy:{ausy}')
            msg, ret = self.java()
            # print(f'java:{jav}')
        return msg, ret


class SyncInits():
    def __init__(self, hosts_list, inits_path, user_def_path=None, rtemp_path="R://IlyaG"):
        self.hosts_list = ["jateteam-hp-10"]
        self.hosts_list += [hosts_list]  # ("at-etx1p-1-10",  "jateteam-hp-10")
        self.email_addrs = ["ilya_g@rad.com"]
        self.inits_path = inits_path  # 'AT-ETX1P/software/uutInits'
        self.user_def_path = user_def_path  # 'AT-ETX-2i-10G/ConfFiles/Default'
        self.rtemp_path = rtemp_path  # "R://IlyaG/Etx1P"
        self.inits_dests = []
        self.user_def_dests = []
        self.un_updated_hosts = []
        self.msg = ''
        self.files = []

    def check_hosts(self):
        for host in self.hosts_list:
            if host != socket.gethostname():
                dest = "//" + host + "/" + "c$/" + self.inits_path
                # print(f'check_hosts {dest}, {os.path.isdir(dest)}, {os.path.exists(dest)}')
                if os.path.exists(dest):
                    self.inits_dests += [dest]
                    if self.user_def_path is not None and self.user_def_path != "":
                        dest = "//" + host + "/" + "c$/" + self.user_def_path
                        # print(f'check_hosts {dest}, {os.path.isdir(dest)}, {os.path.exists(dest)}')
                        if os.path.exists(dest):
                            if dest not in self.user_def_dests:
                                self.user_def_dests += [dest]
                        else:
                            if host not in self.un_updated_hosts:
                                self.un_updated_hosts += [host]
                else:
                    self.un_updated_hosts += [host]

            print(f'check_hosts inits_dests:{self.inits_dests} user_def_dests:{self.user_def_dests} un_updated_hosts:{self.un_updated_hosts}')

        if len(self.un_updated_hosts):
            self.msg += "The following PCs are not reachable:\n"
            for h in self.un_updated_hosts:
                self.msg += h+'\n'

        return True

    def sync_folders(self):
        self.sync_init_files()
        self.sync_user_def_files()

    def sync_init_files(self):
        files = []
        if len(self.inits_dests):
            # src = 'c://'+self.inits_path
            # rtemp = self.rtemp_path + "/inits"

            for dest in self.inits_dests:
                files += sync('c://'+self.inits_path, dest, "sync", verbose=False, create=True)
                self.files += files
                if len(files):
                    self.msg += '\n\n The following Inits were updated:\n'
                else:
                    self.msg += '\n\n No Init files were copied\n'

            self.copy_files_to_rtemp(files, self.rtemp_path + "/inits")

    def sync_user_def_files(self):
        files = []
        if len(self.user_def_dests):
            # src = 'c://'+self.user_def_path
            # rtemp = self.rtemp_path + "/userDefs"
            for dest in self.user_def_dests:
                files += sync('c://'+self.user_def_path, dest, "sync", verbose=False, create=True)
                self.files += files
                if len(files):
                    self.msg += '\n\n The following User Default Files were updated:\n'
                else:
                    self.msg += '\n No User Default Files were copied\n'

            self.copy_files_to_rtemp(files, self.rtemp_path + "/userDefs")

                # for fil in files:
                #     if os.path.isfile(fil):
                #         Path(rtemp).mkdir(parents=True, exist_ok=True)
                #         status = subprocess.check_output(f'copy \"{fil}\", \"{rtemp}\"', shell=True)
                #         print(f'sync_folders src:{src}, dest:{dest}, fil:{fil}, status:{status}')
                #         self.msg += os.path.basename(fil) + '\n'

    def copy_files_to_rtemp(self, files, rtemp):
        for fil in files:
            if os.path.isfile(fil):
                Path(rtemp).mkdir(parents=True, exist_ok=True)
                subprocess.check_output(f'copy \"{fil}\", \"{rtemp}\"', shell=True)
                self.msg += os.path.basename(fil)+'\n'
        return None

    def send_mail(self):
        msg = EmailMessage()
        cont = f'file://{self.rtemp_path}\n\r'
        # cont += self.msg
        for fi in self.files:
            cont += os.path.basename(fi)+'\n\r'
        msg.set_content(cont)
        msg['Subject'] = f'{socket.gethostname().upper()}: Inits were copied'
        msg['From'] = os.getlogin() + '@rad.com'
        msg['To'] = self.email_addrs[0]

        s = smtplib.SMTP('exrad-il.ad.rad.co.il')
        s.send_message(msg)
        s.quit()


if __name__ == "__main__":
    s1 = "//prod-svm1/tds/AT-Testers/JER_AT/ilya/Python/SF-1P/AT-SF-1P"
    d1 = "d:/PythonS/AT-SF1P"
    s2 = "//prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/SF-1V/download/sf1v/"
    d2 = "d:/temp"
    no_check_dirs = 'stam__pycache__ stam_venv __pycache__ .idea'  #stam_venv stam__pycache__ .idea
    no_check_files = '*zip init*.json'


    email_addrs = [['ilya_g@rad.com'], []]  #[['ilya_g@rad.com', "alex_f@rad.com"], []]
    asy = AutoSync((s1, d1, s2, d2), no_check_dirs, no_check_files, email_addrs)
    print(asy.check_sour_dest_list())
    print(f'java:{asy.java()}')

# AutoSync.auto_sync()
        
        
    

