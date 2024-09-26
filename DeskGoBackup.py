import datetime

from screeninfo import get_monitors
import os
import subprocess
import psutil
import shutil
from time import sleep

# 屏幕列表
SCREEN_LIST = get_monitors()
# 应用进程名字（列表）
PROCESS_NAME = "DesktopMgr"
# appdata路径
APPDATA_PATH = os.getenv("APPDATA") + "\\Tencent\\DeskGo"
# 数据名字列表
DATA_NAME_LIST = ["ConFile.dat", "DesktopMgr.lg", "FencesDataFile.dat"]


def get_backup_folder_name_by_current_screen():
    primary_screen = [screen for screen in SCREEN_LIST if screen.is_primary]
    backup_folder_name = primary_screen[0].name.replace('\\\\.\\', '')
    for screen in SCREEN_LIST:
        if screen.is_primary:
            continue
        backup_folder_name += '-' + screen.name.replace('\\\\.\\', '') + '&'
    if len(SCREEN_LIST) > 1:
        backup_folder_name = backup_folder_name[:-1]
    return backup_folder_name


# 所有的备份文件路径
BACKUP_PATH = APPDATA_PATH + "\\Backup"
# 根据当前屏幕状态获取的备份文件名
BACKUP_FOLDER_NAME = get_backup_folder_name_by_current_screen()
# 完整的备份文件路径
BACKUP_FOLDER_PATH = BACKUP_PATH + "\\" + BACKUP_FOLDER_NAME


def print_screen_info():
    for screen in SCREEN_LIST:
        print(f"名称: {screen.name.replace('\\\\.\\', '')}")
        print(f"主屏幕: {'是' if screen.is_primary else '否'}")
        print(f"分辨率: {screen.width} x {screen.height}")
        print("------------------------")


def get_process_by_name(name):
    for proc in psutil.process_iter(['pid', 'name', 'exe']):
        if name in proc.info['name']:
            return proc
    return None


def backup_function():
    # 检查备份文件是否存在,不存在则创建
    if not os.path.exists(BACKUP_FOLDER_PATH):
        print(f"备份文件不存在，创建备份文件夹,路径为:{BACKUP_FOLDER_PATH}")
        os.mkdir(BACKUP_FOLDER_PATH)

    for filename in DATA_NAME_LIST:
        # 复制并且覆盖文件
        shutil.copy(APPDATA_PATH + "\\" + filename, BACKUP_FOLDER_PATH + "\\" + filename)
        print(f"复制文件:\n{APPDATA_PATH}\\{filename} 到 {BACKUP_FOLDER_PATH}")


def restore_function():
    # 检查备份文件是否存在
    is_exist = os.path.exists(BACKUP_FOLDER_PATH)

    # 通过进程列表名找到进程
    process = get_process_by_name(PROCESS_NAME)
    if process is None:
        print("未找到进程!")
        return
    process_path = process.exe()

    # 终止进程
    print("尝试终止进程...")
    process.kill()

    # 如果备份文件路径存在,则进行恢复
    if is_exist:
        for filename in DATA_NAME_LIST:
            # 复制并且覆盖文件
            shutil.copy(BACKUP_FOLDER_PATH + "\\" + filename, APPDATA_PATH + "\\" + filename)
            print(f"复制文件:\n{BACKUP_FOLDER_PATH}\\{filename} 到 {APPDATA_PATH}")

    print("重启进程中...")
    try:
        subprocess.Popen(process_path, shell=True)
    except subprocess.CalledProcessError as e:
        print(f"启动进程失败: {e}")
    except Exception as e:
        print(f"发生错误: {e}")

    return


if __name__ == "__main__":

    if(not os.path.exists(APPDATA_PATH)):
        print("没有AppData文件，请确认您已经安装了腾讯桌面管理！或者检查APP_DATA是否正确！")
        sleep(3)
        exit


    print(datetime.datetime.today())
    print("\n屏幕信息:")
    print("------------------------")
    print_screen_info()

    switcher = {
        "1": backup_function,
        "2": restore_function,
        "0": exit
    }

    while True:
        print("------------------------")
        print("OPTION:")
        print("1.备份")
        print("2.恢复")
        print("0.退出")
        print("请选择:", end="")
        option = str(input())
        print("------------------------")
        print("Start ...")
        fun = switcher.get(option)
        fun()
