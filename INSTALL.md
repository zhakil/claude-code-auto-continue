# 🚀 Claude Code Auto-Continue 一键安装指南

Claude Code 智能包装器，自动处理 Pro 用户限制，支持终端最小化运行。

## ⚡ 一键安装命令

### 方法1: 推荐 - PowerShell一键安装
```powershell
# 复制粘贴以下命令到PowerShell中运行（以管理员身份）
irm https://raw.githubusercontent.com/zhakil/claude-code-auto-continue/main/quick-install.ps1 | iex
```

### 方法2: GitHub直接安装
```powershell
# 从GitHub下载并安装
irm https://raw.githubusercontent.com/zhakil/claude-code-auto-continue/main/install-from-github.ps1 | iex
```

### 方法3: 手动克隆安装
```powershell
# 克隆仓库
git clone https://github.com/zhakil/claude-code-auto-continue.git
cd claude-code-auto-continue

# 运行安装脚本
.\quick-install.ps1
```

## 📋 安装后使用

安装完成后，正常使用 claude 命令：

```bash
# 查看帮助
claude --help

# 检查状态
claude --status

# 正常使用Claude Code
claude /build --comprehensive
claude /implement user-auth --full
claude /analyze --deep --security
```

## ✨ 功能特性

- ✅ **自动检测限制**: 监控 Claude Pro 使用限制
- ✅ **智能时间解析**: 支持多种时间格式 (14:30、2:30 PM、in 30 minutes)
- ✅ **无人值守运行**: 终端最小化也能正常工作
- ✅ **状态持久化**: 重启后自动恢复等待任务
- ✅ **一键安装**: 支持全新电脑自动配置所有依赖

## 🔄 自动处理流程

当遇到 Pro 限制时：
1. 🔍 **检测限制信息** - 自动识别 "limit reset at" 等信息
2. ⏰ **解析重置时间** - 智能解析各种时间格式
3. 💾 **保存任务状态** - 持久化保存当前任务
4. ⏳ **自动等待** - 精确等待到重置时间
5. 🚀 **恢复执行** - 自动继续执行原始任务

## 🛠️ 系统要求

- Windows 10/11
- PowerShell 5.1+ (Windows自带)
- 管理员权限（用于配置系统PATH）

## 📞 故障排除

### 常见问题

**Q: 安装后 claude 命令不工作**
A: 重新打开终端，或运行 `refreshenv`

**Q: 没有检测到限制**  
A: 检查 `.claude-wrapper.log` 文件中的日志信息

**Q: 权限错误**
A: 以管理员身份运行 PowerShell

### 查看状态
```bash
# 查看当前包装器状态
claude --status

# 查看日志文件
Get-Content .claude-wrapper.log -Tail 20
```

## 🎯 使用示例

```bash
# 长时间任务示例
claude /build --comprehensive

# 当遇到限制时，会显示：
# ⚠️  检测到Claude Pro使用限制
# ⏰ 重置时间: 2024-08-29 14:30:00
# ⏳ 等待时间: 1小时25分钟
# 🤖 任务将在重置时间到达后自动继续
# 💡 你现在可以关闭终端，系统会在后台等待

# 到达重置时间后自动继续执行任务
```

现在您可以在任何全新电脑上使用一行命令快速安装！🚀