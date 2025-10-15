#! /bin/bash
set -euo pipefail

# 로그 남기기
exec >>(tee -a /var/log/startup-script.log) 2>&1
echo "[$(date -ls)] startup-script begin (Debian + Nginx)"

MD="http://169.254.169.254/computeMetadata/v1"
HDR="Metadata-Flavor: Google"

# 메타데이터 서버 대기
for i in {1..30}; do
	if curl -fsl -H "$HDR" "$MD/"; then
		break
	fi
	sleep 2
done

# env 읽기(없으면 default)
ENV_VAL=$(curl -fs -H "$HDR" "$MD/instance/attributes/env" || echo "default")
echo "ENV_VAL=$ENV_VAL"

export DEBIAN_FRONTEND=noninteractive

# apt 재시도
for i in {1..5}; do
	if apt-get update && apt-get install -y nginx; then
	  echo "apt ok on try $i"
	  break
	fi
	echo "apt failed try $i; retrying ..."
	sleep 5
done

mkdir -p /var/www/html
echo "<h1>Environment: $ENV_VAL</h1>" > /var/www/html/index.html

systemctl enable nginx
systemctl restart nginx

echo "[$(date -ls)] startup-script done"