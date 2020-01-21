$7zipPath = "$env:ProgramFiles\7-Zip\7z.exe"

if (-not (Test-Path -Path $7zipPath -PathType Leaf)) {
    throw "7 zip file '$7zipPath' not found"
}

Set-Alias 7zip $7zipPath

function Expand-OpsmanLogFile {
    param(
        [string] $logFile,
        [string] $outputDirectory     
    )

    # if empty, set the outputDirectory to the log file's directory    
    if ([System.String]::IsNullOrWhiteSpace($outputDirectory)){
        $logFileInfo = [System.IO.FileInfo]::new($logFile)
        $outputDirectory = $logFileInfo.Directory.FullName
    }

    $outputDirectoryName = [System.IO.Path]::GetFileNameWithoutExtension($logFile)
    $outputDirectoryFullPath = [System.IO.Path]::Combine($outputDirectory, $outputDirectoryName)
    $extension = [System.IO.Path]::GetExtension($logFile)

    switch ($extension) {
        ".tgz" {  
            Expand-OpsmanTgzFile -logFile $logFile -outputDirectoryName $outputDirectoryFullPath
        }
        ".zip" {  
            Expand-OpsmanZipFile -logFile $logFile -outputDirectoryName $outputDirectoryFullPath
        }
        Default {
            throw "unrecognized extension $extension"
        }
    }    

    # call export recursively for any tgz, zip files 
    $wildcardPath = [System.IO.Path]::Combine($outputDirectoryFullPath, "*")
    $files = Get-ChildItem -Path $wildcardPath -Include "*.tgz", "*.zip"
    foreach ($file in $files) {
        Expand-OpsmanLogFile -logFile $file.FullName
        Remove-Item -Path $file.FullName -Force -Confirm:$false
    }
}

function Expand-OpsmanTgzFile {
    param(
        [string] $logFile,
        [string] $outputDirectoryName
    )
    7zip x -y -o"$outputDirectoryName" $logFile
    $tarFiles = Get-ChildItem -Path $outputDirectoryName -Filter "*.tar"
    foreach( $tarFile in $tarFiles) {
        7zip x -y $tarFile.FullName -o"$outputDirectoryName"
        Remove-item -Path "\\?\$($tarFile.FullName)" -Force -Confirm:$false
    }
}

function Expand-OpsmanZipFile {
    param(
        [string] $logFile,
        [string] $outputDirectoryName
    )
    7zip x -y -o"$outputDirectoryName" $logFile
}

Export-ModuleMember -Function Expand-OpsmanLogFile, Expand-OpsmanTgzFile, Expand-OpsmanZipFile