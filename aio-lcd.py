#!/usr/bin/env python3
# Paradox Hypersonic Elixir 360 AIO LCD feeder (native Linux, no Windows app)
# Protocol reversed: 64-byte HID report, no report ID
#   byte0 = 0xaa header
#   byte1 = CPU temp (C)
#   byte4 = fan RPM low byte, byte5 = fan RPM high byte (16-bit LE)
#   byte9 = GPU temp (C)
import os, time, glob, subprocess

DEV = "/dev/hidraw6"
CFG = os.path.expanduser("~/.config/aio-lcd.conf")
# CPU: k10temp (AMD Tctl/Tccd) or coretemp (Intel Package). label picks the die temp.
CPU_CHIPS = {"k10temp": ("Tctl", "Tccd1"), "coretemp": ("Package id 0",),
             "zenpower": ("Tdie",)}

# Defaults (overridden by ~/.config/aio-lcd.conf from install.sh)
FAN_CHIP = "nct6687"   # MSI B650 Tomahawk superio (modprobe nct6683 force=1)
FAN_INPUT = "fan2_input"  # AIO pump
# GPU: "auto" | "nvidia:<index>" | "amdgpu:<tempN_input>" | "i915:..." | "xe:..."
GPU_SEL = "auto"
FAN_SEL = "auto"  # "auto" | "<chip>/<fanN_input>"

def load_cfg():
    global FAN_CHIP, FAN_INPUT, GPU_SEL, FAN_SEL
    try:
        for line in open(CFG):
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            k, v = k.strip(), v.strip()
            if k == "GPU" and v:
                GPU_SEL = v
            elif k == "FAN" and v:
                FAN_SEL = v
                if v != "auto" and "/" in v:
                    FAN_CHIP, FAN_INPUT = v.split("/", 1)
    except Exception:
        pass

load_cfg()

def fan_rpm():
    if FAN_SEL != "auto":
        for h in glob.glob("/sys/class/hwmon/hwmon*"):
            try:
                if open(h + "/name").read().strip() == FAN_CHIP:
                    return min(65535, int(open(h + "/" + FAN_INPUT).read()))
            except Exception:
                pass
        return 0
    for h in glob.glob("/sys/class/hwmon/hwmon*"):
        try:
            if open(h + "/name").read().strip() == FAN_CHIP:
                return min(65535, int(open(h + "/" + FAN_INPUT).read()))
        except Exception:
            pass
    # fallback: first nonzero fan
    for f in sorted(glob.glob("/sys/class/hwmon/hwmon*/fan*_input")):
        try:
            v = int(open(f).read())
            if v > 0:
                return min(65535, v)
        except Exception:
            pass
    return 0

def cpu_temp():
    for h in glob.glob("/sys/class/hwmon/hwmon*"):
        try:
            name = open(h + "/name").read().strip()
            if name not in CPU_CHIPS:
                continue
            wanted = CPU_CHIPS[name]
            # prefer labeled sensor; fall back to temp1_input
            for lf in glob.glob(h + "/temp*_label"):
                if open(lf).read().strip() in wanted:
                    tf = lf.replace("_label", "_input")
                    return min(99, int(open(tf).read()) // 1000)
            return min(99, int(open(h + "/temp1_input").read()) // 1000)
        except Exception:
            pass
    return 0

def _gpu_hwmon(chip, sensor):
    for h in glob.glob("/sys/class/hwmon/hwmon*"):
        try:
            if open(h + "/name").read().strip() != chip:
                continue
            return min(99, int(open(h + "/" + sensor).read()) // 1000)
        except Exception:
            pass
    return 0

def _gpu_nvidia(index):
    try:
        out = subprocess.run(
            ["nvidia-smi", "--query-gpu=temperature.gpu", "--format=csv,noheader"],
            capture_output=True, text=True, timeout=2).stdout.strip()
        lines = out.splitlines()
        return min(99, int(lines[index]))
    except Exception:
        return 0

def gpu_temp():
    if GPU_SEL != "auto":
        try:
            kind, rest = GPU_SEL.split(":", 1)
        except ValueError:
            return 0
        if kind == "nvidia":
            try:
                return _gpu_nvidia(int(rest))
            except Exception:
                return 0
        if kind in ("amdgpu", "i915", "xe"):
            return _gpu_hwmon(kind, rest)
        return 0
    # auto: AMD/Intel hwmon first, then NVIDIA GPU 0
    for name in ("amdgpu", "i915", "xe"):
        for h in glob.glob("/sys/class/hwmon/hwmon*"):
            try:
                if open(h + "/name").read().strip() != name:
                    continue
                for tf in sorted(glob.glob(h + "/temp*_input")):
                    return min(99, int(open(tf).read()) // 1000)
            except Exception:
                pass
    return _gpu_nvidia(0)

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
