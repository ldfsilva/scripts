# Collect information of all Veeam jobs which were executed at least once
function get_job_details(){

    #Get runtime date
    $date = Get-Date -format yyyMMdd_HHmmss

    # Output File
    $file_name = 'veeam_job_details_' + $date + '.txt'

    # Create initial output file with header
    "VM Name,Job Name,Job Type,Job Start Time,Job State,Job Progress,Job End Time,Job Duration (D:H:M:S),Job Result,Total Size (bytes),Total Used Size (bytes),Processed Size (bytes),Processed Delta (bytes),Transferred Size (bytes),VM Start Time,VM End Time,VM Duration (D:H:M:S),VM Duration (Secods),Avg Speed (bytes),Data Store Name,Data Store Reference">> $file_name

    #
    $Jobs = Get-VBRJob
    foreach($Job in $Jobs) {
        $session = $job.FindLastSession()

        #Overall job timing
        $SessionStartTime = $session.CreationTime
        $State = $session.State
        $Progress = $session.BaseProgress
        $SessionEndTime = $session.EndTime
        $Duration = $session.progress.Duration
        $Duration_str = ("{0}:{1}:{2}:{3}" -f `
            $Duration.Days, $Duration.Hours, $Duration.Minutes, $Duration.Seconds)
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
            $TotalSize = $VM.progress.TotalSize
            $TotalUsedSize = $VM.progress.TotalUsedSize
            $TransferedSize = $VM.progress.TransferedSize
            $ProcessedDelta = $VM.progress.ProcessedDelta

            $Start = $VM.progress.starttime
            $Finish = $VM.progress.stoptime
            $VM_Duration = $VM.progress.Duration
            $TotalSeconds = $Duration.TotalSeconds
            $VM_Duration_str = ("{0}:{1}:{2}:{3}" -f `
                $VM_Duration.Days, $VM_Duration.Hours, $VM_Duration.Minutes, $VM_Duration.Seconds)
            $AvgSpeed = $VM.progress.AvgSpeed
            $schedule = $job.GetScheduleOptions()

            $DatastoreName = $Job.ViReplicaTargetOptions.DatastoreName
            $DatastoreReference = $Job.ViReplicaTargetOptions.DatastoreReference
        }

        # Write output to file
        $VMName + "," + $JobName + "," + $Type + "," + $SessionStartTime + "," + $State + "," + $Progress + "," + $SessionEndTime + "," + $Duration_str + "," + $Result + "," + $TotalSize + "," + $TotalUsedSize + "," + $ProcessedSize + "," + $ProcessedDelta + "," + $TransferedSize + "," + $Start + "," + $Finish + "," + $VM_Duration_str + "," + $TotalSeconds + "," + $AvgSpeed + "," + $DatastoreName + "," + $DatastoreReference >> $file_name
    }

    #Check object properties
    #Object | Format-List -Property *
}