# 🤖 Claude Code Auto-Continue

<div align="center">

[![GitHub release](https://img.shields.io/github/release/zhakil/claude-code-auto-continue.svg)](https://github.com/zhakil/claude-code-auto-continue/releases)
[![License](https://img.shields.io/github/license/zhakil/claude-code-auto-continue.svg)](LICENSE)

**Language / 语言选择**

[🇨🇳 中文](#中文) | [🇺🇸 English](#english)

</div>

---

## 中文

Claude Code 智能包装器，自动处理 Pro 用户限制，支持后台运行，让您无需人工干预即可完成长时间任务。

> 🎯 **核心价值**：遇到限制自动等待，到时间自动恢复，完全无人值守！

### ⚡ 快速开始

**一键安装** - 复制以下命令到 PowerShell 中运行（需管理员权限）：

```powershell
irm https://raw.githubusercontent.com/zhakil/claude-code-auto-continue/main/quick-install.ps1 | iex
```

安装后直接使用 `claude` 命令，遇到限制会自动处理：

```bash
claude /build --comprehensive
claude /implement user-auth --full
```

### 🎯 使用说明

安装完成后直接使用 `claude` 命令，与原版完全一致，**零学习成本**：

```bash
# 查看帮助和状态
claude --help
claude --status

# 正常使用Claude Code（遇到限制会自动处理）
claude /build --comprehensive      # 构建项目
claude /implement user-auth --full # 实现功能
claude /analyze --deep --security  # 深度分析
```

> 💡 **使用体验**：就像使用原版Claude Code一样，但再也不用担心限制中断工作了！

### ✨ 核心功能

- 🔍 **智能限制检测** - 自动识别25+种限制消息格式
- ⏰ **智能时间解析** - 支持绝对时间(`14:30`)、相对时间(`30分钟后`)等20+种格式  
- 🤖 **无人值守运行** - 后台精确等待，终端可关闭
- 💾 **状态持久化** - 重启后自动恢复等待任务
- 🔧 **自动路径发现** - 智能检测Claude Code安装位置
- 📦 **一键部署** - 自动安装所有依赖和配置

### 🚀 工作原理

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

### 🛠️ 其他安装方式

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

### 🚨 故障排除

**Q: 安装后 claude 命令不工作**  
A: 重新打开终端或运行 `refreshenv`

**Q: 没有检测到限制**  
A: 检查 `.claude-wrapper.log` 文件查看详细日志

**Q: 后台等待不工作**  
A: 确保 Node.js 进程未被终止，检查任务管理器

#### 状态监控
```bash
claude --status          # 查看当前状态
Get-Content .claude-wrapper.log -Tail 20  # 查看日志
```

---

## English

Intelligent Claude Code wrapper that automatically handles Pro user limits with background execution, enabling unattended long-running tasks.

> 🎯 **Core Value**: Auto-wait when limited, auto-resume when ready, completely unattended!

### ⚡ Quick Start

**One-click installation** - Copy and run in PowerShell (Administrator required):

```powershell
irm https://raw.githubusercontent.com/zhakil/claude-code-auto-continue/main/quick-install.ps1 | iex
```

After installation, use `claude` commands normally - limits will be handled automatically:

```bash
claude /build --comprehensive
claude /implement user-auth --full
```

### 🎯 Usage

Use `claude` commands exactly like the original - completely transparent, **zero learning curve**:

```bash
# Check help and status
claude --help
claude --status

# Normal Claude Code usage (limits handled automatically)
claude /build --comprehensive      # Build projects
claude /implement user-auth --full # Implement features
claude /analyze --deep --security  # Deep analysis
```

> 💡 **User Experience**: Just like using original Claude Code, but never worry about limit interruptions again!

### ✨ Core Features

- 🔍 **Smart Limit Detection** - Automatically recognizes 25+ limit message formats
- ⏰ **Intelligent Time Parsing** - Supports absolute time(`14:30`), relative time(`in 30 minutes`), 20+ formats
- 🤖 **Unattended Operation** - Background precise waiting, terminal can be closed
- 💾 **State Persistence** - Auto-recovery of waiting tasks after restart
- 🔧 **Auto Path Discovery** - Intelligently detects Claude Code installation location
- 📦 **One-click Deployment** - Auto-installs all dependencies and configurations

### 🚀 How It Works

When Claude Pro limits are detected:

1. **🔍 Auto Detection** - Identifies limit information and reset time
2. **💾 Save State** - Persistently saves current task to `.claude-wrapper-state.json`
3. **⏳ Background Wait** - Starts timer, precisely waits until reset time
4. **🔔 Auto Resume** - Seamlessly continues original task when time arrives

```
⚠️  Claude Pro usage limit detected
⏰ Reset time: 2024-08-29 14:30:00
⏳ Wait time: 1 hour 25 minutes
💡 Terminal can be closed, system will wait in background and auto-resume
```

### 🛠️ Alternative Installation Methods

<details>
<summary>📦 Manual Clone Installation</summary>

```powershell
git clone https://github.com/zhakil/claude-code-auto-continue.git
cd claude-code-auto-continue
.\quick-install.ps1
```
</details>

<details>
<summary>🔧 Technical Architecture</summary>

- **TypeScript** - 700+ lines of type-safe core logic
- **Smart Detection** - 25+ limit patterns, 20+ time formats
- **State Management** - JSON persistence, Winston logging system
- **Process Management** - Graceful signal handling and recovery mechanisms
</details>

### 🚨 Troubleshooting

**Q: Claude command doesn't work after installation**  
A: Restart terminal or run `refreshenv`

**Q: Limits not detected**  
A: Check `.claude-wrapper.log` file for detailed logs

**Q: Background waiting doesn't work**  
A: Ensure Node.js process isn't terminated, check Task Manager

#### Status Monitoring
```bash
claude --status          # Check current status
Get-Content .claude-wrapper.log -Tail 20  # View logs
```

---

### 📄 License / 许可证

This project is licensed under the [MIT License](LICENSE).

本项目使用 [MIT License](LICENSE) 授权。

### 🙏 Acknowledgments / 致谢

Thanks to [Anthropic](https://anthropic.com) team for developing Claude Code.

感谢 [Anthropic](https://anthropic.com) 团队开发的 Claude Code。