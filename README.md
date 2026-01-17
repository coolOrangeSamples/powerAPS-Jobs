# powerAPS-Jobs

[![Windows](https://img.shields.io/badge/Platform-Windows-lightgray.svg)](https://www.microsoft.com/en-us/windows/)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20|%207.4-blue.svg)](https://microsoft.com/PowerShell/)
[![coolOrange powerJobs](https://img.shields.io/badge/coolOrange%20powerJobs%20Processor-26.0.4+-orange.svg)](https://doc.coolorange.com/projects/powerjobsprocessor/en/stable/)
[![coolOrange powerEvents](https://img.shields.io/badge/coolOrange%20powerEvents-26.0.7+-orange.svg)](https://doc.coolorange.com/projects/powerevents/en/stable/)
[![Autodesk Platform Services](https://img.shields.io/badge/Autodesk%20Platform%20Services-API-blue.svg)](https://aps.autodesk.com/)

![powerAPS-Jobs](https://github.com/user-attachments/assets/2e2b8d11-5503-4d2d-bb01-2878d175c019)

## Disclaimer

THE SAMPLE CODE ON THIS REPOSITORY IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.

THE USAGE OF THIS SAMPLE IS AT YOUR OWN RISK AND **THERE IS NO SUPPORT** RELATED TO IT.

---

## Description

This repository provides **automated job workflows** for the COOLORANGE powerAPS ecosystem, enabling seamless publishing of Autodesk Vault files to **Autodesk Construction Cloud (ACC)** through **coolOrange powerJobs Processor**. 

The powerAPS-Jobs component handles Vault Job Processor automation that translates, converts, and publishes CAD files from Vault to ACC in multiple formats including native files, PDFs, and DWF models. It includes both the job submission interface (Vault Client side) and the processing workflows (Job Processor side).

---

## Prerequisites

> **Note**: powerJobs Processor version **26.0.4** or greater is required for these workflows.
> 
> **Note**: powerJobs Client (aka powerEvents) version **26.0.7** or greater is required for these workflows.

This component requires:

- **powerAPS-Modules** - Core PowerShell modules for APS communication
- **powerJobs Processor** installed on the Autodesk Vault **Job Processor machine**
- **powerEvents (powerJobs Client)** installed on each Autodesk Vault **Client machine** 
- Autodesk Vault Professional 2023 or later
- **AutoCAD** or **Inventor** for file translation (depending on file types)

---

## Related Repositories

- **[powerAPS-Modules](https://github.com/coolOrangeSamples/powerAPS-Modules)** - Core PowerShell modules for APS API communication
- **[powerAPS-UI](https://github.com/coolOrangeSamples/powerAPS-UI)** - User interface dialogs and menu extensions

The **powerAPS-Jobs** component depends on **powerAPS-Modules** for APS connectivity and works with **powerAPS-UI** for user configuration.

---

## Installation

> **Important**: Files downloaded from GitHub may be blocked by Windows. You must **unblock all files** before installation:
> 1. Right-click each downloaded file → **Properties**
> 2. Check **"Unblock"** at the bottom → **Apply** → **OK**  
> 3. Or use PowerShell: `Get-ChildItem -Recurse | Unblock-File`

> **Note**: This installation assumes that **Vault Explorer** and the **Vault Job Processor** run on the same machine.

### **Single Machine Installation**
1. **Close** Autodesk Vault Explorer and powerJobs Processor
2. **Download or clone** this repository
3. **Unblock all downloaded files** (see important note above)
4. **Install powerAPS-Modules** first (required dependency)
5. **Copy all files** from this repository to:  
   `C:\ProgramData\coolOrange\`
6. **Restart** powerJobs Processor and Vault Explorer

### **Multi-Machine Deployment**
For distributed environments where Vault clients and Job Processor are on different machines:

**On Job Processor machine:**
- Copy files from `powerJobs/` directory to: `C:\ProgramData\coolOrange\powerJobs\`

**On each Vault Client machine:**  
- Copy files from `Client Extensions/` directory to: `C:\ProgramData\coolOrange\Client Customizations\`

---

## Feature Overview

The powerAPS-Jobs component provides automated publishing workflows that transform and deliver Vault files to Autodesk Construction Cloud.

---

### Client-Side Job Submission

The following publishing options are available in the **File Context Menu** under **"ACC"**:

#### **Publish Drawings as PDF to ACC**
- **Converts CAD drawings** (IDW, DWG) to PDF format
- **Uploads PDF files** to configured ACC project location
- **Maintains folder structure** from Vault to ACC
- **Optional file locking** in ACC after upload
- **Supported formats**: AutoCAD DWG, Autodesk Inventor IDW

#### **Publish Models as DWF to ACC**  
- **Translates 3D models** to DWF format for model viewing
- **Supports multiple CAD formats**: Inventor (IAM, IPT), AutoCAD (DWG), SolidWorks (SLDASM, SLDPRT)
- **Generates viewer-optimized** DWF files
- **Preserves model hierarchy** and metadata  

#### **Publish Native Files to ACC**
- **Uploads original CAD files** without conversion
- **Includes file dependencies** and references automatically
- **Maintains native format** for cloud-based editing
- **Supports all file types** managed in Vault

---

### Server-Side Processing Workflows

The powerJobs Processor executes three specialized jobs:

#### **powerAPS.ACC.Publish.PDF.ps1**
**Automated PDF Generation and Publishing**

**Configuration Options:**
```powershell
# Include file revision in PDF name
$pdfFileNameWithRevision = $false

# Revision separator character  
$pdfFileNameRevisionSeparator = "_"

# Include file extension in PDF name
$pdfFileNameWithExtension = $true

# Lock files in ACC after upload
$lockAccFiles = $true
```

**Workflow Process:**
1. **File Validation**: Verifies IDW/DWG file types
2. **Application Launch**: Opens appropriate CAD application
3. **PDF Export**: Generates high-quality PDF output  
4. **APS Authentication**: Connects using job submitter's credentials
5. **Project Resolution**: Locates target ACC project and folder
6. **File Upload**: Publishes PDF to ACC with metadata
7. **Optional Locking**: Secures file in ACC if configured

#### **powerAPS.ACC.Publish.DWF.ps1**
**3D Model Translation and Publishing**

**Key Features:**
- **Multi-format support**: Handles various 3D file types
- **Reference resolution**: Processes assembly dependencies
- **Viewer optimization**: Generates DWF for model viewing
- **Metadata preservation**: Maintains properties and attributes
- **Quality control**: Validates successful translation

#### **powerAPS.ACC.Publish.Native.ps1**  
**Native File Publishing with References**

**Key Features:**
- **Dependency tracking**: Automatically includes referenced files
- **Folder structure**: Recreates Vault hierarchy in ACC
- **Version synchronization**: Maintains file version consistency  
- **Reference integrity**: Preserves file relationships
- **Metadata mapping**: Transfers custom properties to ACC

---

## Job Processing Architecture

### **Authentication & Security**
- **User context preservation**: Jobs run with submitter's APS credentials
- **Token management**: Automatic authentication and refresh
- **Permission validation**: Ensures user has required access rights
- **Secure credential storage**: Leverages Vault's authentication system

### **Error Handling & Logging**
- **Comprehensive logging**: Detailed progress and error reporting
- **File validation**: Pre-processing checks for supported formats
- **Graceful degradation**: Continues processing remaining files on partial failures
- **Performance monitoring**: Execution timing and statistics

### **Project Mapping**
- **Vault folder association**: Links Vault folders to ACC projects
- **Dynamic path resolution**: Calculates ACC folder paths from Vault structure
- **Regional awareness**: Automatically routes to correct ACC region
- **Hub and project validation**: Verifies target locations exist

---

## Configuration Requirements

### **Vault Folder Setup**
Before publishing files, Vault folders must be configured with ACC project mappings:

1. **Use powerAPS-UI** to assign ACC projects to Vault folders


### **File Format Support**

| **Job Type** | **Supported Formats** | **Output Format** |
|--------------|----------------------|-------------------|
| PDF Publishing | IDW, DWG | PDF |
| DWF Publishing | IAM, IPT, DWG, SLDASM, SLDPRT | DWF |
| Native Publishing | All Vault-managed files | Original format |

---

## End-to-End Publishing Workflow

1. **User selects files** in Vault Explorer and chooses publishing option
2. **Client extension validates** permissions and folder configuration  
3. **Job submission** creates powerJobs job with file and user context
4. **Job processor picks up tasks** and begins automated workflow
5. **File translation** converts to target format if needed
6. **APS authentication** establishes connection using submitter credentials
7. **Project resolution** locates target ACC project and folder structure
8. **File upload** transfers content to ACC with metadata
