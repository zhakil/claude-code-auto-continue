# Claude Wrapper 自动安装脚本
# 用于替换系统中的Claude命令以支持自动限制处理

Write-Host "🚀 Claude Code 智能包装器安装向导" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

# 检查管理员权限
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "⚠️  需要管理员权限来修改系统PATH" -ForegroundColor Yellow
    Write-Host "请以管理员身份重新运行此脚本" -ForegroundColor Yellow
    exit 1
}

# 检查Node.js
Write-Host "📋 检查系统环境..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "✅ Node.js 已安装: $nodeVersion" -ForegroundColor Green
    } else {
        throw "Node.js not found"
    }
} catch {
    Write-Host "❌ 未找到Node.js，请先安装Node.js" -ForegroundColor Red
    exit 1
}

# 查找现有的Claude安装
Write-Host ""
Write-Host "🔍 查找现有Claude Code安装..." -ForegroundColor Yellow

$claudePaths = @()
$whereResult = where.exe claude 2>$null
if ($whereResult) {
    $claudePaths += $whereResult
}

# 检查常见安装位置
$commonPaths = @(
    "D:\npm-global\claude.cmd",
    "C:\Users\$env:USERNAME\AppData\Roaming\npm\claude.cmd",
    "$env:APPDATA\npm\claude.cmd"
)

foreach ($path in $commonPaths) {
    if (Test-Path $path) {
        $claudePaths += $path
    }
}

if ($claudePaths.Count -eq 0) {
    Write-Host "❌ 未找到Claude Code安装" -ForegroundColor Red
    Write-Host "请先安装Claude Code: npm install -g @anthropic-ai/claude-code" -ForegroundColor Blue
    exit 1
}

Write-Host "✅ 找到Claude安装:" -ForegroundColor Green
$claudePaths | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }

# 安装依赖
Write-Host ""
Write-Host "📦 安装项目依赖..." -ForegroundColor Yellow
try {
    npm install
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 依赖安装成功" -ForegroundColor Green
    } else {
        throw "npm install failed"
    }
} catch {
    Write-Host "❌ 依赖安装失败" -ForegroundColor Red
    exit 1
}

# 构建项目
Write-Host ""
Write-Host "🔨 构建项目..." -ForegroundColor Yellow
try {
    npm run build
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 项目构建成功" -ForegroundColor Green
    } else {
        throw "npm run build failed"
    }
} catch {
    Write-Host "❌ 项目构建失败" -ForegroundColor Red
    exit 1
}

# 获取当前目录
$currentPath = Get-Location

# 创建包装器脚本
Write-Host ""
Write-Host "📝 创建Claude包装器..." -ForegroundColor Yellow

# 备份原始Claude命令
$backupPath = "$currentPath\original-claude-backup"
if (-not (Test-Path $backupPath)) {
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
}

# 创建新的Claude命令脚本
$wrapperScript = @"
@echo off
REM Claude Code 智能包装器
REM 自动处理Pro用户限制

node "$currentPath\dist\claude-wrapper.js" %*
"@

$wrapperPath = "$currentPath\claude.cmd"
$wrapperScript | Out-File -FilePath $wrapperPath -Encoding ASCII

# 获取当前PATH
$currentPATH = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$userPATH = [Environment]::GetEnvironmentVariable("PATH", "User")

# 询问安装方式
Write-Host ""
Write-Host "📋 选择安装方式:" -ForegroundColor Yellow
Write-Host "1. 全局安装 (推荐) - 替换系统PATH中的Claude命令" -ForegroundColor Blue
Write-Host "2. 本地安装 - 仅在当前目录创建别名" -ForegroundColor Blue
Write-Host "3. 用户安装 - 添加到用户PATH（不需要管理员权限）" -ForegroundColor Blue

do {
    $choice = Read-Host "请选择 (1-3)"
} while ($choice -notin @('1', '2', '3'))

