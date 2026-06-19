#!/bin/bash
# Update and install Apache
apt update -y
apt install -y apache2

# Fetch IMDSv2 token
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)

# Get instance ID
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s \
  http://169.254.169.254/latest/meta-data/instance-id)

# Create index.html with instance ID injected
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Cloud Infrastructure Platform</title>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<style>
body { font-family:'Poppins',sans-serif; background:#0f172a; color:white; text-align:center; padding:50px; }
.container { background:rgba(255,255,255,0.08); padding:30px; border-radius:12px; display:inline-block; }
.instance { color:#38bdf8; font-weight:600; }
.status { margin-top:20px; padding:12px; border-radius:50px; background:#16a34a; font-weight:600; display:inline-block; }
</style>
</head>
<body>
<div class="container">
  <h1>Cloud Infrastructure <span style="color:#60a5fa;">Platform</span></h1>
  <p>Highly Available Infrastructure deployed with Terraform and AWS services.</p>
  <h2>Compute Instance</h2>
  <p>Instance ID: <span class="instance">${INSTANCE_ID}</span></p>
  <div class="status">✓ Infrastructure Operational</div>
</div>
</body>
</html>
EOF

# Enable and start Apache
systemctl enable apache2
systemctl start apache2
