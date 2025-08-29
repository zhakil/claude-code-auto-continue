@echo off
chcp 65001 >nul
echo.
echo 🚀 Claude Code Auto-Continue 完整功能安装程序
echo =============================================
echo.

REM 获取当前目录
set "INSTALL_DIR=%~dp0"
set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"

echo 📍 安装目录: %INSTALL_DIR%
echo.

REM 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ 检测到需要管理员权限来修改系统PATH
    echo 正在以管理员身份重新启动安装程序...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b 0
)

echo ✅ 管理员权限确认
echo.

REM 检查Node.js
echo 📋 检查系统环境...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 未找到Node.js，请先安装Node.js
    echo 下载地址: https://nodejs.org/
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
echo ✅ Node.js: %NODE_VERSION%

REM 检查Claude Code
echo.
echo 🔍 智能查找Claude Code安装...

REM 尝试多种方法查找Claude
set "CLAUDE_FOUND="
set "CLAUDE_PATH="

REM 方法1: where命令
for /f "tokens=*" %%i in ('where claude 2^>nul') do (
    set "CLAUDE_PATH=%%i"
    set "CLAUDE_FOUND=1"
    goto found_claude
)

REM 方法2: npm全局路径
for /f "tokens=*" %%i in ('npm root -g 2^>nul') do (
    set "NPM_ROOT=%%i"
    if exist "%%i\@anthropic-ai\claude-code\cli.js" (
        set "CLAUDE_PATH=%%i\@anthropic-ai\claude-code\cli.js"
        set "CLAUDE_FOUND=1"
        goto found_claude
    )
)

REM 方法3: 常见路径检查
set "POSSIBLE_PATHS="
set "POSSIBLE_PATHS=%POSSIBLE_PATHS%"%APPDATA%\npm\node_modules\@anthropic-ai\claude-code\cli.js" "
set "POSSIBLE_PATHS=%POSSIBLE_PATHS%"%LOCALAPPDATA%\npm\node_modules\@anthropic-ai\claude-code\cli.js" "
set "POSSIBLE_PATHS=%POSSIBLE_PATHS%"D:\npm-global\node_modules\@anthropic-ai\claude-code\cli.js" "
set "POSSIBLE_PATHS=%POSSIBLE_PATHS%"C:\npm\node_modules\@anthropic-ai\claude-code\cli.js" "

for %%p in (%POSSIBLE_PATHS%) do (
    if exist %%p (
        set "CLAUDE_PATH=%%~p"
        set "CLAUDE_FOUND=1"
        goto found_claude
    )
)

:found_claude
if not defined CLAUDE_FOUND (
    echo ❌ 未找到Claude Code安装
    echo 正在自动安装Claude Code...
    npm install -g @anthropic-ai/claude-code
    if %errorlevel% neq 0 (
        echo ❌ Claude Code自动安装失败
        echo 请手动运行: npm install -g @anthropic-ai/claude-code
        pause
        exit /b 1
    )
    
    REM 重新查找
    for /f "tokens=*" %%i in ('npm root -g 2^>nul') do (
        if exist "%%i\@anthropic-ai\claude-code\cli.js" (
            set "CLAUDE_PATH=%%i\@anthropic-ai\claude-code\cli.js"
            set "CLAUDE_FOUND=1"
        )
    )
    
    if not defined CLAUDE_FOUND (
        echo ❌ 安装后仍未找到Claude Code
        pause
        exit /b 1
    )
)

echo ✅ 找到Claude Code: %CLAUDE_PATH%
echo.

REM 安装依赖
echo 📦 安装项目依赖...
pushd "%INSTALL_DIR%"
call npm install
if %errorlevel% neq 0 (
    echo ❌ 依赖安装失败
    pause
    popd
    exit /b 1
)
echo ✅ 依赖安装成功

REM 构建项目
echo.
echo 🔨 构建TypeScript项目...
call npm run build
if %errorlevel% neq 0 (
    echo ❌ 项目构建失败
    pause
    popd
    exit /b 1
)
echo ✅ 项目构建成功

REM 创建包装器批处理文件
echo.
echo 🔧 创建系统集成...

