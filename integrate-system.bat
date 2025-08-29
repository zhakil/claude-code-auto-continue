@echo off
chcp 65001 >nul
echo.
echo 🚀 Claude Code Auto-Continue 系统集成
echo ====================================
echo.

REM 获取当前目录
set "WRAPPER_DIR=%~dp0"
set "WRAPPER_DIR=%WRAPPER_DIR:~0,-1%"

echo 📍 包装器目录: %WRAPPER_DIR%
echo.

REM 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ 需要管理员权限来修改系统文件
    echo 请以管理员身份运行此脚本
    pause
    exit /b 1
)

echo ✅ 管理员权限确认
echo.

REM 备份当前的claude.cmd
echo 💾 备份原始Claude命令...
if exist "D:\npm-global\claude.cmd" (
    if not exist "D:\npm-global\claude.cmd.backup" (
        copy "D:\npm-global\claude.cmd" "D:\npm-global\claude.cmd.backup" >nul
        echo ✅ 原始claude.cmd已备份
    ) else (
        echo ℹ️ 备份文件已存在
    )
)

REM 创建新的claude.cmd包装器
echo.
echo 🔧 创建包装器命令...

echo @echo off > "D:\npm-global\claude.cmd"
echo chcp 65001 ^>nul >> "D:\npm-global\claude.cmd"
echo node "%WRAPPER_DIR%\dist\claude-wrapper.js" %%* >> "D:\npm-global\claude.cmd"

if %errorlevel% equ 0 (
    echo ✅ 包装器已集成到系统Claude命令
) else (
    echo ❌ 集成失败
    pause
    exit /b 1
)

REM 创建恢复脚本
echo.
echo 📝 创建恢复脚本...

echo @echo off > "%WRAPPER_DIR%\restore-original.bat"
echo chcp 65001 ^>nul >> "%WRAPPER_DIR%\restore-original.bat"
echo echo 🔄 恢复原始Claude命令 >> "%WRAPPER_DIR%\restore-original.bat"
echo if exist "D:\npm-global\claude.cmd.backup" ^( >> "%WRAPPER_DIR%\restore-original.bat"
echo     copy "D:\npm-global\claude.cmd.backup" "D:\npm-global\claude.cmd" ^>nul >> "%WRAPPER_DIR%\restore-original.bat"
echo     echo ✅ 原始Claude命令已恢复 >> "%WRAPPER_DIR%\restore-original.bat"
echo ^) else ^( >> "%WRAPPER_DIR%\restore-original.bat"
echo     echo ❌ 找不到备份文件 >> "%WRAPPER_DIR%\restore-original.bat"
echo ^) >> "%WRAPPER_DIR%\restore-original.bat"
echo pause >> "%WRAPPER_DIR%\restore-original.bat"

echo ✅ 恢复脚本已创建: restore-original.bat

REM 测试集成
echo.
echo 🧪 测试集成...
claude --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ 集成测试成功
) else (
    echo ❌ 集成测试失败
)

echo.
echo 🎉 系统集成完成！
echo ================
echo.
echo 📋 现在您可以：
echo   claude --help           # 查看包装器帮助
echo   claude --status         # 检查包装器状态  
echo   claude --version        # 查看Claude版本
echo   claude /build --full    # 正常使用，自动处理限制
echo.
echo 💡 特性：
echo   ✅ 自动检测Claude Pro使用限制
echo   ✅ 智能等待到重置时间
echo   ✅ 后台状态保持
echo   ✅ 无缝Claude命令体验
echo.
echo 🔄 恢复原始命令：运行 restore-original.bat
echo.
echo 🚀 享受无中断的Claude Code体验！

pause