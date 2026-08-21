#!/usr/bin/env bash
# Chay script nay TREN VM (qua EC2 Instance Connect trong AWS Console),
# chi mot lan duy nhat de cai dat moi truong va systemd service.
#
# TRUOC KHI CHAY: thay <ACCESS_KEY_MOI> va <SECRET_KEY_MOI> ben duoi bang
# mot cap AWS access key MOI (rotate lai key cu vi da bi dan vao chat truoc do).
# Key nay chi can quyen doc bucket S3 (giong k4-ci-cd-bot).
set -euo pipefail

NEW_AWS_ACCESS_KEY_ID="<ACCESS_KEY_MOI>"
NEW_AWS_SECRET_ACCESS_KEY="<SECRET_KEY_MOI>"

sudo apt update -y
sudo apt install -y python3-pip git

pip3 install --break-system-packages fastapi "uvicorn[standard]" scikit-learn joblib boto3 pydantic

rm -rf ~/app
git clone https://github.com/Haitriu/K4-Track2-Day21-2A202601980-PhamDucHaiTrieu.git ~/app

sudo tee /etc/systemd/system/income-api.service > /dev/null <<EOF
[Unit]
Description=Income Model Inference Server
After=network.target

[Service]
User=$USER
WorkingDirectory=/home/$USER/app
Environment="ARTIFACT_BUCKET=day21-track2-2a202601980-phamduchaitrieu"
Environment="AWS_ACCESS_KEY_ID=${NEW_AWS_ACCESS_KEY_ID}"
Environment="AWS_SECRET_ACCESS_KEY=${NEW_AWS_SECRET_ACCESS_KEY}"
Environment="AWS_DEFAULT_REGION=us-east-1"
ExecStart=/usr/bin/python3 -m uvicorn src.serve:app --host 0.0.0.0 --port 8080 --app-dir /home/$USER/app
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

# Tao SSH key rieng de GitHub Actions dung khi restart service sau moi lan release
ssh-keygen -t ed25519 -f ~/.ssh/income_deploy -N "" -C "github-actions-deploy"
cat ~/.ssh/income_deploy.pub >> ~/.ssh/authorized_keys
echo "----- COPY PRIVATE KEY BEN DUOI VAO GITHUB SECRET 'SERVER_SSH_KEY' -----"
cat ~/.ssh/income_deploy
