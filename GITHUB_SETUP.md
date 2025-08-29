# GitHub 仓库设置指南

## 1. 创建GitHub仓库

1. **访问GitHub**: https://github.com
2. **点击 "New repository"** 或访问: https://github.com/new
3. **仓库设置**:
   - Repository name: `claude-code-auto-continue`
   - Description: `Claude Code智能包装器 - 自动处理Pro用户限制，支持终端最小化运行`
   - 选择 `Public`
   - **不要**勾选 "Initialize this repository with a README"
   - **不要**添加 .gitignore 或 license
4. **点击 "Create repository"**

## 2. 推送代码到GitHub

创建仓库后，GitHub会显示命令。在PowerShell中执行：

```powershell
# 进入项目目录
cd "E:\git\MCP\claude-wrapper"

# 添加远程仓库（替换YOUR_USERNAME为你的GitHub用户名）
git remote add origin https://github.com/YOUR_USERNAME/claude-code-auto-continue.git

# 推送代码
git branch -M main
git push -u origin main
```

## 3. 一键安装命令

仓库创建完成后，用户可以使用以下命令一键安装：

### 方法1: PowerShell直接安装
```powershell
# 下载并运行安装脚本
Invoke-Expression (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/YOUR_USERNAME/claude-code-auto-continue/main/quick-install.ps1')
```

### 方法2: 手动下载安装
```powershell
# 克隆仓库
git clone https://github.com/YOUR_USERNAME/claude-code-auto-continue.git
cd claude-code-auto-continue

# 运行安装脚本
.\quick-install.ps1
```

### 方法3: GitHub一键安装
```powershell
# 直接从GitHub安装
Invoke-Expression (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/YOUR_USERNAME/claude-code-auto-continue/main/install-from-github.ps1')
```

## 4. 更新install-from-github.ps1中的用户名

请编辑 `install-from-github.ps1` 文件，将以下行：
```powershell
$GitHubUser = "your-username"  # 这里需要替换为实际的GitHub用户名
```
替换为：
```powershell
$GitHubUser = "YOUR_ACTUAL_USERNAME"
```

## 5. 仓库配置完成

配置完成后，任何人都可以在新电脑上使用一行命令安装：

```powershell
# 一键安装命令
irm https://raw.githubusercontent.com/YOUR_USERNAME/claude-code-auto-continue/main/quick-install.ps1 | iex
```

这个命令会：
- 自动检测和安装 Node.js、Git、Claude Code
- 下载并构建包装器
- 配置系统PATH
- 创建claude命令替换

安装完成后就可以正常使用claude命令，遇到Pro限制会自动处理！