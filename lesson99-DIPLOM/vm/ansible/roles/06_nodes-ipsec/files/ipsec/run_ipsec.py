#!/usr/bin/python3
#version 2024-02-29-13-40 https
import os
import subprocess
import sys

conf_dir = "/data/config/"
run_fetch = 1
previous_f = f"{conf_dir}tmp/previous_ver.tmp"  # previous version of exchange
my_name_f = f"{conf_dir}my_name.txt"
if not os.path.isdir(f"{conf_dir}tmp"):
    os.makedirs(f"{conf_dir}tmp")
sett_f = f"{conf_dir}tmp/settings.conf"
if not os.path.exists(my_name_f):
    raise FileNotFoundError(f"No file {my_name_f}")
sett = {}
last_update = ""
if run_fetch:
    fetch = 'fetch '
    fetch_version_check = subprocess.getoutput('fetch -v 2>&1 | grep no-verify-peer')
    if 'no-verify-peer' in fetch_version_check:
        fetch += '--no-verify-peer '
    fetch += f"-o {conf_dir}tmp " + 'https://user:user@10.99.1.225/settings.conf'
    print(fetch)
    subprocess.run(fetch, shell=True)

force = 0
my_name = ''
args = sys.argv[1:]
for arg in args:
    if arg == "-force":
        force = 1

# print(f"force = {force}")















import os
import subprocess
import crypt










def fillSett():
    print("--fillSett--")
    sett = {}
    conf_dir = "/data/config/"
    sett_f = conf_dir + "tmp/settings.conf"
    my_name_f = conf_dir + "my_name.txt"
    sett["leaves"] = {}
    sett["my_nets"] = []
    sett["star_name"] = ""
    sett["star_disable"] = ""
    sett["version"] = ""
    sett["int_ip"] = ""
    sett["ext_ip"] = ""
    sett["star_ip"] = ""
    sett["my_name"] = ""
    sett["ipsec_nets"] = {}
    sett["my_name"] = subprocess.check_output(["cat", my_name_f]).decode("utf-8").strip()
    with open(sett_f, "r") as f:
        for line in f:
            line = line.strip()
            if line.startswith("#") or line == "":
                continue
            print(line)
            key, value = line.split("=")
            key = key.strip()
            value = value.strip()
            if key.startswith("route_"):
                name = key.split("_")[1]
                if name not in sett["leaves"]:
                    sett["leaves"][name] = {}
                    sett["leaves"][name]["routes"] = []
                nets = value.split(",")
                for net in nets:
                    sett["leaves"][name]["routes"].append(net.strip())
            elif key.startswith("ext_ip_"):
                name = key.split("_")[2]
                if name not in sett["leaves"]:
                    sett["leaves"][name] = {}
                sett["leaves"][name]["ext_ip"] = value
            elif key.startswith("int_ip_"):
                name = key.split("_")[2]
                if name not in sett["leaves"]:
                    sett["leaves"][name] = {}
                sett["leaves"][name]["int_ip"] = value
            elif key.startswith("exclude_leaves_"):
                name = key.split("_")[2]
                if name not in sett["leaves"]:
                    sett["leaves"][name] = {}
                    sett["leaves"][name]["exclude_leaves"] = []
                leaves = value.split(",")
                for leaf in leaves:
                    sett["leaves"][name]["exclude_leaves"].append(leaf.strip())
            else:
                sett[key] = value
    sett["int_ip"] = sett["leaves"][sett["my_name"]]["int_ip"]
    sett["ext_ip"] = sett["leaves"][sett["my_name"]]["ext_ip"]
    sett["my_nets"] = sett["leaves"][sett["my_name"]]["routes"]
    star_name = sett["star_name"]
    if sett["leaves"][star_name]["ext_ip"]:
        sett["star_ip"] = sett["leaves"][star_name]["ext_ip"]
    else:
        raise Exception("No star_name {} in settings".format(star_name))
    return sett

def setRoutes(sett):
    print("\n--setRoutes--")
    routes_f = "/data/config/routes.sh"
    with open(routes_f, "w") as f:
        f.write("#!/usr/local/bin/bash\n")
        f.write("#-----{}------#\n\n".format(last_update))
        exclude_leaves = []
        if "exclude_leaves" in sett["leaves"][sett["my_name"]]:
            exclude_leaves = sett["leaves"][sett["my_name"]]["exclude_leaves"]
        print("\nmy_name:{},exclude_leaves:{}".format(sett["my_name"], ",".join(exclude_leaves)))
        for name in sett["leaves"]:
            if name == sett["my_name"]:
                continue
            for net in sett["leaves"][name]["routes"]:
                r0 = "route delete {}\n".format(net)
                r1 = "route add -net {} {}\n".format(net, sett["int_ip"])
                begin_line = ""
                fix_name = "# {}".format(name)
                if name in exclude_leaves:
                    begin_line = "# "
                    fix_name += " (found in exlude_leaves)"
                f.write("{}\n".format(fix_name))
                f.write("{}{}\n".format(begin_line, r0))
                f.write("{}{}\n".format(begin_line, r1))
            f.write("\n")
    os.chmod(routes_f, 0o755)
    rc_local = "/etc/rc.local"
    grp = "grep '{}' {}".format(routes_f, rc_local)
    if not os.path.exists(rc_local):
        with open(rc_local, "w") as f:
            f.write("#!/usr/local/bin/bash\n")
            f.write("{}\n".format(routes_f))
    elif not subprocess.check_output(grp, shell=True):
        with open(rc_local, "a") as f:
            f.write("{}\n".format(routes_f))
    os.chmod(rc_local, 0o755)
    subprocess.call(routes_f)

