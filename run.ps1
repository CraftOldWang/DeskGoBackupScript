
# 设置目标进程名称
$PROCESS_NAME = "DesktopMgr64"  
# 获取进程信息
$deskgoprocess = Get-Process -Name $PROCESS_NAME -ErrorAction SilentlyContinue
# 如果找到进程，获取其路径
if ($deskgoprocess) {
    # 获取进程路径
    $processPath = $deskgoprocess.Path
    Write-Host "找到进程: $PROCESS_NAME"
    Write-Host "进程路径: $processPath"
} else {
    Write-Host "未找到进程: $PROCESS_NAME"
    exit
}

# 直接在当前窗口中运行 Python 脚本
python "./DeskGoBackup.py"
# 获得python 的退出码
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0){
    
    # 重启腾讯桌面管理
    Write-Host "Python 脚本执行完毕，返回值为 0，正在重启进程..."

    # 如果进程已存在，先杀死它
    if ($deskgoprocess) {
        Write-Host "杀死进程 $PROCESS_NAME..."
        $deskgoprocess.Kill()
        Write-Host "进程已被终止。"
    }

    # 在python脚本中启动会导致脚本运行完后不能自动关闭终端的窗口， 可能是subprocess的问题。
    # 把重启搬到ps1中执行了。
    try {
        # 启动目标进程
        Start-Process -FilePath $processPath -ErrorAction Stop
        Write-Host "进程 $PROCESS_NAME 已重新启动."
    } catch {
        Write-Host "启动进程失败: $_"
    }
}

exit