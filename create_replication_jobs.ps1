function create_replication_jobs($vm_list, $esx_host, $datastore_name, $prefix="JOB_"){
    # $vm_list: A list containing one or more VMs (e.g.: "server1","server2")
    # $esx_host: ESX host where VMs should be replicated to (e.g.: 10.0.0.10)
    # $datastore_name: Specify the datastore where the VMs should be replicated to, this
    #                   datastore needs to be accessible on esx_host (e.g.: "DATASTORE_01")
    # $prefix:  String to be used as a prefix in the job name

    # Get runtime date
    $date = Get-Date -format yyyMMdd_HHmmss

    # Output File
    $file_name = 'veeam_jobs_created_' + $date + '.txt'

    $COMMENT = "Job automatically created through script"

    $server = Get-VBRServer -Type ESXi -Name  $esx_host
    $datastore = Find-VBRViDatastore -Server $server -Name $datastore_name

    # Create Replication Job and write its output to file
    foreach ( $vm in $vm_list ){
        $job_name = $PREFIX + "_" + $vm
        Find-VBRViEntity -Name $vm | Add-VBRViReplicaJob -Name $job_name -Server $server -Datastore $datastore -Suffix "_replica" -RestorePointsToKeep 3 -Description "Comment: $COMMENT VM: $vm DS: $datastore_name" | tee -a $file_name
    }

    echo "Output was saved on file: $file_name"
}