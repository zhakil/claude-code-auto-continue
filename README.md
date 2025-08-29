# 🤖 Claude Code Auto-Continue 智能包装器

[![GitHub release](https://img.shields.io/github/release/zhakil/claude-code-auto-continue.svg)](https://github.com/zhakil/claude-code-auto-continue/releases)
[![License](https://img.shields.io/github/license/zhakil/claude-code-auto-continue.svg)](LICENSE)

Claude Code 智能包装器，自动处理 Pro 用户限制，支持终端最小化运行，让您无需人工干预即可完成长时间任务。

## ⚡ 一键安装

**推荐方式** - 复制以下命令到 PowerShell 中运行：

```powershell
irm https://raw.githubusercontent.com/zhakil/claude-code-auto-continue/main/quick-install.ps1 | iex
```

> 💡 **提示**：此命令会自动安装所有依赖（Node.js、Git、Claude Code）并配置包装器

### 其他安装方式

<details>
<summary>📦 GitHub直接安装</summary>

```powershell
irm https://raw.githubusercontent.com/zhakil/claude-code-auto-continue/main/install-from-github.ps1 | iex
```
</details>

<details>
<summary>🔧 手动安装</summary>

```powershell
# 克隆仓库
git clone https://github.com/zhakil/claude-code-auto-continue.git
cd claude-code-auto-continue

# 运行安装脚本
.\quick-install.ps1
```
</details>

## 🎯 使用方法

安装完成后，有两种使用方式：

### 方式1: 直接使用包装器（推荐）
```bash
# 使用完整路径调用包装器
"C:\Users\你的用户名\.claude-auto-continue\claude.cmd" --help
"C:\Users\你的用户名\.claude-auto-continue\claude.cmd" /build --comprehensive
```

### 方式2: 设置别名（可选）
在 PowerShell 配置文件中添加：
```powershell
Set-Alias claude "C:\Users\你的用户名\.claude-auto-continue\claude.cmd"
```

然后正常使用：
```bash
claude /build --comprehensive
claude /implement user-auth --full
claude /analyze --deep --security
```

## ✨ 功能特性

### 🔍 智能限制检测
- 自动监控 Claude Pro 使用限制消息
- 支持多种限制格式：`limit reset at`、`rate limit`、`quota exceeded` 等
- 实时输出监控，无延迟检测

### ⏰ 智能时间解析
- **绝对时间**：`14:30`、`2:30 PM`、`02:30`
- **相对时间**：`in 30 minutes`、`in 2 hours`
- **混合格式**：`in 1 hour and 30 minutes`

### 🤖 无人值守运行
- 精确定时等待到重置时间
- 终端最小化也能正常工作
- 自动恢复执行原始任务
- 状态持久化，重启后自动恢复

### 🔧 智能路径查询
- 自动检测 Claude Code 安装位置
- 支持多种安装方式（npm global、local、用户安装）
- 无需手动配置路径

### 📦 全自动安装
- 一键安装所有依赖（Node.js、Git、Claude Code）
- 智能环境检测和配置
- 支持全新电脑快速部署

## 🚀 工作流程演示

### 正常使用
```bash
# 查看状态
claude --status

# 执行长时间任务
claude /build --comprehensive
```

### 遇到限制时自动处理
```
🤖 Claude Code 智能包装器启动...
🔗 使用Claude路径: D:\npm-global\node_modules\@anthropic-ai\claude-code\cli.js

⚠️  检测到 Claude Pro 使用限制
⏰ 重置时间: 2024-08-29 14:30:00
⏳ 等待时间: 1小时25分钟
🤖 任务将在重置时间到达后自动继续
💡 你现在可以关闭终端，系统会在后台等待
```

### 自动恢复执行
```
🔔 限制时间已重置，自动恢复执行...
[继续执行原始 Claude Code 命令]
```

## 📊 状态监控

```bash
# 查看当前状态
claude --status

# 输出示例：
📊 Claude Wrapper 状态: 空闲
# 或者
📊 Claude Wrapper 状态: 等待中  
⏰ 重置时间: 2024-08-29 14:30:00
📝 原始命令: claude /build --comprehensive
```

## 📁 文件结构

```
claude-wrapper/
├── src/
│   └── claude-wrapper.ts      # 核心包装器逻辑
├── dist/                      # 编译后的文件
├── install.ps1               # 安装脚本
├── package.json              # 项目配置
├── tsconfig.json             # TypeScript配置
├── 检查状态.cmd              # 状态检查工具
├── 卸载.cmd                  # 卸载工具
└── README.md                 # 本文档
```

## 🚨 故障排除

### 常见问题

**Q: 安装后 claude 命令不工作**
A: 重新打开终端，或者运行 `refreshenv` 刷新环境变量

**Q: 没有检测到限制**
A: 检查 `.claude-wrapper.log` 文件，确认是否有限制信息被捕获

**Q: 时间解析错误**
A: 包装器会默认设置 1 小时后重试，可查看日志了解详情

**Q: 后台等待不工作**
A: 确保 Node.js 进程没有被杀死，检查任务管理器

### 日志文件

- **主日志**：`.claude-wrapper.log` - 记录所有操作
- **状态文件**：`.claude-wrapper-state.json` - 保存等待状态

### 卸载方法

如需卸载，运行项目目录中的 `卸载.cmd` 文件，或手动：
1. 从 PATH 中移除包装器目录
2. 删除 `claude.cmd` 文件
3. 恢复原始 claude 命令

## 🔄 工作流程

1. **正常执行** - 包装器透明运行 Claude Code
2. **检测限制** - 监控输出中的限制信息
3. **解析时间** - 提取重置时间并计算等待时长
4. **保存状态** - 将任务状态保存到磁盘
5. **自动等待** - 使用定时器精确等待
6. **恢复执行** - 时间到达后继续原始任务
7. **清理状态** - 任务完成后清理临时文件

## 🎯 使用建议

- **长期任务**：特别适合需要长时间执行的复杂构建或分析任务
- **批处理**：可以连续执行多个命令，遇到限制会自动处理
- **无人值守**：支持最小化或后台运行，无需人工干预
- **状态监控**：定期使用 `claude --status` 检查运行状态

## 📞 技术支持

如遇到问题，请检查：
1. 日志文件中的错误信息
2. Node.js 和 TypeScript 环境是否正常
3. Claude Code 是否正确安装
4. 网络连接和权限设置

包装器设计为透明运行，正常情况下您无需关心其存在，只需像平常一样使用 claude 命令即可。

## ⚙️ 配置选项

默认情况下，包装器无需任何配置即可工作。所有状态和日志都存储在您的用户主目录下的 `.claude-auto-continue` 文件夹中。

- **日志文件**: `~/.claude-auto-continue/.claude-wrapper.log`
- **状态文件**: `~/.claude-auto-continue/.claude-wrapper-state.json`

未来版本可能会支持更多自定义配置。

## 🤝 贡献指南

我们欢迎任何形式的贡献！如果您有好的想法或发现了 Bug，请：

1.  **Fork** 本仓库
2.  创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3.  提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4.  推送到分支 (`git push origin feature/AmazingFeature`)
5.  **提交 Pull Request**

我们建议在进行较大改动前先创建一个 Issue 进行讨论。

## 📄 许可证

本项目使用 [MIT License](LICENSE) 授权。

## 🙏 致谢

-   感谢 [Anthropic](https.google.com/search?q=Anthropic) 团队开发的 Claude Code。
-   感谢所有为本项目提供反馈和贡献的开发者。