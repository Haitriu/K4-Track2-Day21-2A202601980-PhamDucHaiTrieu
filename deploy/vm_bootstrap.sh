#!/usr/bin/env bash
# Tai va chay: curl -sSL <raw-url-cua-file-nay> | bash
# Truoc do phai export AWS_ACCESS_KEY_ID va AWS_SECRET_ACCESS_KEY.
set -euo pipefail

: "${AWS_ACCESS_KEY_ID:?Chua export AWS_ACCESS_KEY_ID}"
: "${AWS_SECRET_ACCESS_KEY:?Chua export AWS_SECRET_ACCESS_KEY}"

ARTIFACT_BUCKET="day21-track2-2a202601980-phamduchaitrieu"
AWS_DEFAULT_REGION="us-east-1"
REPO_URL="https://github.com/Haitriu/K4-Track2-Day21-2A202601980-PhamDucHaiTrieu.git"

sudo dnf update -y
sudo dnf install -y python3-pip git

pip3 install --user fastapi "uvicorn[standard]" scikit-learn==1.4.2 joblib==1.4.2 boto3 pydantic

rm -rf ~/app
git clone "$REPO_URL" ~/app

sudo tee /etc/systemd/system/income-api.service > /dev/null <<EOF
[Unit]
Description=Income Model Inference Server
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/home/ec2-user/app
Environment="ARTIFACT_BUCKET=${ARTIFACT_BUCKET}"
Environment="AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
Environment="AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
Environment="AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}"
Environment="PATH=/home/ec2-user/.local/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=/home/ec2-user/.local/bin/uvicorn src.serve:app --host 0.0.0.0 --port 8080 --app-dir /home/ec2-user/app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable income-api
sudo systemctl restart income-api

sleep 3
curl -sf http://localhost:8080/healthz && echo "OK - service da chay"

if [ ! -f ~/.ssh/income_deploy ]; then
  ssh-keygen -t ed25519 -f ~/.ssh/income_deploy -N "" -C "github-actions-deploy"
fi
grep -qxF "$(cat ~/.ssh/income_deploy.pub)" ~/.ssh/authorized_keys 2>/dev/null || \
  cat ~/.ssh/income_deploy.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo "----- COPY PRIVATE KEY BEN DUOI VAO GITHUB SECRET 'SERVER_SSH_KEY' -----"
cat ~/.ssh/income_deploy
echo "----- HET PRIVATE KEY -----"

echo "IP cong khai cua VM nay:"
curl -s http://169.254.169.254/latest/meta-data/public-ipv4; echo