REM 创建claude.bat
set "CLAUDE_BAT=%INSTALL_DIR%\claude.bat"
echo @echo off > "%CLAUDE_BAT%"
echo chcp 65001 ^>nul >> "%CLAUDE_BAT%"
echo node "%INSTALL_DIR%\dist\claude-wrapper.js" %%* >> "%CLAUDE_BAT%"

REM 备份现有claude命令(如果存在)
if exist "C:\Windows\System32\claude.bat" (
    echo 🔄 备份现有claude命令...
    copy "C:\Windows\System32\claude.bat" "C:\Windows\System32\claude.bat.backup" >nul
)

REM 安装到系统目录
copy "%CLAUDE_BAT%" "C:\Windows\System32\claude.bat" >nul
if %errorlevel% equ 0 (
    echo ✅ 包装器已安装到系统PATH
) else (
    echo ❌ 系统目录安装失败，尝试用户PATH...
    
    REM 添加到用户PATH
    for /f "usebackq tokens=2*" %%A in (`reg query "HKCU\Environment" /v PATH 2^>nul`) do set "USER_PATH=%%B"
    if not defined USER_PATH set "USER_PATH="
    
    echo %USER_PATH% | find /i "%INSTALL_DIR%" >nul
    if %errorlevel% neq 0 (
        if defined USER_PATH (
            set "NEW_PATH=%INSTALL_DIR%;%USER_PATH%"
        ) else (
            set "NEW_PATH=%INSTALL_DIR%"
        )
        reg add "HKCU\Environment" /v PATH /d "!NEW_PATH!" /f >nul
        echo ✅ 已添加到用户PATH，重启终端后生效
    ) else (
        echo ✅ 目录已在PATH中
    )
)

REM 创建快捷测试脚本
echo.
echo 📝 创建便捷工具...

echo @echo off > "%INSTALL_DIR%\status.bat"
echo chcp 65001 ^>nul >> "%INSTALL_DIR%\status.bat"
echo echo 📊 Claude Wrapper 状态检查 >> "%INSTALL_DIR%\status.bat"
echo echo ========================== >> "%INSTALL_DIR%\status.bat"
echo node "%INSTALL_DIR%\dist\claude-wrapper.js" --status >> "%INSTALL_DIR%\status.bat"
echo pause >> "%INSTALL_DIR%\status.bat"

echo @echo off > "%INSTALL_DIR%\test.bat"
echo chcp 65001 ^>nul >> "%INSTALL_DIR%\test.bat"
echo echo 🧪 Claude Wrapper 测试 >> "%INSTALL_DIR%\test.bat"
echo echo ================== >> "%INSTALL_DIR%\test.bat"
echo node "%INSTALL_DIR%\dist\claude-wrapper.js" --help >> "%INSTALL_DIR%\test.bat"
echo echo. >> "%INSTALL_DIR%\test.bat"
echo echo ✅ 如果看到帮助信息，说明安装成功！ >> "%INSTALL_DIR%\test.bat"
echo pause >> "%INSTALL_DIR%\test.bat"

popd

echo.
echo 🎉 安装完成！
echo =============
echo.
echo 📋 使用方法：
echo   claude --help           # 显示帮助信息
echo   claude --status         # 检查包装器状态
echo   claude /build --full    # 正常使用Claude命令
echo   claude /analyze --deep  # 深度分析
echo.
echo 💡 核心功能：
echo   ✅ 自动检测Claude Pro使用限制（支持多种语言）
echo   ✅ 智能时间解析（支持相对/绝对时间格式）
echo   ✅ 无人值守等待（后台定时器）
echo   ✅ 状态持久化（重启后自动恢复）
echo   ✅ 完整日志记录（.claude-wrapper.log）
echo   ✅ 智能重试机制（指数退避）
echo.
echo 🔧 便捷工具：
echo   status.bat    # 快速检查状态
echo   test.bat      # 测试安装
echo.
echo 📁 重要文件：
echo   .claude-wrapper-state.json    # 等待状态文件
echo   .claude-wrapper.log           # 详细日志文件
echo.
echo 🚀 现在可以正常使用claude命令，遇到限制会自动处理！
echo 💡 终端可以最小化，系统会在后台等待并自动恢复任务
echo.

pause