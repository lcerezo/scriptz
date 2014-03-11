#!/usr/bin/env python
import paramiko, os, sys, glob, fnmatch, argparse
'''This will ssh into each host and stop/start fsm in the correct order. currently it does not check if java actually exited.'''

parser = argparse.ArgumentParser()
parser.add_argument("do", type=str, help="pass start or stop as argument to start or stop fsm stack")
args = parser.parse_args()
startapi = '/fsm/fsmapi/apache-tomcat-7.0.34/bin/startup.sh'
startmobile = '/fsm/fsmmobile/apache-tomcat-7.0.34/bin/startup.sh'
startwww = '/fsm/fsmwww/apache-tomcat-7.0.34/bin/startup.sh'
stopapi = '/fsm/fsmapi/apache-tomcat-7.0.34/bin/shutdown.sh'
stopmobile = '/fsm/fsmmobile/apache-tomcat-7.0.34/bin/shutdown.sh'
stopwww = '/fsm/fsmwww/apache-tomcat-7.0.34/bin/shutdown.sh'
startqueue = '/fsm/fsmqueue/apache-activemq-5.8.0/bin/linux-x86-64/activemq start'
stopqueue = '/fsm/fsmqueue/apache-activemq-5.8.0/bin/linux-x86-64/activemq stop'
# app hosts
hosts = [ 'fsm11-dev.mgt.wdc1.wildblue.net', 'fsm12-dev.mgt.wdc1.wildblue.net' ]
activemqhost = 'fsm11-dev.mgt.wdc1.wildblue.net'


def sshcontrol(host, user2, runcmd):
	client = paramiko.SSHClient()
	client.load_system_host_keys()
	client.load_host_keys(os.path.expanduser(os.path.join("~", ".ssh", "known_hosts")))
	client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
	client.connect(host, username=user2)
	stdin, stdout, stderr = client.exec_command(runcmd)
	#print "stderr: ", stderr.readlines()
	print( 'Host:: ' + host + ' replied to command ' + runcmd )
	print stdout.readlines()

def stopfsm(hostlist, mqnode):
	for nodes in hostlist():
		sshcontrol(nodes, "fsmwww", stopwww)
		sshcontrol(nodes, "fsmapi", stopapi)
		sshcontrol(nodes, "fsmmobile", stopmobile)
	sshcontrol(mqnode, "fsmqueue", stopqueue)

def startfsm(hostlist, mqnode):
	#sshcontrol(mqnode, "fsmqueue", startqueue)
	for nodes in hostlist:
		sshcontrol(nodes, "fsmwww", startwww)
		sshcontrol(nodes, "fsmapi", startapi)
		sshcontrol(nodes, "fsmmobile", startmobile)

if __name__ == "__main__":
	paramiko.util.log_to_file('./p.logs')
	if args.do == "start":
		startfsm(hosts, activemqhost )
	elif args.do == "stop":
		stopfsm(hosts, activemqhost )
