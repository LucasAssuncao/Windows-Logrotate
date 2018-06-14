# Script: rotate-windows.ps1
# Date: 10/05/2018
# Autor: Lucas Assunção da Silva

#Arquivo e configuracao JSON
$json = Get-Content 'D:\Scripts\rotate.json' | Out-String 
$object = ConvertFrom-Json -InputObject $json

$log_file = 'D:\Scripts\log\rotate-windows.log'

$counter = 0

$date  = Get-Date 
$year  = $date.ToString("yyyy")
$month = $date.ToString("MM")
$day   = $date.ToString("dd")
$hour   = $date.ToString("HH")
$minute = $date.ToString("mm")
$second = $date.ToString("ss")

Set-Alias sevenzip "C:\Program Files\7-Zip\7z.exe"

if (-not (Test-Path "$($log_file)" )){
    New-Item -ItemType file -Path "$($log_file)"
}

#Function to clear the log content
function truncate($log){
    logger "Truncating [$($log)]"
    Clear-Content $log
    if($?){
        logger "File [$($log)] truncated" "SUCCESS"
    }else{
        logger "File [$($log)] isn't truncated" "ERROR"
    }
}

#Function to compress the rotated logs
function compress($log){
    logger "Compressing [$($log)]"
    sevenzip a -sdel "$($params.dest_dir)\$($finaldestination).zip" "$($params.dest_dir)\$($finaldestination)"
    if($?){
        logger "File [$($log)] compressed" "SUCCESS"
        # Remove-Item "$($params.dest_dir)\$($finaldestination)"
    }else{
        logger "File [$($log)] isn't compressed" "ERROR"
    }
}

#This function add each step of the execution of this script in a log file for debbuging and monitoring via Log indexers like Splunk
function logger ($log_message, $type) {
    # Implicit sleep, this script is faster than the disk speed.
    #Start-Sleep -s 5
    if (!$type) {
        $type = "INFO"
    }
    if ($log_message) {
        Add-Content -Path $log_file "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") [rotate-windows.ps1] [$type] $log_message"
    }
}

#MAIN Function that call other functions to rotate the log file and compress the rotated log file
function main($params){
    $arq = Split-Path $params.home_dir -Leaf
    $finaldestination="$($arq.Split('.')[0])-$($year)-$($month)-$($day)_$($hour)-$($minute)-$($second).$($arq.Split('.')[1])"
    
    if (-not (Test-Path "$($params.dest_dir)")){
        logger "Destination folder [$($params.dest_dir)] doesn't exist. Creating folder"
        New-Item -ItemType directory -Path "$($params.dest_dir)"
    }else{
        logger "Destination folder [$($params.dest_dir)] already exists."
    }

    if (-not (Test-Path "$($params.dest_dir)\$($finaldestination)")){
        logger "Destination file [$($params.dest_dir)\$($finaldestination)] doesn't exists. Creating file"
        New-Item -ItemType file -Path "$($params.dest_dir)" -Name "$($finaldestination)"
    }else{
        logger "Destination file [$($params.dest_dir)\$($finaldestination)] already exists."
    }

    Get-Content $params.home_dir >> "$($params.dest_dir)\$($finaldestination)"
    
    #Call the function TRUNCATE passing as a parameter the source log to be rotated and cleaned without deleting it.
    truncate $params.home_dir

    #Call the function COMPRESS passing as a parameter the 
    #destination log (log with the content of the source log), this function reduces disk space depending of the size of the log file
    compress "$($params.dest_dir)\$($finaldestination)"
}

#Call the MAIN function passing as a parameter each log in the JSON File
ForEach ($obj in $object){
    $validador = $obj.file.Count
    
    Do{
        main $obj.file[$counter]
        $counter++
    } While ($counter -lt $validador)
}