# 加载必要的 .NET 类
Add-Type -AssemblyName System.Windows.Forms


# 可能的进程名称
$PROCESS_NAME = @("DesktopMgr64","DesktopMgr")
# 应用数据文件夹
$APP_DATA_PATH = [Environment]::GetFolderPath("ApplicationData") + "\Tencent\DeskGo"
# 备份文件夹
$BACKUP_PATH = $APP_DATA_PATH + "\Backup"
# 文件列表
$FILE_LIST = @("ConFile.dat","DesktopMgr.lg","FencesDataFile.dat")

# 屏幕列表
$screenList = [System.Windows.Forms.Screen]::AllScreens
# 主屏幕
$mainScreen = [System.Windows.Forms.Screen]::PrimaryScreen


# 日志记录器
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
    info([string]$message){
        Write-Host $message -ForegroundColor Gray
    }
}
# 创建日志记录器
$logger = New-Object Logger

# 根据当前屏幕信息拼接的整个备份文件夹路径
function getBackupFolderPathByScreenInfo{
    $folderName = $mainScreen.DeviceName.Replace('\\.\', '') + "($($mainScreen.Bounds.Width)x$($mainScreen.Bounds.Height))"
    foreach ($screen in $screenList) {
        # 跳过主屏幕
        if([bool]$screen.Primary){
            continue
        }
        $offsetX = [Math]::Abs($screen.Bounds.X)
        $offsetY = [Math]::Abs($screen.Bounds.Y)
        $suffix = "($($screen.Bounds.Width)x$($screen.Bounds.Height))[$($offsetX)$($offsetY)]"
        $screenName = $screen.DeviceName.Replace('\\.\', '') + $suffix
        $folderName = $folderName+'-'+$screenName+'&'
    }
    $folderName = $folderName.TrimEnd('&')

    $backupFolderPath = $BACKUP_PATH+ '\' + $folderName

    return $backupFolderPath
}
# 当前屏幕备份的文件夹路径
$backupFolderPath = getBackupFolderPathByScreenInfo

# 备份文件函数
function BackupFile {
    param (
    )
    # 根据目前屏幕信息检查是否存在该屏幕的备份文件夹，没有则创建
    if (!(Test-Path $backupFolderPath)) {
        New-Item -ItemType Directory -Path $backupFolderPath -Force | Out-Null
    }
    # TODO复制数据到当前屏幕组合的备份文件夹中
    foreach ($file in $FILE_LIST) {
        $logger.info("copy $APP_DATA_PATH\$file to $backupFolderPath\$file")
        Copy-Item -Path "$APP_DATA_PATH\$file" -Destination "$backupFolderPath\$file"
    }

    $logger.info("Press y to back backup file(if don't need type enter):")
    $back = Read-Host
    if($back -eq 'y'){
        BackBackupFile
    }
}

function BackBackupFile {
    $backbackup = $backupFolderPath + ".back"
    if (!(Test-Path $backbackup)) {
        New-Item -ItemType Directory -Path $backbackup -Force | Out-Null
    }

    foreach ($file in $FILE_LIST) {
        $logger.info("copy $APP_DATA_PATH\$file to $backbackup\$file")
        Copy-Item -Path "$APP_DATA_PATH\$file" -Destination "$backbackup\$file"
    }
    $logger.info("success copy to $backbackup")
}

# 恢复文件函数
function RestoreFile {
    # 设置一个bool变量，判断是否存在当前屏幕组合的备份文件
    $backupFileExist = $true
    # 根据当前屏幕组合的备份文件夹，检查备份文件是否都存在
    foreach ($file in $FILE_LIST) {
        if (!(Test-Path "$backupFolderPath\$file")) {
            # 不存在的话提示，但是不退出
            $logger.error("Backup $backupFolderPath\$file not exist!")
            $backupFileExist = $false
        }
    }

    # 从进程列表中获取进程
    $desktopMgrProcess = $null
    foreach($name in $PROCESS_NAME){
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
        foreach ($file in $FILE_LIST) {
            $logger.info("Copy $backupFolderPath\$file to $APP_DATA_PATH\$file");
            Copy-Item -Path "$backupFolderPath\$file" -Destination "$APP_DATA_PATH\$file" -Force | Out-Null
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
    if (!(Test-Path $APP_DATA_PATH)) {
        $logger.error("You haven't installed application DeskGo!Wait 3 seconds will exit!")
        # 停止三秒退出
        Start-Sleep -Seconds 3
        exit
    }

    # 列出当前时间
    Write-Host Current Time: "$(Get-Date)"
    # 列出目前正在使用的显示器信息
    $logger.warning("This resolution is't your device real resolution!It is be scaled by the screen DPI scale.")
    foreach ($screen in $screenList) {
        Write-Host "----------------------------------------------"
        if ($screen.Primary) {
            $logger.warning("Primary screen")
        }
        Write-Host "Screen name: $($screen.DeviceName.Replace('\\.\', ''))"
        Write-Host "Screen resolution: $($screen.Bounds)"
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

        if (!(Test-Path $BACKUP_PATH)) {
            $logger.warning("Backup path not found, creating...")
            New-Item -ItemType Directory -Path $BACKUP_PATH -Force | Out-Null
        }
        switch ($option) {
            1 {
                BackupFile
            }
            2 {
                RestoreFile
            }
            0 {
                exit
            }
            default {
                Write-Host "Invalid option"
            }
        }
    }

}

# 入口
Main