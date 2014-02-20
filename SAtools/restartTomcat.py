#!/usr/bin/env python
import paramiko, os, sys, glob, fnmatch, argparse

parser = argparse.ArgumentParser()
parser.add_argument("do", type=str)
args = parser.parse_args()
optoutfilelist = glob.glob('/tmp/*.csv')
targetdir = ('/dev/shm/')
paramiko.util.log_to_file('./p.logs')
srcdir = ('/tmp/')
hosts = [ fsm11-dev, fsm12-dev]
ssh = paramiko.SSHClient()
ssh.load_system_host_keys()
ssh.load_host_keys(os.path.expanduser(os.path.join("~", ".ssh", "known_hosts")))
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
startapi = '/fsm/fsmapi/apache-tomcat-7.0.34/bin/startup.sh'
startmobile = '/fsm/fsmmobile/apache-tomcat-7.0.34/bin/startup.sh'
startwww = '/fsm/fsmwww/apache-tomcat-7.0.34/bin/startup.sh'
stopapi = '/fsm/fsmapi/apache-tomcat-7.0.34/bin/shutdown.sh'
stopmobile = '/fsm/fsmmobile/apache-tomcat-7.0.34/bin/shutdown.sh'
stopwww = '/fsm/fsmwww/apache-tomcat-7.0.34/bin/shutdown.sh'
startqueue = '/fsm/fsmqueue/apache-activemq-5.8.0/bin/linux-x86-64/activemq start'
stopqueue = '/fsm/fsmqueue/apache-activemq-5.8.0/bin/linux-x86-64/activemq stop'
def pushoptouts(host):
	optoutfiles = getfilestopush(srcdir)
	ssh.connect(host)
	sftp = ssh.open_sftp()
	for file in optoutfiles:
		srcfullpath = ( srcdir + file )
		destfullpath = (targetdir + file )
	#	#sftp.put(file, str.join(targetdir,file))
		sftp.put(srcfullpath, destfullpath)
		#print srcfullpath,  destfullpath
	sftp.close()
	
def sshcontrol(host, user2, runcmd):
	client = paramiko.SSHClient()
	client.load_system_host_keys()
	client.connect(host, username=user2)
	stdin, stdout, stderr = client.exec_command(runcmd)
	#print "stderr: ", stderr.readlines()
	print stdout.readlines()

def stopfsm(hostlist, mqnode):
		for nodes in hostlist():
			sshcontrol(nodes, "fsmwww", stopwww)
			sshcontrol(nodes, "fsmapi", stopapi)
			sshcontrol(nodes, "fsmmobile", stopmobile)
		sshcontrol(mqnode, "fsmqueue", stopqueue)

def startfsm(hostlist, mqnode):
	sshcontrol(mqnode, "fsmqueue", startqueue)
		for nodes in hostlist():
			sshcontrol(nodes, "fsmwww", startwww)
			sshcontrol(nodes, "fsmapi", startapi)
			sshcontrol(nodes, "fsmmobile", startmobile)
if __name__ == "__main__":
	try:
		if args.do == "start":
			for nodes in hosts():
				startfsm(nodes, "fsm11-test")
		elif args.do == "stop":
			for nodes in hosts():
				stopfsm(nodes, "fsm11-test")
	except Exception, e:
		return e