switch ($choice) {
    '1' {
        # 全局安装
        Write-Host ""
        Write-Host "🌍 执行全局安装..." -ForegroundColor Yellow
        
        # 将当前目录添加到系统PATH的开头
        if ($currentPATH -notlike "*$currentPath*") {
            $newPATH = "$currentPath;$currentPATH"
            [Environment]::SetEnvironmentVariable("PATH", $newPATH, "Machine")
            Write-Host "✅ 已添加到系统PATH" -ForegroundColor Green
        } else {
            Write-Host "✅ 已在系统PATH中" -ForegroundColor Green
        }
        
        Write-Host "💡 现在 'claude' 命令将使用智能包装器" -ForegroundColor Cyan
    }
    
    '2' {
        # 本地安装
        Write-Host ""
        Write-Host "🏠 执行本地安装..." -ForegroundColor Yellow
        
        $aliasScript = @"
@echo off
REM 使用本地Claude包装器
echo 🤖 使用Claude智能包装器...
node "$currentPath\dist\claude-wrapper.js" %*
"@
        
        $aliasScript | Out-File -FilePath "claude-smart.cmd" -Encoding ASCII
        Write-Host "✅ 本地别名已创建: claude-smart.cmd" -ForegroundColor Green
        Write-Host "💡 使用 'claude-smart' 命令来调用智能包装器" -ForegroundColor Cyan
    }
    
    '3' {
        # 用户安装
        Write-Host ""
        Write-Host "👤 执行用户安装..." -ForegroundColor Yellow
        
        if ($userPATH -notlike "*$currentPath*") {
            $newUserPATH = "$currentPath;$userPATH"
            [Environment]::SetEnvironmentVariable("PATH", $newUserPATH, "User")
            Write-Host "✅ 已添加到用户PATH" -ForegroundColor Green
        } else {
            Write-Host "✅ 已在用户PATH中" -ForegroundColor Green
        }
        
        Write-Host "💡 现在 'claude' 命令将使用智能包装器（重新打开终端后生效）" -ForegroundColor Cyan
    }
}

# 创建管理脚本
Write-Host ""
Write-Host "🛠️ 创建管理脚本..." -ForegroundColor Yellow

# 状态检查脚本
$statusScript = @"
@echo off
echo 📊 Claude Wrapper 状态检查
node "$currentPath\dist\claude-wrapper.js" --status
pause
"@

$statusScript | Out-File -FilePath "检查状态.cmd" -Encoding UTF8

# 卸载脚本
$uninstallScript = @"
@echo off
title Claude Wrapper 卸载程序
echo ⚠️  Claude Wrapper 卸载程序
echo.
echo 这将移除Claude智能包装器并恢复原始Claude命令
echo.
set /p confirm=确认卸载? (y/n): 

if /i "%confirm%"=="y" (
    echo.
    echo 🔄 正在卸载...
    
    REM 从PATH中移除
    echo 从系统PATH移除...
    REM 这里需要PowerShell来修改PATH
    powershell -Command "& { `$path = [Environment]::GetEnvironmentVariable('PATH', 'Machine'); `$newPath = `$path -replace '$currentPath;?', ''; [Environment]::SetEnvironmentVariable('PATH', `$newPath, 'Machine') }"
    
    echo ✅ 卸载完成
    echo 💡 请重新打开终端以使更改生效
) else (
    echo 取消卸载
)

pause
"@

$uninstallScript | Out-File -FilePath "卸载.cmd" -Encoding UTF8

Write-Host "✅ 管理脚本已创建:" -ForegroundColor Green
Write-Host "   - 检查状态.cmd" -ForegroundColor Gray
Write-Host "   - 卸载.cmd" -ForegroundColor Gray

# 完成安装
Write-Host ""
Write-Host "🎉 安装完成！" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

Write-Host "📋 使用说明:" -ForegroundColor Yellow
Write-Host "• 现在直接使用 claude 命令，会自动处理Pro限制" -ForegroundColor Blue
Write-Host "• 遇到限制时会自动等待并在重置时间继续执行" -ForegroundColor Blue
Write-Host "• 使用 'claude --status' 查看当前状态" -ForegroundColor Blue
Write-Host "• 使用 'claude --help' 查看帮助信息" -ForegroundColor Blue
Write-Host ""

Write-Host "💡 示例:" -ForegroundColor Yellow
Write-Host "   claude /build --comprehensive" -ForegroundColor Gray
Write-Host "   claude /implement user-auth --full" -ForegroundColor Gray
Write-Host "   claude /analyze --deep --security" -ForegroundColor Gray
Write-Host ""

Write-Host "📝 特性:" -ForegroundColor Yellow
Write-Host "✅ 自动检测Claude Pro使用限制" -ForegroundColor Green
Write-Host "✅ 智能解析重置时间" -ForegroundColor Green
Write-Host "✅ 自动等待并继续执行" -ForegroundColor Green
Write-Host "✅ 后台状态保持" -ForegroundColor Green
Write-Host "✅ 终端最小化也能正常工作" -ForegroundColor Green
Write-Host ""

# 测试安装
$testNow = Read-Host "是否现在测试安装？(y/n)"
if ($testNow -eq 'y' -or $testNow -eq 'Y') {
    Write-Host ""
    Write-Host "🧪 测试Claude包装器..." -ForegroundColor Yellow
    
    if ($choice -eq '2') {
        & ".\claude-smart.cmd" --help
    } else {
        refreshenv
        Start-Sleep -Seconds 2
        & claude --help
    }
}

Write-Host ""
Write-Host "感谢使用 Claude Code 智能包装器！🚀" -ForegroundColor Green
Write-Host "现在你可以放心地运行长时间任务，即使遇到Pro限制也会自动处理！" -ForegroundColor Cyan