#!/bin/bash
# claude-profile-kiro.sh
# claude-profile kiro 的 wrapper，自动检查并启动 kiro-gateway

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 首先检查并启动 kiro-gateway
"$SCRIPT_DIR/start-kiro-gateway.sh"

if [ $? -eq 0 ]; then
    echo ""
    echo "🚀 Kiro Gateway 已就绪"
    echo "✅ 可以继续使用 claude-profile kiro"
    echo ""
    echo "💡 提示: Kiro Gateway 运行在 http://localhost:8000"
    echo "📊 健康检查: curl http://localhost:8000/health"
else
    echo "⚠️  Kiro Gateway 启动失败"
fi
