# Claude Code Auto-Continue GitHub一键安装
# 适用于全新电脑，支持从GitHub直接下载和安装

param(
    [string]$Branch = "main",
    [switch]$Local,
    [switch]$Quiet,
    [string]$InstallDir = ""
)

$ErrorActionPreference = "Stop"

if (-not $Quiet) {
    Write-Host "🚀 Claude Code Auto-Continue GitHub安装器" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host ""
}

# GitHub仓库信息
$GitHubRepo = "claude-code-auto-continue"
$GitHubUser = "your-username"  # 这里需要替换为实际的GitHub用户名
$RepoUrl = "https://github.com/$GitHubUser/$GitHubRepo"

# 检查管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not $Local -and -not (Test-Administrator)) {
    Write-Host "⚠️  需要管理员权限来修改系统PATH" -ForegroundColor Yellow
    Write-Host "正在以管理员身份重新启动..." -ForegroundColor Yellow
    
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`" -Branch $Branch"
    if ($Local) { $arguments += " -Local" }
    if ($Quiet) { $arguments += " -Quiet" }
    if ($InstallDir) { $arguments += " -InstallDir `"$InstallDir`"" }
    
    Start-Process powershell -Verb RunAs -ArgumentList $arguments -Wait
    exit
}

# 安装必要工具
Write-Host "📋 检查和安装必要工具..." -ForegroundColor Yellow

# 检查并安装Node.js
try {
    $nodeVersion = & node --version 2>$null
    if ($nodeVersion) {
        Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
    } else {
        throw "Node.js not found"
    }
} catch {
    Write-Host "正在安装 Node.js..." -ForegroundColor Yellow
    winget install OpenJS.NodeJS --silent --accept-source-agreements --accept-package-agreements
    Write-Host "✅ Node.js 安装完成" -ForegroundColor Green
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# 检查并安装Git
try {
    $gitVersion = & git --version 2>$null
    if ($gitVersion) {
        Write-Host "✅ Git: $gitVersion" -ForegroundColor Green
    } else {
        throw "Git not found"
    }
} catch {
    Write-Host "正在安装 Git..." -ForegroundColor Yellow
    winget install Git.Git --silent --accept-source-agreements --accept-package-agreements
    Write-Host "✅ Git 安装完成" -ForegroundColor Green
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# 检查并安装Claude Code
Write-Host ""
Write-Host "🔍 检查Claude Code安装..." -ForegroundColor Yellow

$claudeInstalled = $false
try {
    & claude --version 2>$null
    $claudeInstalled = $true
    Write-Host "✅ Claude Code 已安装" -ForegroundColor Green
} catch {
    Write-Host "正在安装 Claude Code..." -ForegroundColor Yellow
    & npm install -g @anthropic-ai/claude-code
    Write-Host "✅ Claude Code 安装完成" -ForegroundColor Green
}

# 确定安装目录
if ($InstallDir -eq "") {
    $InstallDir = if ($Local) { Join-Path $PWD.Path "claude-auto-continue" } else { "$env:USERPROFILE\.claude-auto-continue" }
}

Write-Host ""
Write-Host "📦 下载项目到: $InstallDir" -ForegroundColor Yellow

# 下载项目
if (Test-Path $InstallDir) {
    Write-Host "⚠️  目录已存在，正在更新..." -ForegroundColor Yellow
    Remove-Item $InstallDir -Recurse -Force
}

try {
    & git clone "$RepoUrl.git" "$InstallDir" --branch $Branch --depth 1
    Write-Host "✅ 项目下载完成" -ForegroundColor Green
} catch {
    Write-Host "❌ 无法从GitHub下载项目" -ForegroundColor Red
    Write-Host "正在使用本地创建方式..." -ForegroundColor Yellow
    
    # 调用本地安装脚本的逻辑
    & powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/$GitHubUser/$GitHubRepo/main/quick-install.ps1')"
    exit
}

# 进入项目目录并安装
Push-Location $InstallDir

Write-Host ""
Write-Host "📦 安装依赖..." -ForegroundColor Yellow
& npm install

Write-Host ""
Write-Host "🔨 构建项目..." -ForegroundColor Yellow
& npm run build

# 配置PATH
if (-not $Local) {
    Write-Host ""
    Write-Host "🔧 配置系统PATH..." -ForegroundColor Yellow
    
    $currentPATH = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    if ($currentPATH -notlike "*$InstallDir*") {
        $newPATH = "$InstallDir;$currentPATH"
        [Environment]::SetEnvironmentVariable("PATH", $newPATH, "User")
        Write-Host "✅ PATH配置完成" -ForegroundColor Green
        $env:Path = $newPATH
    }
    
    # 创建claude命令
    $claudeCmd = @"
@echo off
node "$InstallDir\dist\claude-wrapper.js" %*
"@
    $claudeCmd | Out-File -FilePath (Join-Path $InstallDir "claude.cmd") -Encoding ASCII
}

Pop-Location

Write-Host ""
Write-Host "🎉 GitHub安装完成！" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host ""
Write-Host "📋 使用方法：" -ForegroundColor Yellow

if ($Local) {
    Write-Host "cd `"$InstallDir`"" -ForegroundColor Gray
    Write-Host ".\claude.cmd --help" -ForegroundColor Gray
} else {
    Write-Host "claude --help  # 重新打开终端后生效" -ForegroundColor Gray
    Write-Host "claude --status" -ForegroundColor Gray
    Write-Host "claude /build --comprehensive" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🚀 现在可以正常使用，遇到Pro限制会自动处理！" -ForegroundColor Cyan