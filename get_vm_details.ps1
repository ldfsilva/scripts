# Get runtime date
$date = Get-Date -format yyyMMdd_HHmmss

# Output File
$file_name = 'veeam_vm_details_' + $date + '.txt'

# List of VMs in quotes separated by commas (e.g.: "server1","server2")
$vm_list = ""

# Create initial output file with header
"VM Name,VM Status,VM State,VM UUID,VM Hostname,VM Path,VM Provisioned Size(Bytes),VM Used Size(Bytes),VM Provisioned Size(GB),VM Used Size(GB),VM Report File">> $file_name

# Create Replication Job
foreach ( $vm in $vm_list ){
    $vm_detail = Find-VBRViEntity -Name $vm

    $name = $vm_detail.name
    if (-Not $vm_detail){
        $status = "VM Not Found"
        $name = $vm

        # Write output to file
        $name + "," + $status >> $file_name
    }else {
        $status = 'VM Found' 
        $path = $vm_detail.path
        $hostname = $vm_detail.vmhostname
        $uuid = $vm_detail.uuid
        $state = $vm_detail.powerstate
        $provisioned_size = $vm_detail.provisionedsize
        $used_size = $vm_detail.usedsize
        $provisioned_size_gb = $provisioned_size/1024/1024/1024
        $provisioned_size_gb = "{0:N2}" -f $provisioned_size_gb
        $used_size_gb = $used_size/1024/1024/1024
        $used_size_gb = "{0:N2}" -f $used_size_gb

        # Write output to file
        $name + "," + $status + "," + $state + "," + $uuid + "," + $hostname + "," + $path + "," + $provisioned_size + "," + $used_size + "," + $provisioned_size_gb + "," + $used_size_gb + "," + $file_name >> $file_name
    }
}
