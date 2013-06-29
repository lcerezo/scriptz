import fcntl
fp = open("lock-testluis4", "a")
fcntl.lockf(fp.fileno(), fcntl.LOCK_EX|fcntl.LOCK_NB)
