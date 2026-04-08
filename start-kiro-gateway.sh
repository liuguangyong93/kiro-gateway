#!/bin/bash
# start-kiro-gateway.sh
# 自动检查并启动 kiro-gateway 服务

# 获取脚本所在目录（支持符号链接）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
LOG_FILE="/tmp/kiro-gateway.log"
HEALTH_URL="http://localhost:8000/health"
TOKEN_FILE="$HOME/.aws/sso/cache/kiro-auth-token.json"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 检查 Kiro Gateway 服务状态..."

# 检查服务是否已在运行
if curl -s "$HEALTH_URL" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Kiro Gateway 服务已在运行${NC}"
    curl -s "$HEALTH_URL" | python3 -m json.tool 2>/dev/null || curl -s "$HEALTH_URL"
    exit 0
fi

echo -e "${YELLOW}⚠️  服务未运行，准备启动...${NC}"

# 检查项目目录
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}❌ 项目目录不存在: $PROJECT_DIR${NC}"
    exit 1
fi

# 修复 region（如果需要）
if [ -f "$TOKEN_FILE" ]; then
    python3 << EOF
import json
import sys

try:
    with open('$TOKEN_FILE', 'r') as f:
        data = json.load(f)

    if data.get('region') != 'us-east-1':
        data['region'] = 'us-east-1'
        with open('$TOKEN_FILE', 'w') as f:
            json.dump(data, f, indent=2)
        print("📝 已修复 region 为 us-east-1")
except Exception as e:
    print(f"⚠️  修复 region 时出错: {e}")
EOF
fi

# 停止可能存在的旧进程
echo "🛑 停止旧进程..."
pkill -f "python3 main.py" 2>/dev/null || true
sleep 1

# 启动服务
echo "🚀 启动 Kiro Gateway..."
cd "$PROJECT_DIR" || exit 1
nohup python3 main.py > "$LOG_FILE" 2>&1 &

# 等待服务启动
echo "⏳ 等待服务启动..."
for i in {1..10}; do
    sleep 1
    if curl -s "$HEALTH_URL" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Kiro Gateway 启动成功！${NC}"
        echo ""
        echo "📊 健康状态:"
        curl -s "$HEALTH_URL" | python3 -m json.tool 2>/dev/null || curl -s "$HEALTH_URL"
        echo ""
        echo "📝 日志文件: $LOG_FILE"
        exit 0
    fi
    echo "  尝试 $i/10..."
done

echo -e "${RED}❌ 服务启动失败，请检查日志: $LOG_FILE${NC}"
echo "最后 20 行日志:"
tail -20 "$LOG_FILE"
exit 1
