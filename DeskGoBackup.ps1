# 加载必要的 .NET 类
Add-Type -AssemblyName System.Windows.Forms

# 可能的进程名称
$ProcessName = @("DesktopMgr64","DesktopMgr")
$screens = [System.Windows.Forms.Screen]::AllScreens
# 主屏幕信息（去除屏幕名称中的\.\）
$mainScreenName = [System.Windows.Forms.Screen]::PrimaryScreen.DeviceName.Replace('\\.\', '')
# 应用数据文件夹
$appDataPath = [Environment]::GetFolderPath("ApplicationData") + "\Tencent\DeskGo\"
# 备份文件夹
$backupPath = $appdataPath + "Backup\"
# 文件列表
$fileList = @("ConFile.dat","DesktopMgr.lg","FencesDataFile.dat")

# 拼接文件夹名称
$folderName = $mainScreenName
foreach ($screen in $screens) {
    # 跳过主屏幕
    if([bool]$screen.Primary){
        continue
    }
    $screenName = $screen.DeviceName.Replace('\\.\', '')
    $folderName = $folderName+"-"+$screenName+"&"
}
$folderName = $folderName.TrimEnd("&")

# 根据当前屏幕信息拼接的整个备份文件夹路径
$backupFolderPath = $backupPath + $folderName

# 创建日志记录器
class Logger {
    message([string]$message){
        Write-Host $message
    }
    error([string]$message){
        Write-Host $message -ForegroundColor Red
    }
    warning([string]$message){
        Write-Host $message -ForegroundColor Yellow
    }
    success([string]$message){
        Write-Host $message -ForegroundColor Green
    }
    info([string]$message){
        Write-Host $message -ForegroundColor Gray
    }
}
$logger = [Logger]::new()

# 备份文件函数
function BackupFile {
    param (
    )
    # 根据目前屏幕信息检查是否存在该屏幕的备份文件夹，没有则创建
    if (!(Test-Path $backupFolderPath)) {
        New-Item -ItemType Directory -Path $backupFolderPath -Force | Out-Null
    }
    # TODO复制数据到当前屏幕组合的备份文件夹中
    foreach ($file in $fileList) {
        $logger.info("copy $appDataPath\$file to $backupFolderPath\$file")
        Copy-Item -Path "$appDataPath\$file" -Destination "$backupFolderPath\$file"
        $logger.success("Backup $file success!")
    }
}

# 恢复文件函数
function RestoreFile {
    # 设置一个bool变量，判断是否存在当前屏幕组合的备份文件
    $backupFileExist = $true
    # 根据当前屏幕组合的备份文件夹，检查备份文件是否都存在
    foreach ($file in $fileList) {
        if (!(Test-Path "$backupFolderPath\$file")) {
            # 不存在的话提示，但是不退出
            $logger.error("Backup $backupFolderPath\$file not exist!")
            $backupFileExist = $false
        }
    }

    # 从进程列表中获取进程
    $desktopMgrProcess = $null
    foreach($name in $ProcessName){
        if((Get-Process -Name $name -ErrorAction SilentlyContinue)){
            $desktopMgrProcess = Get-Process -Name $name
            break
        }
    }
    # 将进程的文件路径提取出来
    $desktopMgrPath = $desktopMgrProcess.Path
    if ($desktopMgrProcess) {
        $logger.info("Stop DesktopMgr Process ing...")
        Stop-Process -Name DesktopMgr64
        Start-Sleep -Seconds 1
    } else {
        $logger.error("Can't find DesktopMgr process")
    }

    # 复制文件到当前屏幕组合的备份文件夹中
    if ($backupFileExist) {
        foreach ($file in $fileList) {
            $logger.info("Copy $backupFolderPath\$file to $appDataPath\$file");
            Copy-Item -Path "$backupFolderPath\$file" -Destination "$appDataPath\$file" -Force | Out-Null
            $logger.success("Restore $backupFolderPath\$file success!")
        }
    } else {
        $logger.warning("No backup files found!Skip execution copy backup files!")
    }

    # 重新启动DesktopMgr进程
    $logger.info("Restart DesktopMgr process...")
    Start-Process $desktopMgrPath
}

# 主函数
function Main{
    # 如果没有此文件夹，说明未安装程序
    if (!(Test-Path $appDataPath)) {
        $logger.error("You haven't installed application DeskGo!Wait 3 seconds will exit!")
        # 停止三秒退出
        Start-Sleep -Seconds 3
        exit
    }

    # 列出当前时间
    Write-Host Current Time: "$(Get-Date)"
    # 列出目前正在使用的显示器信息
    $logger.warning("This resolution is't your device real resolution!It is be scaled by the screen DPI scale.")
    foreach ($screen in $screens) {
        Write-Host "----------------------------------------------"
        if ($screen.Primary) {
            $logger.warning("Primary screen")
        }
        Write-Host "Screen name: $($screen.DeviceName.Replace('\\.\', ''))"
        Write-Host "Screen resolution: $($screen.Bounds.Width) x $($screen.Bounds.Height)"
        Write-Host "Screen working area: $($screen.WorkingArea)"
    }

    # 检查备份文件夹是否存在
    
    while ($true) {
        Write-Host "`n----------------------------------------------"
        Write-Host "OPTIONS:"
        Write-Host "1.Backup data"
        Write-Host "2.Restore"
        Write-Host "0.Exit"
        Write-Host -NoNewline "Please choose option:"
        $option = Read-Host
        Write-Host "`nStarting..."

        if (!(Test-Path $backupPath)) {
            $logger.warning("Backup path not found, creating...")
            New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
            $logger.success("Backup folder created successfully!")
        }
        switch ($option) {
            1 {
                # Write-Host "Backup data"
                BackupFile
            }
            2 {
                RestoreFile
                # Write-Host "Restore data"
            }
            0 {
                exit
            }
            default {
                Write-Host "Invalid option"
            }
        }
    }


    #  "Check path is exist..."
    # # 检查备份文件夹是否存在，不存在则创建
    # if (!(Test-Path $backupPath)) {
    #     New-Item -ItemType Directory -Path $backupPath
    #      "`nBuild folder success! Path is:$backupPath"
    # }
}

function Test{
    # # 常量名检查
    # Write-Host 'ProcessName:'       $ProcessName
    # Write-Host 'MainScreenName:'    $mainScreenName
    # Write-Host 'AppDatePath:'       $appDataPath
    # Write-Host 'BackupPath:'        $backupPath
    # Write-Host 'FileList:'          $fileList
    # Write-Host 'FolderName:'        $folderName
    # Write-Host 'BackupFolderPath:'  $backupFolderPath

    # # $desktopMgrProcess = Get-Process | Where-Object { $_.Name -like "$ProcessName" }
    $desktopMgrProcess = $null
    foreach($name in $ProcessName){
        if((Get-Process -Name $name -ErrorAction SilentlyContinue)){
            $desktopMgrProcess = Get-Process -Name $name
            break
        }
    }
    # 将进程的文件路径提取出来
    $desktopMgrPath = $desktopMgrProcess.Path
    Write-Host "`nDesktopMgrPath:$desktopMgrPath"
    if ($desktopMgrProcess) {
        Stop-Process -Name DesktopMgr64
        Start-Sleep -Seconds 1
    }
    # Start-Process "C:\Program Files (x86)\Tencent\DeskGo\3.3.1491.127\DesktopMgr64.exe"
}

# Test
Main