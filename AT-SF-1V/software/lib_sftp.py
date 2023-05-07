import sys
from RL import Lib_RadApps

def FtpDeleteFile(fil):
    if sftp.FileExists(fil.lower()) == 1:
        fil = fil.lower()
        sftp.DeleteFile(fil)
        
def FtpFileExist(fil):
    fil = fil.lower()
    return sftp.FileExists(fil)
    
def FtpUploadFile(fil):
    return sftp.UploadFile(fil)
    
def FtpGetFile(remFil, locFil):
    return sftp.GetFile(remFil, locFil)
    
if __name__ == '__main__':
    print(sys.argv)
    func =  sys.argv[1]
    fil =  sys.argv[2]
            
    sftp = Lib_RadApps.Sftp('ftp.rad.co.il', 'ate', 'ate2009')
    
    if func == 'FtpDeleteFile':
        print(f'list_files:{sftp.ListOfFiles()}')
    
    if func == 'FtpGetFile':
        fil2 =  sys.argv[3]
        result = eval(func + "(fil, fil2)")
    else:
        result = eval(func + "(fil)")
        
    print(f'result: {result} , list_files:{sftp.ListOfFiles()}')
    
