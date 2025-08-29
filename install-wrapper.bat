@echo off
REM 安装 Claude Code Auto-Continue 包装器

echo 🚀 Claude Code Auto-Continue 安装程序
echo =====================================

REM 获取当前目录
set WRAPPER_DIR=%~dp0
echo 📍 安装目录: %WRAPPER_DIR%

REM 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ 需要管理员权限来修改系统PATH
    echo 请右键"以管理员身份运行"此文件
    pause
    exit /b 1
)

REM 备份原有的claude.exe (如果存在)
where claude >nul 2>&1
if %errorlevel% equ 0 (
    echo 🔄 发现现有Claude安装，创建别名...
    for /f "tokens=*" %%i in ('where claude') do (
        echo 原Claude路径: %%i
        echo %%i > "%WRAPPER_DIR%original-claude.txt"
    )
)

REM 创建claude.bat在系统目录
copy "%WRAPPER_DIR%claude-wrapper.bat" "C:\Windows\System32\claude.bat"
if %errorlevel% equ 0 (
    echo ✅ 包装器已安装到系统PATH
) else (
    echo ❌ 安装失败
    pause
    exit /b 1
)

echo.
echo 🎉 安装完成！
echo ===============
echo.
echo 📋 使用方法：
echo claude --help    # 显示帮助
echo claude --status  # 检查状态  
echo claude /build --comprehensive  # 正常使用
echo.
echo 💡 功能特性：
echo ✅ 自动检测Claude Pro使用限制
echo ✅ 智能等待并自动继续任务
echo ✅ 支持后台运行
echo ✅ 状态持久化
echo.
echo 🚀 现在可以正常使用claude命令，遇到限制会自动处理！
pause