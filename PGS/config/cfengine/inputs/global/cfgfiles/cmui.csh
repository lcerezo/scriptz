# Standard .cshrc for PGS

if ( ! $?CM_RLSE ) then
   # set your default cm release:
   setenv CM_RLSE "cm-3.3.4"
endif

if ( ! $?USER_TYPE ) then
   # set your default user type:
   # setenv USER_TYPE "basic"
   setenv USER_TYPE "cm"
endif

# DON'T MODIFY THE FOLLOWING BLOCK OF DATA
setenv CM_LOGIN /cm/login
if ( -f /cm/login/common.cshrc ) then
    source /cm/login/common.cshrc
else
    echo "WARNING *** No Cube Manager login file system available. ***"
    echo "WARNING *** Cube Manager is not set up for this user.    ***"
endif
# END BLOCK OF DATA

# add your aliases and other customization below:
 
#
#The following is the staff for set up the ENV of both CM1.70 and CM2.0 

alias cmhis 'echo CM_HOME=$CM_HOME'
alias cmuns 'unsetenv CM_HOME CM_ETC CM_EHOME CM_LOCAL CM_ARCH PVM_ARCH CM_HOST CM_IHOST PVM_ROOT PVM_ARCH'
alias envcm 'env | egrep "CM_|_ARCH|_ROOT" | sort'
