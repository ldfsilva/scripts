# Collect information of all Veeam jobs which were executed at least once
function get_job_details(){

    #Get runtime date
    $date = Get-Date -format yyyMMdd_HHmmss

    # Output File
    $file_name = 'veeam_job_details_' + $date + '.txt'

    # Create initial output file with header
    "VM Name,Job Name,Job Type,Job Start Time,Job State,Job Progress,Job End Time,Job Result,Total Size,Total Used Size,Processed Size,Processed Delta,Transferred Size,Disk Number,Start Time,End Time,Duration,Avg Speed,Data Store Name,Data Store Reference">> $file_name

    #
    $Jobs = Get-VBRJob
    foreach($Job in $Jobs) {
        $session = $job.FindLastSession()

        #Overall job timing
        $SessionStartTime = $session.CreationTime
        $State = $session.State
        $Progress = $session.BaseProgress
        $SessionEndTime = $session.EndTime
        $Result = $session.Result
        $Type = $Job.jobtype

        # When a job was never started GetTaskSessions will throw an nul-valued
        # expression error. Check if there is a valid session before execution
        # otherwise continue to the next iteration
        if (! $session){
            continue
        }
        $TaskSession = $session.GetTaskSessions()
        foreach($VM in $TaskSession){
            $JobName = $VM.JobName
            $VMName = $VM.Name
            $Status = $VM.status #Verify if it's useful to keep track of VM status or not

            $ProcessedSize = $VM.Progress.ProcessedSize

            #VM Capacity Details
            $DiskNum = $VM.CurrentDiskNum
            $TotalSize = $VM.progress.TotalSize
            $TotalUsedSize = $VM.progress.TotalUsedSize
            $TransferedSize = $VM.progress.TransferedSize
            $ProcessedDelta = $VM.progress.ProcessedDelta

            $Start = $VM.progress.starttime
            $Finish = $VM.progress.stoptime
            $Duration = $VM.progress.Duration
            $AvgSpeed = $VM.progress.AvgSpeed

            $schedule = $job.GetScheduleOptions()

            $DatastoreName = $Job.ViReplicaTargetOptions.DatastoreName
            $DatastoreReference = $Job.ViReplicaTargetOptions.DatastoreReference
        }

        # Write output to file
        $VMName + "," + $JobName + "," + $Type + "," + $SessionStartTime + "," + $State + "," + $Progress + "," + $SessionEndTime + "," + $Result + "," + $TotalSize + "," + $TotalUsedSize + "," + $ProcessedSize + "," + $ProcessedDelta + "," + $TransferedSize + "," + $DiskNum + "," + $Start + "," + $Finish + "," + $Duration + "," + $AvgSpeed + "," + $DatastoreName + "," + $DatastoreReference >> $file_name
    }

    #Check object properties
    #Object | Format-List -Property *
}