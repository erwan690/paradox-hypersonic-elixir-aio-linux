#!/usr/bin/env python3
# Paradox Hypersonic Elixir 360 AIO LCD feeder (native Linux, no Windows app)
# Protocol reversed: 64-byte HID report, no report ID
#   byte0 = 0xaa header
#   byte1 = CPU temp (C)
#   byte4 = fan RPM low byte, byte5 = fan RPM high byte (16-bit LE)
#   byte9 = GPU temp (C)
import os, time, glob, subprocess

DEV = "/dev/hidraw6"
CPU_TEMP = "/sys/class/hwmon/hwmon1/temp1_input"  # k10temp Tctl

def fan_rpm():
    # no native superio module on this kernel -> returns 0.
    # if lm-sensors/nct6xxx added later, first fan*_input is used automatically.
    for f in glob.glob("/sys/class/hwmon/hwmon*/fan*_input"):
        try:
            return min(65535, int(open(f).read()))
        except Exception:
            pass
    return 0

def cpu_temp():
    try:
        return min(99, int(open(CPU_TEMP).read()) // 1000)
    except Exception:
        return 0

def gpu_temp():
    try:
        out = subprocess.run(
            ["nvidia-smi", "--query-gpu=temperature.gpu", "--format=csv,noheader"],
            capture_output=True, text=True, timeout=2).stdout.strip()
        return min(99, int(out))
    except Exception:
        return 0

def find_dev():
    # hidraw index can change across replug; match 5131:2007
    for h in glob.glob("/sys/class/hidraw/hidraw*"):
        try:
            uevent = open(h + "/device/uevent").read()
            if "5131:2007" in uevent.upper():
                return "/dev/" + os.path.basename(h)
        except Exception:
            pass
    return DEV

def main():
    dev = find_dev()
    fd = os.open(dev, os.O_RDWR)
    frame = bytearray(64)
    frame[0] = 0xaa
    while True:
        frame[1] = cpu_temp()
        frame[9] = gpu_temp()
        rpm = fan_rpm()
        frame[4] = rpm & 0xFF
        frame[5] = (rpm >> 8) & 0xFF
        try:
            os.write(fd, bytes(frame))
        except OSError:
            os.close(fd); time.sleep(2); fd = os.open(find_dev(), os.O_RDWR)
        time.sleep(0.5)  # keepalive, LCD sleeps without refresh

if __name__ == "__main__":
    main()
