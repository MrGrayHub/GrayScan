import subprocess
import re

def detect_os(ip):
    pattern = r"ttl=(\d+)"  
    try:
        action = subprocess.run(['ping', '-c', '1', ip], capture_output=True, text=True, check=True)
        result = action.stdout.lower()  
        match = re.search(pattern, result)
        if match:
            ttl_value = int(match.group(1))
            if ttl_value == 128:
                return "Windows"
            elif ttl_value == 64:
                return "Linux/FreeBSD/OSX/Juniper/HP-UX"
            elif ttl_value == 255:
                return "Cisco device"
            elif ttl_value == 254:
                return "Solaris/AIX"
            elif ttl_value == 252:
                return "Windows Server 2003/XP"
            elif ttl_value == 240:
                return "Novell"
            elif ttl_value == 200:
                return "HP-UX"
            elif ttl_value == 190:
                return "MacOS"
            elif ttl_value == 127:
                return "MacOS"
            elif ttl_value == 100:
                return "IBM OS/2"
            elif ttl_value == 60:
                return "AIX"
            elif ttl_value == 50:
                return "Windows 95/98/ME"
            elif ttl_value == 48:
                return "BSDI"
            elif ttl_value == 30:
                return "SunOS"
            else:
                return "Unknown OS or device"
        else:
            return "ՕՀ֊ն չի հայտնաբերվել"
    except subprocess.CalledProcessError as e:
        return f"Ping failed: {e}"