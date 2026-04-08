---
date: 2026-04-08
created: 2026-04-08 19:25:00 +0800
tags: [docs, kiro-gateway, project]
---

# Kiro Gateway 项目适配文档

## 项目位置

`/Users/gyliu/brain-drops/projects/kiro-gateway`

## 适配变动记录

### 1. Region 修改（核心修复）

**问题：** GitHub issue #81 - `ap-northeast-1` 的 Kiro API endpoint 无法访问

**解决方案：** 将 API endpoint 改为 `us-east-1`

**修改文件：** `~/.aws/sso/cache/kiro-auth-token.json`

```json
// 修改前
"region": "ap-northeast-1"

// 修改后
"region": "us-east-1"
```

**说明：**
- 这只是改变 API 调用的服务器地址
- 不影响 AWS SSO 账户本身（仍是 ap-northeast-1）
- 每次重新登录 Kiro IDE 后需要重新修改

### 2. 代理配置

**修改文件：** `.env`

```bash
# 添加代理配置
VPN_PROXY_URL="http://127.0.0.1:7897"
```

**说明：**
- 使用本地 Clash HTTP 代理
- 端口 7897 是 Clash Verge 的默认 mixed-port

### 3. 自动修复脚本

**文件：** `~/fix-kiro-region.sh`

```bash
#!/bin/bash
# 自动修复 region 并重启服务
TOKEN_FILE="$HOME/.aws/sso/cache/kiro-auth-token.json"

if [ -f "$TOKEN_FILE" ]; then
    python3 << EOF
import json
import sys

with open('$TOKEN_FILE', 'r') as f:
    data = json.load(f)

if data.get('region') != 'us-east-1':
    data['region'] = 'us-east-1'
    with open('$TOKEN_FILE', 'w') as f:
        json.dump(data, f, indent=2)
    print("✅ Region 已修复为 us-east-1")
    sys.exit(1)
else:
    print("✅ Region 已经是 us-east-1")
    sys.exit(0)
EOF

    if [ $? -eq 1 ]; then
        echo "正在重启 kiro-gateway..."
        pkill -f "python3 main.py" 2>/dev/null
        sleep 1
        cd /Users/gyliu/brain-drops/projects/kiro-gateway && nohup python3 main.py > /tmp/kiro-gateway.log 2>&1 &
        echo "服务已重启"
    fi
else
    echo "❌ Token 文件不存在: $TOKEN_FILE"
fi
```

## 快速启动

```bash
# 启动服务
cd /Users/gyliu/brain-drops/projects/kiro-gateway
python3 main.py

# 或使用 nohup 后台运行
cd /Users/gyliu/brain-drops/projects/kiro-gateway
nohup python3 main.py > /tmp/kiro-gateway.log 2>&1 &
```

## 服务检查

```bash
# 检查健康状态
curl http://localhost:8000/health

# 测试 API
curl -X POST http://localhost:8000/v1/messages \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer kiro-proxy-local-2024" \
  -d '{
    "model": "claude-opus-4-6",
    "messages": [{"role": "user", "content": "你好"}],
    "max_tokens": 50
  }'
```

## 自动启动集成

创建 shell alias 用于 `claude-profile kiro` 命令：

```bash
# 添加到 ~/.zshrc
alias claude-profile-kiro='check_and_start_kiro_gateway && claude-profile kiro'

check_and_start_kiro_gateway() {
    if ! curl -s http://localhost:8000/health > /dev/null; then
        echo "🔄 Kiro Gateway 未运行，正在启动..."
        ~/brain-drops/projects/kiro-gateway/start-kiro-gateway.sh
        sleep 3
    fi
}
```

## 参考资料

- [GitHub Issue #81](https://github.com/jwadow/kiro-gateway/issues/81) - Region override from credentials file causes connection failure
- [Kiro Gateway README](https://github.com/jwadow/kiro-gateway)
