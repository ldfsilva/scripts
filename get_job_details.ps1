Get runtime date
$date = Get-Date -format yyyMMdd_HHmmss

# Output File
$file_name = 'veeam_job_details_' + $date + '.txt'

# Create initial output file with header
"VM Name,Job Name,Job Type,Job Start Time,Job End Time,Job Status,Job Progress,Total Size,Total Used Size,Processed Size,Processed Delta,Transferred Size,Disk Number,Start Time,End Time,Duration,Avg Speed,Data Store Name,Data Store Reference">> $file_name

#
$Jobs = Get-VBRJob
foreach($Job in $Jobs) {
    $session = $job.FindLastSession()

    #Overall job timing
    $SessionStartTime = $session.CreationTime
    $SessionEndTime = $session.EndTime

    $TaskSession = $session.GetTaskSessions()
    foreach($VM in $TaskSession){
        $JobName = $VM.JobName
        $VMName = $VM.Name
        $Type = $Job.jobtype
        $Status = $VM.status

        $Progress = $VM.Progress.DisplayName
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
    $VMName + "," + $JobName + "," + $Type + "," + $SessionStartTime + "," + $SessionEndTime + "," + $Status + "," + $Progress + "," + $TotalSize + "," + $TotalUsedSize + "," + $ProcessedSize + "," + $ProcessedDelta + "," + $TransferedSize + "," + $DiskNum + "," + $Start + "," + $Finish + "," + $Duration + "," + $AvgSpeed + "," + $DatastoreName + "," + $DatastoreReference >> $file_name
}

#Check object properties
#Object | Format-List -Property *
