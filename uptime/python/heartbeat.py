# Pings the host. If the host is down, will create a flag_file to keep track
# of the previous check of it's uptime. If the file is newer than 1 hour,
# the script will not execute, buying the admin time to correct the issue.
# If it has been more than 1 hour, the server will send an email via SMTP.
# 
# The script must have write access to the specified 'flags' folder below.
#
# Each tracked host should get a separate crontab entry.
# Crontab Example: 
# */5 * * * * /usr/bin/python3 /root/scripts/heartbeat.py 10.0.0.27 "Sandbox Server" >> /var/log/heartbeat.log 2>&1
#
# Author: Justin Carver 2023

import subprocess
import smtplib
from email.mime.text import MIMEText
import os
import datetime
import argparse
import time

# Argument parsing
parser = argparse.ArgumentParser(description='Monitor a server and send email alerts when it is down.')
parser.add_argument('host_ip', help='IP address of the host to monitor')
parser.add_argument('host_name', help='Name of the host for identification')
args = parser.parse_args()

from_email = "email.address.com"
to_email = "email@address.com"
smtp_server = "smtp-server.local.com"
smtp_port = 587
smtp_user = "USERNAME"
smtp_pass = "PASSWORD"

# Flag file
flags_dir = "./flags"

# Ensure 'flags' directory exists
if not os.path.exists(flags_dir):
    os.makedirs(flags_dir)

down_flag_file = os.path.join(flags_dir, f"{args.host_name}_{args.host_ip}.flag")

def is_server_up(host_ip):
    try:
        output = subprocess.check_output(["ping", "-c", "1", host_ip], stderr=subprocess.STDOUT, universal_newlines=True)
        return "1 packets transmitted, 1 received" in output
    except subprocess.CalledProcessError as e:
        print(f"[{datetime.datetime.now()}] Failed to reach {args.host_name} ({host_ip}): {e}.")
        return False

def send_email(subject, message, from_email, to_email, smtp_server, smtp_port, smtp_user, smtp_pass):
    msg = MIMEText(message)
    msg['Subject'] = subject
    msg['From'] = from_email
    msg['To'] = to_email

    # Set headers for high importance
    msg['X-Priority'] = '1'  # High priority (1 = highest, 3 = normal, 5 = lowest)
    msg['Priority'] = 'urgent'
    msg['Importance'] = 'high'

    try:
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(smtp_user, smtp_pass)
            server.sendmail(from_email, [to_email], msg.as_string())
        print(f"[{datetime.datetime.now()}] Email sent successfully.")
    except Exception as e:
        print(f"[{datetime.datetime.now()}] Failed to send email: {e}")

if is_server_up(args.host_ip):
    print(f"[{datetime.datetime.now()}] {args.host_name} ({args.host_ip}) is up and running.")
    if os.path.exists(down_flag_file):
        os.remove(down_flag_file)
else:
    if os.path.exists(down_flag_file):
        print(f"[{datetime.datetime.now()}] {args.host_name} ({args.host_ip}) is still down. No new alert sent.")
        # Check the last modified time of the flag file
        last_modified = os.path.getmtime(down_flag_file)
        if time.time() - last_modified > 3600:  # More than an hour ago
            print(f"[{datetime.datetime.now()}] Over an hour since last alert. Sending another alert...")
            message = f"{args.host_name} ({args.host_ip}) is still offline."
            send_email(f"{args.host_name} Server Down", message, from_email, to_email, smtp_server, smtp_port, smtp_user, smtp_pass)
            os.utime(down_flag_file, None)  # Update the flag file's last modified time
    else:
        print(f"[{datetime.datetime.now()}] {args.host_name} ({args.host_ip}) is down. Sending alert email...")
        message = f"{args.host_name} ({args.host_ip}) is not online."
        send_email(f"{args.host_name} Server Down", message, from_email, to_email, smtp_server, smtp_port, smtp_user, smtp_pass)
        open(down_flag_file, 'a').close()