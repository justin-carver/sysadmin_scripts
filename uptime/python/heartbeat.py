# Simply iterates through hosts_to_check. If they cannot be reached,
# the host will be appended to down_hosts[] and sent via email to the
# information below.
#
# Author: Justin Carver 2023

import subprocess
import smtplib
from email.mime.text import MIMEText

hosts_to_check = ["10.0.0.27"]
from_email = "email.address.com"
to_email = "email@address.com"
smtp_server = "smtp-server.local.com"
smtp_port = 587
smtp_user = "USERNAME"
smtp_pass = "PASSWORD"

down_hosts = []

def is_servers_up(hosts):
    for host in hosts:
        try:
            output = subprocess.check_output(["ping", "-c", "1", host], stderr=subprocess.STDOUT, universal_newlines=True)
            return "1 packets transmitted, 1 received" in output
        except subprocess.CalledProcessError as e:
            print(f"Failed to reach the server: {e}.")
            down_hosts.append(host)

def send_email(subject, message, from_email, to_email, smtp_server, smtp_port, smtp_user, smtp_pass):
    msg = MIMEText(message)
    msg['Subject'] = subject
    msg['From'] = from_email
    msg['To'] = to_email

    try:
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(smtp_user, smtp_pass)
            server.sendmail(from_email, [to_email], msg.as_string())
        print("Email sent successfully.")
    except Exception as e:
        print(f"Failed to send email: {e}")

if is_servers_up(hosts_to_check):
    print("Server is up and running.")
else:
    down_hosts_str = "\n".join(down_hosts)
    message = f"The following hosts are not online:\n{down_hosts_str}"
    print("Server is down. Sending alert email...")
    send_email("Server Down", message, from_email, to_email, smtp_server, smtp_port, smtp_user, smtp_pass)