def setIpsec(sett):
    print("\n----setIPsec----")
    ipsec_f = "/usr/local/etc/racoon/ipsec.conf"
    str = "flush;\n"
    str += "spdflush;\n"
    if sett["my_name"] == sett["star_name"]:
        star_exclude_leaves = []
        if "exclude_leaves" in sett["leaves"][sett["my_name"]]:
            star_exclude_leaves = sett["leaves"][sett["my_name"]]["exclude_leaves"]
        for in_name in sorted(sett["leaves"]):
            if in_name == sett["my_name"]:
                continue
            str += "#----STAR -->{}\n".format(in_name.upper())
            if in_name in star_exclude_leaves:
                str += "# --{} found in exclude_leaves_star:({}) miss it\n".format(in_name, ",".join(star_exclude_leaves))
                continue
            exclude_leaves_in_name = []
            if "exclude_leaves" in sett["leaves"][in_name]:
                exclude_leaves_in_name = sett["leaves"][in_name]["exclude_leaves"]
            for net_in in sorted(sett["leaves"][in_name]["routes"]):
                for out_name in sorted(sett["leaves"]):
                    if in_name == out_name:
                        continue
                    begin_line = ""
                    fix_out_name = out_name
                    if out_name in exclude_leaves_in_name:
                        begin_line = "# "
                        fix_out_name += " (found in exlude_leaves for leaf: {})".format(in_name)
                    if out_name in star_exclude_leaves:
                        begin_line = "# "
                        fix_out_name += " (found in exlude_leaves for star: {})".format(sett["my_name"])
                    bn = 0
                    for net_out in sorted(sett["leaves"][out_name]["routes"]):
                        if not bn:
                            str += "\n# from {} \n".format(fix_out_name)
                            bn = 1
                        ipsec_ext_ip = sett["leaves"][in_name]["ext_ip"]
                        str += "{}spdadd {} {} any -P out ipsec esp/tunnel/{}/{}-{}{}/require;\n".format(begin_line, net_out, net_in, sett["star_ip"], ipsec_ext_ip, sett["star_ip"], ipsec_ext_ip)
                        str += "{}spdadd {} {} any -P in ipsec esp/tunnel/{}/{}-{}{}/require;\n\n".format(begin_line, net_in, net_out, ipsec_ext_ip, sett["star_ip"], ipsec_ext_ip, sett["star_ip"])
    else:
        exclude_leaves = []
        if "exclude_leaves" in sett["leaves"][sett["my_name"]]:
            exclude_leaves = sett["leaves"][sett["my_name"]]["exclude_leaves"]
        for name in sorted(sett["leaves"]):
            if name == sett["my_name"]:
                continue
            begin_line = ""
            fix_name = name
            if name in exclude_leaves:
                begin_line = "# "
                fix_name += " (found in exlude_leaves)"
            str += "\n# {}\n".format(fix_name)
            for ipsec_net in sorted(sett["leaves"][name]["routes"]):
                for my_net in sett["my_nets"]:
                    str += "{}spdadd {} {} any -P out ipsec esp/tunnel/{}/{}/require;\n".format(begin_line, my_net, ipsec_net, sett["ext_ip"], sett["star_ip"])
                    str += "{}spdadd {} {} any -P in ipsec esp/tunnel/{}/{}/require;\n\n".format(begin_line, ipsec_net, my_net, sett["star_ip"], sett["ext_ip"])
    print(str)
    with open(ipsec_f, "w") as f:
        f.write("#-----{}------#\n".format(last_update))
        f.write(str)
    subprocess.call("/etc/rc.d/ipsec stop", shell=True)
    subprocess.call("/etc/rc.d/ipsec start", shell=True)

