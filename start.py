#!/usr/bin/env python3

import subprocess
import time
import os
import pwd

MJPG = [
    "/usr/local/bin/mjpg_streamer",
    "-i",
    "%(input)s",
    "-o",
    "output_http.so -p %(port)s -w /usr/local/share/mjpg-streamer/www/",
]

MJPG_INPUT_DEFAULT = "input_uvc.so -r HD"

OCTOPRINT = ["/opt/octoprint/venv/bin/octoprint", "serve"]

#CLEARUVCVIDEO = ["rmmod uvcvideo"]
#RELOADUVCVIDEO = ["modprobe uvcvideo quirks=640"]

def main():

    #clearuvcvideo_process = subprocess.Popen(CLEARUVCVIDEO)
    #clearuvcvideo_process.wait()
    #time.sleep(1)
    #reloaduvcvideo_process = subprocess.Popen(RELOADUVCVIDEO)
    #reloaduvcvideo_process.wait()
    #time.sleep(1)

    mjpg_processes = []
    mjpg_ports = [5000] # Reserve the OctoPrint port
    for k, v in os.environ.items():
        if k.startswith("MJPG") and not k.startswith("MJPG_"):
            v = v.strip()
            port_env = "MJPG_PORT" + k[4:]
            port = int(os.environ.get(port_env, 8080))
            if port in mjpg_ports:
                raise ValueError("Port %s from key %s already in use" % (port, port_env))
            if not v:
                v = MJPG_INPUT_DEFAULT
            subs = {'input': v, 'port': port}
            cmd = []
            for part in MJPG:
                cmd.append(part % subs)
            print("Starting: %s" % (cmd,))
            mjpg_processes.append(subprocess.Popen(cmd))

    # Start klipper
    klipper = subprocess.Popen(['sudo', '-u', 'octoprint', '/runklipper.py'])

    os.setgid(
        1000
    )  # Drop privileges, https://stackoverflow.com/questions/2699907/dropping-root-permissions-in-python#2699996
    os.setuid(1000)
    os.environ['HOME'] = '/home/octoprint'
    os.environ['LC_ALL'] = 'en_US.utf-8'
    os.environ['LANG'] = 'en_US.utf-8'

    # subprocess.Popen('env', shell=True).wait()
    while 1:
        Poctoprint = subprocess.Popen(OCTOPRINT)
        Poctoprint.wait()
        time.sleep(1)


if __name__ == '__main__':
    main()

