#Requires -RunAsAdministrator

Set-StrictMode -Version 3.0

$Name = "dev_env"
$Dir = "${HOME}\Documents\${Name}"
$WSLDir = "/mnt/c/Users/${Env:UserName}/Documents/${Name}"
$Output = "${Env:TEMP}\${Name}_setup"

function ExecBin($Block, $SuccessCode = 0) {
    $Val = Invoke-Command -ScriptBlock ${Block}
    if (${LastExitCode} -ne ${SuccessCode}) {
        exit 1
    }

    return ${Val}
}

function ExecCmd($Block) {
    try {
        return Invoke-Command -ScriptBlock ${Block}
    } catch {
        Write-Error -Exception ${PSItem}.exception -Message ${PSItem}.exception.message
        exit 1
    }
}

function Message($Color) {
    Write-Host -ForegroundColor ${Color} ${Args}
    Write-Output ${Args} *>> ${Output}
}

function Step($Message, $Block) {
    Message Cyan "==> ${Message}"
    Invoke-Command -ScriptBlock ${Block} *>> ${Output}
    Message Green "--> Done"
}

function StepNoRedirect($Message, $Block) {
    Message Cyan "==> ${Message}"
    Invoke-Command -ScriptBlock ${Block}
    Message Green "--> Done"
}

Message Yellow "!!! Detailed command output is being written to ${Output}"

StepNoRedirect "Installing WSL2" {
    if ((Get-Command -ErrorAction SilentlyContinue "wsl") -eq ${Null}) {
        ExecBin { dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart } 3010 *>> ${Output}
        ExecBin { dism /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart } 3010 *>> ${Output}

        $Timeout = 20
        $Message = "Restarting in ${Timeout} seconds to complete setup of WSL"

        Message Yellow "--> ${Message}"
        Message Yellow "--> Once restarted, run the setup script again to continue"
        ExecBin { shutdown /r /t ${Timeout} /c ${Message} } *>> ${Output}
        exit 0
    } else {
        $KernelUpdateInstaller = "${Env:TEMP}\kernel_update_installer.msi"

        ExecCmd {
            (New-Object System.Net.WebClient).DownloadFile("https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi", ${KernelUpdateInstaller})
        } *>> ${Output}

        ExecCmd { Start-Process -FilePath ${KernelUpdateInstaller} -Wait } *>> ${Output}
        ExecCmd { Remove-Item -Force -Path ${KernelUpdateInstaller} } *>> ${Output}

        ExecBin { wsl --set-default-version 2 } *>> ${Output}

        Message Yellow "--> Install a Linux distribution from Microsoft Store"
        Message Yellow "--> Run the installed Linux distribution application"
        Message Yellow "--> Make the WSL user the same as your Windows user ('${Env:UserName}')"
        Message Yellow "--> Once the distribution has been setup, press enter to continue"
        ExecCmd { Read-Host } *>> ${Output}

        ExecBin { wsl sudo apt-get install keychain --no-install-recommends --yes } 1>> ${Output}
    }
}

Step "Installing fonts" {
    $Zip = "${Env:TEMP}\font.zip"
    $TmpDir = "${Env:TEMP}\font"
    $TmpNLDir = "${TmpFontDir}\ttf\No ligatures"

    $RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

    ExecCmd { (New-Object System.Net.WebClient).DownloadFile("https://download.jetbrains.com/fonts/JetBrainsMono-2.001.zip", ${Zip}) }
    ExecCmd { Expand-Archive -Path ${Zip} -DestinationPath ${TmpDir} }

    ExecCmd {
        $ShellNamespace = (New-Object -COMObject Shell.Application).Namespace(${TmpNLDir})

        Get-ChildItem -Path ${TmpNLDir} | ForEach-Object {
            $ShellFileName = ${ShellNamespace}.ParseName(${PSItem}.Name)
            $FontName = ${ShellNamespace}.GetDetailsOf(${ShellFileName}, 21)
            $RegistryName = "${FontName} (OpenType)"

            New-ItemProperty -PropertyType String -Path ${RegistryPath} -Name ${RegistryName} -Value ${PSItem}.Name
            Copy-Item -Path ${PSItem}.FullName -Destination "C:\Windows\Fonts"
        }
    }

    ExecCmd { Remove-Item -Recurse -Force -Path @(${Zip}, ${TmpDir}) }
}

Step "Installing packages" {
    ExecBin { winget install --exact -q Mozilla.Firefox }
    ExecBin { winget install --exact -q Git.Git }
    ExecBin { winget install --exact -q Microsoft.WindowsTerminal }
}

StepNoRedirect "Configuring development host" {
    $ServerUserFile = "${HOME}\.server_user"

    $ServerAddr = ExecCmd { Read-Host -Prompt "    Address for development environment" } 2>> ${Output}
    $ServerUser = ExecCmd { Read-Host -Prompt "    Username for development environment" } 2>> ${Output}

    ExecCmd { "${ServerAddr} server" | Out-File -Encoding ASCII -Append -FilePath "${Env:WINDIR}\System32\drivers\etc\hosts" } *>> ${Output}

    ExecCmd { ${ServerUser} | Out-File -Encoding ASCII -NoNewline -FilePath ${ServerUserFile} } *>> ${Output}
    ExecCmd { (Get-Item -Path ${ServerUserFile}).Attributes += "Hidden" }

    Message Yellow "--> 'server' host created for address '${ServerAddr}'"
}

Step "Cloning ${Name}" {
    if (Test-Path -PathType "Container" -Path ${Dir}) {
        Remove-Item -Recurse -Force ${Dir}
    }

    ExecBin { git clone "https://github.com/larzconwell/${Name}.git" ${Dir} }
}

Step "Linking Windows dotfiles" {
    $TerminalSettingsDir = "${Env:LOCALAPPDATA}\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"

    ExecCmd { Remove-Item -Recurse -Force -Path ${TerminalSettingsDir} }
    ExecCmd { New-Item -Force -ItemType SymbolicLink -Path ${TerminalSettingsDir} -Target "${Dir}\windows_terminal" }
}

Step "Linking WSL2 dotfiles" {
    ExecBin { wsl "${WSLDir}/scripts/link_files" "${WSLDir}/dotfiles/wsl" '${HOME}' "." }
}