def setRacoon(sett):
    print("\n----setRacoon----")
    racoon_f = "/usr/local/etc/racoon/racoon.conf"
    racoon_templ = """\
#-----{}------#
path include "/usr/local/etc/racoon" ;
path pre_shared_key "/usr/local/etc/racoon/psk.txt" ;
#log error ;
log warning ;
padding {{
        maximum_length 20 ;
        randomize off ;
        strict_check off ;
        exclusive_tail off ;
}}
listen {{
        isakmp {} [500] ;
}}
timer {{
        counter 5 ;
        interval 20 sec ;
        persend 1 ;
        phase1 30 sec ;
        phase2 15 sec ;
}}
""".format(last_update, sett["ext_ip"])
    racoon_peer = """\
{{
        exchange_mode main,aggressive;
        lifetime time 24 hour;
        doi ipsec_doi;
        situation identity_only;
        nonce_size 16;
        initial_contact on;
        proposal_check obey;
        proposal {{
                encryption_algorithm aes 256;
                hash_algorithm sha1;
                authentication_method pre_shared_key;
                dh_group 2;
        }}
}}
"""
    exclude_leaves = []
    if "exclude_leaves" in sett["leaves"][sett["my_name"]]:
        exclude_leaves = sett["leaves"][sett["my_name"]]["exclude_leaves"]
    if sett["my_name"] == sett["star_name"]:
        for name in sorted(sett["leaves"]):
            if name == sett["my_name"]:
                continue
            begin_line = ""
            if name in exclude_leaves:
                begin_line = "# "
            if begin_line:
                racoon_templ += "# {} in exclude_leaves miss it\n\n".format(name)
            else:
                racoon_templ += "# {}\n remote {}\n".format(name, sett["leaves"][name]["ext_ip"])
                racoon_templ += racoon_peer
    else:
        if sett["star_name"] in exclude_leaves:
            racoon_templ += "# {}\n # remote {} found in exclude_leaves for {} miss it \n\n".format(sett["star_name"], sett["star_ip"], sett["my_name"])
        else:
            racoon_templ += "# {}\nremote {}\n".format(sett["star_name"], sett["star_ip"])
            racoon_templ += racoon_peer
    racoon_templ += """\
sainfo anonymous
{{
        pfs_group 2;
        lifetime time 60 sec;
        encryption_algorithm aes 256 ;
        authentication_algorithm hmac_sha1 ;
        compression_algorithm deflate ;
}}
"""
    with open(racoon_f, "w") as f:
        f.write("#-----{}------#\n".format(last_update))
        f.write(racoon_templ)
    subprocess.call("/etc/rc.d/racoon stop", shell=True)
    subprocess.call("/etc/rc.d/racoon start", shell=True)

def setPsk(sett):
    print("\n----setPsk----")
    psk_f = "/usr/local/etc/racoon/psk.txt"
    fix = subprocess.check_output(["cat", "/data/config/fixpsk.txt"]).decode("utf-8")
    str = ""
    exclude_leaves = []
    if "exclude_leaves" in sett["leaves"][sett["my_name"]]:
        exclude_leaves = sett["leaves"][sett["my_name"]]["exclude_leaves"]
    if sett["my_name"] == sett["star_name"]:
        for name in sorted(sett["leaves"]):
            if name == sett["my_name"]:
                continue
            begin_line = ""
            if name in exclude_leaves:
                begin_line = "# found in exlude_leaves for {} ".format(sett["my_name"])
            hsh = crypt.crypt(sett["star_name"] + name, fix)
            if len(hsh) > 7:
                hsh = hsh[2:7]
            str += "{}{} {}_{}_{}\n".format(begin_line, sett["leaves"][name]["ext_ip"], sett["star_name"], name, hsh)
    else:
        hsh = crypt.crypt(sett["star_name"] + sett["my_name"], fix)
        if len(hsh) > 7:
            hsh = hsh[2:7]
        str = "{} {}_{}_{}\n".format(sett["star_ip"], sett["star_name"], sett["my_name"], hsh)
    print(str)
    with open(psk_f, "w") as f:
        f.write("#-----{}------#\n\n".format(last_update))
        f.write(str)
    os.chmod(psk_f, 0o600)

def isActualVersion(sett):
    print("\n----isActualVersion----")
    previous_ver = subprocess.check_output(["cat", "/data/config/tmp/previous_ver.tmp"]).decode("utf-8").strip()
    if not previous_ver:
        return False
    new_ver = float(sett["version"])
    previous_ver = float(previous_ver)
    print("new_ver={}".format(new_ver))
    print("prev_ver={}".format(previous_ver))
    if new_ver - previous_ver > 0.001:
        return False
    else:
        return True

def runSystem(run):
    subprocess.call(run, shell=True)
    if (subprocess.check_output(["echo", "$?"]).decode("utf-8").strip() != "0"):
        raise Exception("command exited with value {}".format(subprocess.check_output(["echo", "$?"]).decode("utf-8").strip()))

def checkDisable(sett):
    print("-----checkDisable-----")
    for name in sett["star_disable"].split(","):
        name = name.strip()
        if name == sett["my_name"] or name == "all":
            print("my_name {} is disabled, exit".format(name))
            if True:
                subprocess.call("/etc/rc.d/racoon stop", shell=True)
                subprocess.call("/etc/rc.d/ipsec stop", shell=True)
                with open("/usr/local/etc/racoon/ipsec.conf", "w") as f:
                    f.write("")
                with open("/usr/local/etc/racoon/racoon.conf", "w") as f:
                    f.write("")
                os.remove("/data/config/tmp/previous_ver.tmp")
                exit(1)

sett = fillSett()
checkDisable(sett)
if not isActualVersion(sett) or force == 1:
    last_update = subprocess.check_output(["date"]).decode("utf-8").strip()
    last_update += "-version:{}".format(sett["version"])
    setRoutes(sett)
    setIpsec(sett)
    setRacoon(sett)
    subprocess.call("echo {}>/data/config/tmp/previous_ver.tmp".format(sett["version"]), shell=True)


