#!/usr/bin/env python
import paramiko, os, sys, glob, fnmatch


optoutfilelist = glob.glob('/tmp/*.csv')
targetdir = ('/dev/shm/')
paramiko.util.log_to_file('./p.logs')
srcdir = ('/tmp/')
hostlist = "/home/zarza.alange/hostlist"
ssh = paramiko.SSHClient()
ssh.load_system_host_keys()
ssh.load_host_keys(os.path.expanduser(os.path.join("~", ".ssh", "known_hosts")))
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

def pushoptouts(host):
	optoutfiles = getfilestopush(srcdir)
	ssh.connect(host)
	sftp = ssh.open_sftp()
	for file in optoutfiles:
		srcfullpath = ( srcdir + file )
		destfullpath = (targetdir + file )
	##	#sftp.put(file, str.join(targetdir,file))
		sftp.put(srcfullpath, destfullpath)
		#print srcfullpath,  destfullpath
	sftp.close()
	
def sshuptime(host, user2, runcmd):
	client = paramiko.SSHClient()
	client.load_system_host_keys()
	client.connect(host, username=user2)
	stdin, stdout, stderr = client.exec_command(runcmd)
	#print "stderr: ", stderr.readlines()
	print stdout.readlines()

def getfilestopush(dir):
	files = []
	for fls in os.listdir(dir):
		if fnmatch.fnmatch(fls, '*.csv'):
			files.append(fls)
	return files

def return_nagios_state(state, extinfo):
	print state, extinfo
	if state.lower() == "critical":
		sys.exit(2)
	elif state.lower() == "warning":
		sys.exit(1)
	else:
		sys.exit(0)

if __name__ == "__main__":
	try:
		f = open(hostlist)
		for nodes in f.readlines():
			pushoptouts(nodes.strip())
		return_nagios_state("OK", "Files pushed with no errors")
	except Exception, e:
		return_nagios_state("critical", e)
	f.close()
