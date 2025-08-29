@echo off
chcp 65001 >nul
echo 🔄 恢复原始Claude命令
echo ====================

if exist "D:\npm-global\claude.cmd.backup" (
    copy "D:\npm-global\claude.cmd.backup" "D:\npm-global\claude.cmd" >nul
    echo ✅ 原始Claude命令已恢复
    echo ℹ️ 现在claude命令将直接调用原始Claude Code
) else (
    echo ❌ 找不到备份文件
)

echo.
echo 💡 如果要重新启用自动继续功能，请运行:
echo    integrate-system.bat
echo.
pause