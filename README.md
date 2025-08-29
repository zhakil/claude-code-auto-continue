# 🤖 Claude Code Auto-Continue

[![GitHub release](https://img.shields.io/github/release/zhakil/claude-code-auto-continue.svg)](https://github.com/zhakil/claude-code-auto-continue/releases)
[![License](https://img.shields.io/github/license/zhakil/claude-code-auto-continue.svg)](LICENSE)

Claude Code 智能包装器，自动处理 Pro 用户限制，支持后台运行，让您无需人工干预即可完成长时间任务。

## ⚡ 快速开始

**一键安装** - 复制以下命令到 PowerShell 中运行（需管理员权限）：

```powershell
irm https://raw.githubusercontent.com/zhakil/claude-code-auto-continue/main/quick-install.ps1 | iex
```

安装后直接使用 `claude` 命令，遇到限制会自动处理：

```bash
claude /build --comprehensive
claude /implement user-auth --full
```

## 🎯 使用方法

安装完成后直接使用 `claude` 命令，与原版完全一致：

```bash
# 查看帮助和状态
claude --help
claude --status

# 正常使用Claude Code（遇到限制会自动处理）
claude /build --comprehensive
claude /implement user-auth --full
claude /analyze --deep --security
```

## ✨ 核心功能

- 🔍 **智能限制检测** - 自动识别25+种限制消息格式
- ⏰ **智能时间解析** - 支持绝对时间(`14:30`)、相对时间(`in 30 minutes`)等20+种格式  
- 🤖 **无人值守运行** - 后台精确等待，终端可关闭
- 💾 **状态持久化** - 重启后自动恢复等待任务
- 🔧 **自动路径发现** - 智能检测Claude Code安装位置
- 📦 **一键部署** - 自动安装所有依赖和配置

## 🚀 工作原理

当检测到Claude Pro限制时：

1. **🔍 自动检测** - 识别限制信息和重置时间
2. **💾 保存状态** - 持久化保存当前任务到 `.claude-wrapper-state.json`  
3. **⏳ 后台等待** - 启动定时器，精确等待到重置时间
4. **🔔 自动恢复** - 时间到达后无缝继续执行原始任务

```
⚠️  检测到Claude Pro使用限制
⏰ 重置时间: 2024-08-29 14:30:00  
⏳ 等待时间: 1小时25分钟
💡 终端可关闭，系统会在后台等待并自动恢复
```

## 🛠️ 其他安装方式

<details>
<summary>📦 手动克隆安装</summary>

```powershell
git clone https://github.com/zhakil/claude-code-auto-continue.git
cd claude-code-auto-continue
.\quick-install.ps1
```
</details>

<details>
<summary>🔧 技术架构</summary>

- **TypeScript** - 700+行类型安全的核心逻辑
- **智能检测** - 25+种限制模式，20+种时间格式  
- **状态管理** - JSON持久化，Winston日志系统
- **进程管理** - 优雅的信号处理和恢复机制
</details>

## 🚨 故障排除

**Q: 安装后 claude 命令不工作**  
A: 重新打开终端或运行 `refreshenv`

**Q: 没有检测到限制**  
A: 检查 `.claude-wrapper.log` 文件查看详细日志

**Q: 后台等待不工作**  
A: 确保 Node.js 进程未被终止，检查任务管理器

### 状态监控
```bash
claude --status          # 查看当前状态
Get-Content .claude-wrapper.log -Tail 20  # 查看日志
```

## 📄 许可证

本项目使用 [MIT License](LICENSE) 授权。

## 🙏 致谢

感谢 [Anthropic](https://anthropic.com) 团队开发的 Claude Code。