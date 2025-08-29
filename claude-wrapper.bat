@echo off
REM Claude Code Auto-Continue Wrapper
REM 自动处理Claude Pro使用限制

set WRAPPER_DIR=%~dp0
node "%WRAPPER_DIR%dist\claude-wrapper.js" %*