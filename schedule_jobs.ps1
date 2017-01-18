# Disable a given job schedule
function disable_job($job_name){
    $job = Get-VBRJob -Name $job_name
    if ($job){
        Disable-VBRJobSchedule -Job $job
    }else {
        echo "Unable to find $job_name"
    }
}

# Reset a given job schedule to its default
function reset_job($job_name){
    $job = Get-VBRJob -Name $job_name
    if ($job){
        Reset-VBRJobScheduleOptions -Job $job
    }else {
        echo "Unable to find $job_name"
    }
}

# Given an array containing jobs name, it will iterate through and disable all of them
function disable_all_jobs($job_list){
    foreach ( $job_name in $job_list ){
        disable_job($job_name)
    }
}

# Given an array containing jobs name, it will iterate through and reset all of them
function reset_all_jobs($job_list){
    foreach ( $job_name in $job_list ){
        reset_job($job_name)
    }
}
