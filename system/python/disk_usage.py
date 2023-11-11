import subprocess
import smtplib
import os
from email.mime.text import MIMEText

from_email = "email.address.com"
to_email = "email@address.com"
smtp_server = "smtp-server.local.com"
smtp_port = 587
smtp_user = "USERNAME"
smtp_pass = "PASSWORD"

def get_disk_usage(partition):
    process = subprocess.Popen(['df', '-h', partition], stdout=subprocess.PIPE)
    stdout = process.communicate()[0].decode('utf-8')
    return int(stdout.splitlines()[1].split()[4].rstrip('%'))

def send_email(subject, message, to_email):
    msg = MIMEText(message)
    msg['Subject'] = subject
    msg['From'] = from_email
    msg['To'] = to_email

    # Set headers for high importance
    msg['X-Priority'] = '1'  # High priority (1 = highest, 3 = normal, 5 = lowest)
    msg['Priority'] = 'urgent'
    msg['Importance'] = 'high'

    # Assuming SMTP setup is done
    with smtplib.SMTP(smtp_server, smtp_port) as server:
        server.starttls()
        server.login(smtp_user, smtp_pass)
        server.sendmail(from_email, [to_email], msg.as_string())

partition = "/"
threshold = 80
current_usage = get_disk_usage(partition)

if current_usage >= threshold:
    message = f"Disk usage on {os.uname()[1]} in partition {partition} is above {threshold}%. Current usage is {current_usage}%."
    send_email(f"{os.uname()[1]} ({partition}) Disk Usage Alert", message, to_email)