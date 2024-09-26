# 腾讯桌面整理（DeskGo）扩展屏幕异常处理

## 前言

**此项目是根据[DeskGoExtendedScreen](https://github.com/Ridup/DeskGoExtendedScreen)的思路重写而来，为了处理使用腾讯桌面整理时，多屏幕切换导致桌面图标和悬浮磁铁位置大小错乱的脚本**

**实现思路请移步[DeskGoExtendedScreen](https://github.com/Ridup/DeskGoExtendedScreen)仓库**

重写脚本最主要的原因是前脚本的几个问题：

1. wmic 调用的 Win32_VideoController 没有办法获取到所有屏幕的分辨率，所以如果有多块屏幕连接的时候，只能获取到一个分辨率
2. 脚本备份仅使用获取到的一块分辨率作为备份文件名，结合第一个问题，如果我在 仅使用一块屏幕 和 扩展屏幕 的时候没有办法知道我在哪种状态，导致恢复依然出现错乱
3. 此api获取的貌似并不是屏幕分辨率而是设备，不清楚是否具有缓存，在切换的时候分辨率还是之前的

## 使用

实现方式有两种，请按需使用！

两种方式效果相同，如果提示没有权限请使用管理员权限运行

启用脚本后将会在腾讯桌面整理的AppData中创建Backup目录，根据屏幕设备的组合名称来创建备份

格式为：[主屏幕]-[副屏幕]&[副屏幕]...

## PowerShell + bat

**请注意！这个脚本用到了 .NET 中的类，请确保含你的环境中含有 .NET 库（一般来说win10及以上都有的）**

1. 将其中两个文件名为 `DeskGoBackup.ps1`和 `run.bat`的文件放在同一文件夹下
2. 双击打开 `DeskGoBackup.bat`文件即可

因为PowerShell只能在命令行中使用，所以双击打开就需要通过bat调用，当然也可以更改启动 `.ps1`的启动方式，这个请自行搜索

### 可能出现的问题

如果PowerShell脚本运行权限被禁止，可能是因为执行策略问题

请使用以下命令更改执行权限

```bash
set-executionpolicy remotesigned
```

### 不算Bug的Bug

在显示屏幕分辨率的时候，如果你的屏幕缩放比例不是100%，则显示的不是你的屏幕实际分辨率，而是缩放后的虚拟分辨率，这个问题并不影响使用

Python脚本因为使用的库已经处理过了，所以显示分辨率并没有问题

## Python

1. 使用前请先安装Python环境，确保能够直接执行Python脚本

2. 使用前需要安装以下库，命令为

```bash
pip install screeninfo psutil
```

3. 然后双击启动即可

一般来说 `shutil` 和 `subprocess`库在安装Python时就已经包含在内，如果仍提示缺少库，那么再执行

```bash
pip install shutil subprocess
```
