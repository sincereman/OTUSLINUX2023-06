#!/usr/bin/python3
#version 2024-02-29-13-40 https
import os
import subprocess

def run_system(command):
    result = subprocess.run(command, shell=True)
    if result.returncode != 0:
        print(f"command exited with value {result.returncode}")
        exit(1)

conf_dir = "/data/config/"
os.makedirs(f"{conf_dir}tmp", exist_ok=True)

fetch = 'fetch '
fetch_version_check = subprocess.run('fetch -v 2>&1 | grep no-verify-peer', shell=True, capture_output=True, text=True)
if 'no-verify-peer' in fetch_version_check.stdout:
    fetch += '--no-verify-peer '

# Check a new version of fetch run_ipsec.pl
fetch_run = fetch + f"-o {conf_dir}tmp/run_ipsec.pl " + 'https://user:user@set.bamard.ru/run_ipsec.pl'
print(fetch_run)
run_system(fetch_run)

if os.path.exists(f"{conf_dir}tmp/run_ipsec.pl") and os.path.exists(f"{conf_dir}bin/run_ipsec.pl"):
    diff_command = f"diff -ruN {conf_dir}tmp/run_ipsec.pl {conf_dir}bin/run_ipsec.pl"
    diff = subprocess.run(diff_command, shell=True, capture_output=True, text=True).stdout
    if diff:
        subprocess.run(f"cp -f {conf_dir}tmp/run_ipsec.pl {conf_dir}bin/run_ipsec.pl", shell=True)
        print(f"\nUpdated {conf_dir}bin/run_ipsec.pl\n")
    else:
        print(f"\nNot Updated {conf_dir}bin/run_ipsec.pl\n")

subprocess.run(f"chmod +x {conf_dir}bin/run_ipsec.pl", shell=True)
subprocess.run(f"chown root {conf_dir}bin/run_ipsec.pl", shell=True)

# Check a new version of fetch update_run.pl
fetch_update = fetch + f"-o {conf_dir}tmp/update_run.pl " + 'https://user:user@set.bamard.ru/update_run.pl'
print(fetch_update)
run_system(fetch_update)

if os.path.exists(f"{conf_dir}tmp/update_run.pl") and os.path.exists(f"{conf_dir}bin/update_run.pl"):
    diff_command = f"diff -ruN {conf_dir}tmp/update_run.pl {conf_dir}bin/update_run.pl"
    diff = subprocess.run(diff_command, shell=True, capture_output=True, text=True).stdout
    if diff:
        subprocess.run(f"cp -f {conf_dir}tmp/update_run.pl {conf_dir}bin/update_run.pl", shell=True)
        print(f"\nUpdated {conf_dir}bin/update_run.pl\n")
    else:
        print(f"\nNot Updated {conf_dir}bin/update_run.pl\n")

subprocess.run(f"chmod +x {conf_dir}bin/update_run.pl", shell=True)
subprocess.run(f"chown root {conf_dir}bin/update_run.pl", shell=True)


