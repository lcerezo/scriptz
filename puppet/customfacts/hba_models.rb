## get HBA info as facts for facters <2 (tested on 1.8)
## Initial writing sometime in Sept of 2014
## The lastest could be found on SVN or in viasat's github installation.
## Luis E. Cerezo @luiscerezo
if Facter.value(:kernel) == 'Linux'
    sysfs_scsi_host_dir = '/sys/class/scsi_host/'
# this will look in the sysfs dir for all hbas installed on the host
    Dir.entries(sysfs_scsi_host_dir).each do |hba|
# These are the attributes to be read into facts for puppet.
            hba_params = [ 'modelname', 'modeldesc', 'info', 'serialnum' , 'fwrev', 'lpfc_drvr_version', ]
            hba_params.each do |hbap|
#  Check if the attribute exists; These are different for different hbas and convert them into facts.
            if File.exist?(sysfs_scsi_host_dir + hba + "/" + hbap)
    	        Facter.add("hba_#{hbap}_#{hba}".to_sym) do
    	            setcode do
       	                Facter::Util::Resolution.exec("cat #{sysfs_scsi_host_dir}#{hba}/#{hbap} ")
                end
                end
                end
     end
     end
     end
# I really don't know why Ruby needs so many flippin' ends. PLOPPERS
