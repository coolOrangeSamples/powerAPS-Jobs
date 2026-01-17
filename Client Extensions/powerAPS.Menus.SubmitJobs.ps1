#==============================================================================#
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER    #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES  #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.   #
#                                                                              #
# Copyright (C) 2026 COOLORANGE S.r.l.                                         #
#==============================================================================#

# How to fix DPI display issues in Vault:
# https://www.autodesk.com/support/technical/article/caas/tsarticles/ts/gyzDnXXycpDjsEGyzJ7TY.html

if ($processName -notin @('Connectivity.VaultPro')) {
	return
}

Add-VaultMenuItem -Location FileContextMenu -Name "Publish Drawings as PDF to ACC" -Submenu "<b>ACC</b>" -Action {
    param($entities)
    if (-not (ApsTokenIsValid)) {
        return
    }

    $missingRoles = GetMissingRoles @(119)
    if ($missingRoles) {
        $message = "The current user does not have the required permissions: $missingRoles!"
        $title = "Permission Error"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($message, $title)
        return
    }

    $excluded = @()
    $files = @()
    foreach($file in $entities) {
        if ( @("idw", "dwg") -notcontains $file._Extension ) {
            $excluded += $file._Name
            continue
        }
        $files += $file
    }

    foreach($file in $files) {
        try {
            $null = GetVaultAccProjectProperties $file._EntityPath
        }
        catch {
            $title = "Submitting Job for File " + $file.Name + " failed!"
            $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($_, $title)
            continue
        }

        Add-VaultJob -Name "powerAPS.ACC.Publish.PDF" -Description "Translate file '$($file._Name)' to PDF and publish to ACC" -Parameters @{
            "FileVersionId" = $file.Id
            "EntityId"= $file.Id
            "EntityClassId"= $file._EntityTypeID
            "SubmittedByAutodeskId" = $APSConnection.User
        }
    }

    if ($excluded.Count -gt 0) {
        $message = "$($files.Count) jobs(s) have been created.$([Environment]::NewLine)The following file(s) are not supported: $($excluded -join [Environment]::NewLine)"
        $title = "Job Warning"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowWarning($message, $title, [Autodesk.DataManagement.Client.Framework.Forms.Currency.ButtonConfiguration]::Ok)
    }    
}

Add-VaultMenuItem -Location FileContextMenu -Name "Publish Models as DWF to ACC" -Submenu "<b>ACC</b>" -Action {
    param($entities)
    if (-not (ApsTokenIsValid)) {
        return
    }

    $missingRoles = GetMissingRoles @(119)
    if ($missingRoles) {
        $message = "The current user does not have the required permissions: $missingRoles!"
        $title = "Permission Error"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($message, $title)
        return
    }

    $excluded = @()
    $files = @()
    foreach($file in $entities) {
        if ( @("iam", "ipt", "dwg", "sldasm", "sldprt") -notcontains $file._Extension ) {
            $excluded += $file._Name
            continue
        }
        $files += $file
    }

    foreach($file in $files) {
        try {
            $null = GetVaultAccProjectProperties $file._EntityPath
        }
        catch {
            $title = "Submitting Job for File " + $file.Name + " failed!"
            $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($_, $title)
            continue
        }

        Add-VaultJob -Name "powerAPS.ACC.Publish.DWF" -Description "Translate file '$($file._Name)' to DWF and publish to ACC" -Parameters @{
            "FileVersionId" = $file.Id
            "EntityId"= $file.Id
            "EntityClassId"= $file._EntityTypeID
            "SubmittedByAutodeskId" = $APSConnection.User
        }
    }

    if ($excluded.Count -gt 0) {
        $message = "$($files.Count) jobs(s) have been created.$([Environment]::NewLine)The following file(s) are not supported: $($excluded -join [Environment]::NewLine)"
        $title = "Job Warning"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowWarning($message, $title, [Autodesk.DataManagement.Client.Framework.Forms.Currency.ButtonConfiguration]::Ok)
    }
}

Add-VaultMenuItem -Location FileContextMenu -Name "Publish Native Files to ACC" -Submenu "<b>ACC</b>" -Action {
    param($entities)
    if (-not (ApsTokenIsValid)) {
        return
    }

    $missingRoles = GetMissingRoles @(119)
    if ($missingRoles) {
        $message = "The current user does not have the required permissions: $missingRoles!"
        $title = "Permission Error"
        $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($message, $title)
        return
    }

    foreach($file in $entities) {
        try {
            $null = GetVaultAccProjectProperties $file._EntityPath
        }
        catch {
            $title = "Submitting Job for File " + $file.Name + " failed!"
            $null = [Autodesk.DataManagement.Client.Framework.Forms.Library]::ShowError($_, $title)
            continue
        }

        Add-VaultJob -Name "powerAPS.ACC.Publish.Native" -Description "Publish file '$($file._Name)' and it's references to ACC" -Parameters @{
            "FileVersionId" = $file.Id
            "EntityId"= $file.Id
            "EntityClassId"= $file._EntityTypeID
            "SubmittedByAutodeskId" = $APSConnection.User
        }
    }
}
