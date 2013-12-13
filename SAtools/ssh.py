import paramiko
hostlist = '/home/zarza.alange/hostlist'

def sshuptime(host, user2, runcmd):
	client = paramiko.SSHClient()
	client.load_system_host_keys()
	client.connect(host, username=user2)
	stdin, stdout, stderr = client.exec_command(runcmd)
	#print "stderr: ", stderr.readlines()
	print stdout.readlines()

f = open(hostlist)
for nodes in f:
	sshuptime(nodes.strip(), 'zarza.alange', 'uname -a' )
#	print nodes
f.close()
