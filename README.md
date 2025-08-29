# Claude Code 智能包装器使用指南

Claude Code 智能包装器自动处理 Pro 用户限制，当遇到使用限制时会自动等待并在重置时间继续执行任务。

## 🚀 快速开始

### 1. 安装包装器

以管理员身份运行 PowerShell，然后执行：

```powershell
# 进入项目目录
cd E:\git\MCP\claude-wrapper

# 运行安装脚本
.\install.ps1
```

### 2. 选择安装方式

安装脚本会提供三种选择：

1. **全局安装（推荐）** - 替换系统 PATH 中的 claude 命令
2. **本地安装** - 仅在当前目录创建别名
3. **用户安装** - 添加到用户 PATH（不需要管理员权限）

### 3. 开始使用

安装完成后，正常使用 claude 命令即可：

```bash
claude /build --comprehensive
claude /implement user-auth --full
claude /analyze --deep --security
```

## 📋 功能特性

### ✅ 自动限制检测

包装器能自动检测以下限制信息：
- `limit reset at` 时间格式限制
- `rate limit` 频率限制
- `too many requests` 请求过多
- `quota exceeded` 配额超出
- `usage limit` 使用限制

### ⏰ 智能时间解析

支持多种时间格式：
- **绝对时间**：`14:30`, `2:30 PM`, `02:30`
- **相对时间**：`in 30 minutes`, `in 2 hours`
- **混合格式**：`in 1 hour and 30 minutes`

### 🔄 后台自动等待

- 精确定时等待到重置时间
- 终端最小化也能正常工作
- 自动恢复执行原始任务
- 状态持久化，重启后恢复

## 🛠️ 使用示例

### 基本使用

```bash
# 正常执行 Claude 命令
claude --help

# 长时间任务（可能遇到限制）
claude /build --comprehensive --analyze

# 查看当前状态
claude --status
```

### 遇到限制时

当遇到限制时，包装器会显示：

```
⚠️  检测到 Claude Pro 使用限制
⏰ 重置时间: 2024-08-29 14:30:00
⏳ 等待时间: 1小时25分钟
🤖 任务将在重置时间到达后自动继续
💡 你现在可以关闭终端，系统会在后台等待
```

### 自动恢复

到达重置时间后，包装器会自动：
1. 显示恢复提示
2. 继续执行原始命令
3. 输出执行结果

## 🔧 高级功能

### 状态查看

```bash
# 查看当前包装器状态
claude --status

# 输出示例：
# 📊 Claude Wrapper 状态:
# 🔄 等待状态: 等待中
# ⏰ 重置时间: 2024-08-29 14:30:00
# 📝 原始命令: claude /build --comprehensive
```

### 帮助信息

```bash
# 查看包装器帮助
claude --help

# 显示包装器功能说明
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