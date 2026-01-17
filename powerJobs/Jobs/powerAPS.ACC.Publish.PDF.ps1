#==============================================================================#
# (c) 2024 coolOrange s.r.l.                                                   #
#                                                                              #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER    #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES  #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.   #
#==============================================================================#

# Required in the powerJobs Settings Dialog to determine the entity type for lifecycle state change triggers
# JobEntityType = FILE

#region Settings
# To include the Revision of the main file in the PDF name set Yes, otherwise No
$pdfFileNameWithRevision = $false

# The character used to separate file name and Revision label in the PDF name such as hyphen (-) or underscore (_)
$pdfFileNameRevisionSeparator = "_"

# To include the file extension of the main file in the PDF name set Yes, otherwise No
$pdfFileNameWithExtension = $true

# To lock the PDF file in ACC after transfer set Yes, otherwise No
$lockAccFiles = $true
#endregion

#region Debugging
if (-not $IAmRunningInJobProcessor) {
    Import-Module powerJobs
    Open-VaultConnection -Server "localhost" -Vault "Vault" -User "Administrator" -Password ""
    $file = Get-VaultFile -Properties @{"Name" = "Drawing.idw"}
}
#endregion

Write-Host "Starting job '$($job.Name)'..."
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($module in Get-ChildItem "C:\ProgramData\coolOrange\powerAPS" -Name -Filter "*.psm1") {
    Import-Module "C:\ProgramData\coolOrange\powerAPS\$module" -Force
}

Write-Host "Processing file $($file._FullPath)..."

#region PDF Export
if (@("idw", "dwg") -notcontains $file._Extension) {
    Write-Host("File extension $($file._Extension) is not supported for PDF export!")
    $stopwatch.Stop()
    Write-Host "Completed job '$($job.Name)' in $([int]$stopwatch.Elapsed.TotalSeconds) Seconds"
    return
}

Write-Host "Generating PDF file..."

$file = (Save-VaultFile -File $file._FullPath -DownloadDirectory $workingDirectory)[0]
$openResult = Open-Document -LocalFile $file.LocalPath -Options @{ FastOpen = $fastOpen }
if (-not $openResult) {
    throw("Failed to open document $($file.LocalPath)! Reason: $($openResult.Error.Message)")
}

$pdfFileName = [System.IO.Path]::GetFileNameWithoutExtension($file._Name)
if ($pdfFileNameWithRevision) {
    $pdfFileName += $pdfFileNameRevisionSeparator + $file._Revision
}
if ($pdfFileNameWithExtension) {
    $pdfFileName += "." + $file._Extension
}
$pdfFileName += ".pdf"

$localFullFileName = "$workingDirectory\$pdfFileName"
if ($openResult.Application.Name -like 'Inventor*') {
    $configFile = "$($env:POWERJOBS_MODULESDIR)Export\PDF_2D.ini"
}
else {
    $configFile = "$($env:POWERJOBS_MODULESDIR)Export\PDF.dwg"
}
$exportResult = Export-Document -Format 'PDF' -To $localFullFileName -Options $configFile
$closeResult = Close-Document
if (-not $exportResult) {
    throw("Failed to export document $($file.LocalPath) to $localFullFileName! Reason: $($exportResult.Error.Message)")
}
if (-not $closeResult) {
    throw("Failed to close document $($file.LocalPath)! Reason: $($closeResult.Error.Message))")
}
#endregion

#region APS Authentication
Write-Host "APS Authentication..."
$result = Connect-APS -User $job.SubmittedByAutodeskId 
if(-not $result) {
   throw ($result.Error)
}
#endregion

#region ACC Project and Folder Structure
$projectFolder = GetVaultAccProjectFolder $file._FolderPath
if (-not $projectFolder) {
    throw "ACC Project folder not specified in Vault!"
}
$folderProperties = GetVaultAccProjectProperties $file._FolderPath
$hub = Get-ApsAccHub $folderProperties["Hub"]
if (-not $hub) {
    throw "ACC Hub '$($folderProperties["Hub"])' not found!"
}
$project = Get-ApsProject -hub $hub -projectName $folderProperties["Project"]
if (-not $project) {
    throw "ACC Project '$($folderProperties["Project"])' not found!"
}
$relativeAccFolder = $folderProperties["Folder"]
$projectFilesFolder = Get-ApsProjectFilesFolder $hub $project
if (-not $projectFilesFolder) {
    throw "ACC Project Files folder not found!"
}

if ($file._FolderPath.StartsWith($projectFolder.FullName)) {
    $folderPath = $file._FolderPath.Substring($projectFolder.FullName.Length).TrimStart('/')
    $folderPath = $relativeAccFolder + "/" + $folderPath
}
else {
    throw "File '$($file._Name)' is not in the Vault base folder '$($projectFolder.FullName)'"
}

# Create ACC folder structure, based on Vault folder path
$contents = Get-ApsTopFolders $hub $project
$folderLevels = $folderPath.Split('/', [System.StringSplitOptions]::RemoveEmptyEntries)
$currentParentFolder = $projectFilesFolder
foreach ($folderLevel in $folderLevels) {
    $currentFolder = $contents | Where-Object { $_.type -eq "folders" -and $_.attributes.displayName -eq $folderLevel }
    if (-not $currentFolder) {
        $currentFolder = Add-ApsFolder $project $currentParentFolder $folderLevel
    }
    $contents = Get-ApsFolderContents $project $currentFolder
    $currentParentFolder = $currentFolder
}
#endregion

#region ACC Upload and Versioning
# Upload binary content
$uploadObject = Add-ApsBucketFile $project $currentParentFolder $localFullFileName

# Get existing item from folder contents
$item = $contents | Where-Object { $_.type -eq "items" -and $_.attributes.displayName -eq $([System.IO.Path]::GetFileName($localFullFileName)) }
if (-not $item) {
    # Create first version if item does not exist
    $version = Add-ApsFirstVersion $project $currentParentFolder $localFullFileName $uploadObject
}
else {
    # Create next version if item already exists
    $version = Add-ApsNextVersion $project $item $localFullFileName $uploadObject
}
Write-Host "Version $($version.attributes.versionNumber)"
#endregion

#region ACC Custom Attributes
$customAttributes = Get-ApsAccCustomAttributeDefinitions $project $projectFilesFolder
$propertyMapping = GetVaultAccAttributeMapping $file._FolderPath
if ($customAttributes.Count -gt 0 -and $propertyMapping.Count -gt 0) {
    $description = $null
    $attributes = @{}
    foreach ($mapping in $propertyMapping.GetEnumerator()) {
        $attributeName = $mapping.Name
        $vaultPropertyName = $mapping.Value

        if ($attributeName -eq "Description") {
            $description = $file.$vaultPropertyName
            continue
        }

        $customAttribute = $customAttributes | Where-Object { $_.name -eq $attributeName }
        $id = $customAttribute.id
        $value = $file.$vaultPropertyName
     
        if ($customAttribute) {
            $attributes.Add($id, $value)
        }
    }

    if ($description) {
        Update-ApsItemDescription $project $version $description
    }
    
    if ($attributes.Count -gt 0) {
        Update-ApsAccCustomAttributes $project $version $attributes
    }
}
#endregion

#region ACC Item Lock
if ($lockAccFiles) {
    Update-ApsItemLocked $project $version $true
}
#endregion

$stopwatch.Stop()
Write-Host "Completed job '$($job.Name)' in $([int]$stopwatch.Elapsed.TotalSeconds) Seconds"
