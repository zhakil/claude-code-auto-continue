# Claude Code Auto-Continue 一键安装脚本
# 支持全新电脑自动安装和配置

param(
    [switch]$Force,           # 强制重新安装
    [switch]$Local,           # 仅本地安装
    [switch]$Quiet,           # 静默安装
    [string]$InstallDir = ""  # 自定义安装目录
)

$ErrorActionPreference = "Stop"

if (-not $Quiet) {
    Write-Host "🚀 Claude Code Auto-Continue 一键安装程序" -ForegroundColor Green
    Write-Host "=======================================" -ForegroundColor Green
    Write-Host ""
}

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
    $arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
    if ($Force) { $arguments += " -Force" }
    if ($Quiet) { $arguments += " -Quiet" }
    if ($InstallDir) { $arguments += " -InstallDir `"$InstallDir`"" }
    
    Start-Process powershell -Verb RunAs -ArgumentList $arguments -Wait
    exit
}

# 环境检查
Write-Host "📋 检查系统环境..." -ForegroundColor Yellow

# 检查Node.js
try {
    $nodeVersion = & node --version 2>$null
    if ($nodeVersion) {
        Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
    } else {
        throw "Node.js not found"
    }
} catch {
    Write-Host "❌ 未找到Node.js" -ForegroundColor Red
    Write-Host "正在自动安装Node.js..." -ForegroundColor Yellow
    
    try {
        winget install OpenJS.NodeJS --silent --accept-source-agreements --accept-package-agreements
        Write-Host "✅ Node.js 安装完成" -ForegroundColor Green
        
        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } catch {
        Write-Host "❌ Node.js 自动安装失败，请手动安装" -ForegroundColor Red
        exit 1
    }
}

# 检查Git
try {
    $gitVersion = & git --version 2>$null
    if ($gitVersion) {
        Write-Host "✅ Git: $gitVersion" -ForegroundColor Green
    } else {
        throw "Git not found"
    }
} catch {
    Write-Host "⚠️  未找到Git，正在安装..." -ForegroundColor Yellow
    try {
        winget install Git.Git --silent --accept-source-agreements --accept-package-agreements
        Write-Host "✅ Git 安装完成" -ForegroundColor Green
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } catch {
        Write-Host "⚠️  Git 安装失败，继续安装..." -ForegroundColor Yellow
    }
}

# 智能查找Claude Code安装路径
Write-Host ""
Write-Host "🔍 智能查找Claude Code安装..." -ForegroundColor Yellow

$claudePaths = @()

# 方法1: 使用where命令
try {
    $whereResult = & where.exe claude 2>$null
    if ($whereResult) {
        $claudePaths += $whereResult
    }
} catch {}

# 方法2: 检查npm全局模块路径
try {
    $npmRoot = & npm root -g 2>$null
    if ($npmRoot) {
        $claudeNpmPath = Join-Path $npmRoot "@anthropic-ai\claude-code\cli.js"
        if (Test-Path $claudeNpmPath) {
            $claudePaths += $claudeNpmPath
        }
    }
} catch {}

# 方法3: 检查常见安装位置
$commonPaths = @(
    "$env:APPDATA\npm\node_modules\@anthropic-ai\claude-code\cli.js",
    "$env:PROGRAMFILES\nodejs\node_modules\@anthropic-ai\claude-code\cli.js",
    "$env:LOCALAPPDATA\npm\node_modules\@anthropic-ai\claude-code\cli.js",
    "D:\npm-global\node_modules\@anthropic-ai\claude-code\cli.js",
    "C:\npm\node_modules\@anthropic-ai\claude-code\cli.js"
)

foreach ($path in $commonPaths) {
    if (Test-Path $path) {
        $claudePaths += $path
    }
}

# 方法4: 通过包管理器查找
try {
    $npmList = & npm list -g @anthropic-ai/claude-code --depth=0 2>$null
    if ($npmList -match "claude-code@") {
        # 从npm list输出中提取路径
        $globalPath = & npm root -g 2>$null
        if ($globalPath) {
            $claudePath = Join-Path $globalPath "@anthropic-ai\claude-code\cli.js"
            if (Test-Path $claudePath) {
                $claudePaths += $claudePath
            }
        }
    }
} catch {}

if ($claudePaths.Count -eq 0) {
    Write-Host "❌ 未找到Claude Code安装" -ForegroundColor Red
    Write-Host "正在自动安装Claude Code..." -ForegroundColor Yellow
    
    try {
        & npm install -g @anthropic-ai/claude-code
        Write-Host "✅ Claude Code 安装完成" -ForegroundColor Green
        
        # 重新查找
        $npmRoot = & npm root -g 2>$null
        if ($npmRoot) {
            $claudeNpmPath = Join-Path $npmRoot "@anthropic-ai\claude-code\cli.js"
            if (Test-Path $claudeNpmPath) {
                $claudePaths += $claudeNpmPath
            }
        }
    } catch {
        Write-Host "❌ Claude Code 自动安装失败" -ForegroundColor Red
        Write-Host "请手动运行: npm install -g @anthropic-ai/claude-code" -ForegroundColor Blue
        exit 1
    }
}

if ($claudePaths.Count -eq 0) {
    Write-Host "❌ 仍未找到Claude Code，安装失败" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 找到Claude Code:" -ForegroundColor Green
$claudePaths | Select-Object -Unique | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }

# 确定安装目录
if ($InstallDir -eq "") {
    $InstallDir = if ($Local) { $PWD.Path } else { "$env:USERPROFILE\.claude-auto-continue" }
}

Write-Host ""
Write-Host "📦 准备安装到: $InstallDir" -ForegroundColor Yellow

# 创建安装目录
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# 下载或复制项目文件
Write-Host ""
Write-Host "⬇️ 获取项目文件..." -ForegroundColor Yellow

$sourceFiles = @{
    "package.json" = @"
{
  "name": "claude-code-auto-continue",
  "version": "1.0.0",
  "description": "Claude Code自动处理Pro用户限制的智能包装器",
  "main": "dist/claude-wrapper.js",
  "type": "module",
  "bin": {
    "claude": "dist/claude-wrapper.js"
  },
  "scripts": {
    "build": "tsc",
    "start": "node dist/claude-wrapper.js",
    "install-wrapper": "node scripts/install.js",
    "uninstall-wrapper": "node scripts/uninstall.js"
  },
  "keywords": [
    "claude-code",
    "wrapper",
    "auto-continue",
    "pro-limits"
  ],
  "author": "Claude",
  "license": "MIT",
  "dependencies": {
    "winston": "^3.11.0",
    "chalk": "^5.3.0"
  },
  "devDependencies": {
    "@types/node": "^20.10.0",
    "typescript": "^5.3.0"
  }
}
"@

    "tsconfig.json" = @"
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "node",
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "declaration": false,
    "sourceMap": false
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
"@
}

# 创建必要的目录结构
@("src", "dist", "scripts") | ForEach-Object {
    $dir = Join-Path $InstallDir $_
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# 写入配置文件
foreach ($file in $sourceFiles.GetEnumerator()) {
    $filePath = Join-Path $InstallDir $file.Key
    $file.Value | Out-File -FilePath $filePath -Encoding UTF8
}

# 创建智能包装器源码
$wrapperSource = @"
#!/usr/bin/env node

import { spawn } from 'child_process';
import { writeFileSync, readFileSync, existsSync } from 'fs';
import { join } from 'path';
import winston from 'winston';
import chalk from 'chalk';

// 配置日志
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.printf(({ timestamp, level, message }) => {
      return `${'$'}{timestamp} [${'$'}{level.toUpperCase()}] ${'$'}{message}`;
    })
  ),
  transports: [
    new winston.transports.File({ 
      filename: join(process.cwd(), '.claude-wrapper.log'),
      maxsize: 2 * 1024 * 1024,
      maxFiles: 2
    })
  ]
});

interface WrapperState {
  isWaiting: boolean;
  originalCommand: string[];
  resetTime: Date | null;
  retryCount: number;
  maxRetries: number;
}

class ClaudeWrapper {
  private stateFile: string;
  private originalClaudePath: string;

  constructor() {
    this.stateFile = join(process.cwd(), '.claude-wrapper-state.json');
    this.originalClaudePath = this.findOriginalClaude();
  }

  /**
   * 智能查找原始Claude可执行文件
   */
  private findOriginalClaude(): string {
    const { execSync } = require('child_process');
    
    // 方法1: 查找npm全局安装路径
    try {
      const npmRoot = execSync('npm root -g', { encoding: 'utf8' }).trim();
      const claudePath = join(npmRoot, '@anthropic-ai', 'claude-code', 'cli.js');
      if (existsSync(claudePath)) {
        return claudePath;
      }
    } catch {}

    // 方法2: 检查常见路径
    const possiblePaths = [
      process.env.APPDATA ? join(process.env.APPDATA, 'npm', 'node_modules', '@anthropic-ai', 'claude-code', 'cli.js') : '',
      process.env.LOCALAPPDATA ? join(process.env.LOCALAPPDATA, 'npm', 'node_modules', '@anthropic-ai', 'claude-code', 'cli.js') : '',
      'D:\\\\npm-global\\\\node_modules\\\\@anthropic-ai\\\\claude-code\\\\cli.js',
      'C:\\\\npm\\\\node_modules\\\\@anthropic-ai\\\\claude-code\\\\cli.js'
    ].filter(p => p && existsSync(p));

    if (possiblePaths.length > 0) {
      return possiblePaths[0];
    }

    // 方法3: 使用系统claude命令
    return 'claude';
  }

  /**
   * 主执行函数
   */
  async run(args: string[]): Promise<void> {
    // 检查是否有等待中的任务
    const state = this.loadState();
    if (state.isWaiting && state.resetTime) {
      const now = new Date();
      if (now >= state.resetTime) {
        console.log(chalk.green('⏰ 等待时间到达，继续执行上次的任务...'));
        await this.executeClaude(state.originalCommand);
        this.clearState();
        return;
      } else {
        const waitTime = state.resetTime.getTime() - now.getTime();
        const minutes = Math.ceil(waitTime / (1000 * 60));
        console.log(chalk.yellow(`⏳ 还需要等待 ${'$'}{minutes} 分钟才能继续执行任务`));
        console.log(chalk.gray(`重置时间: ${'$'}{state.resetTime.toLocaleString()}`));
        return;
      }
    }

    // 执行新的Claude命令
    await this.executeClaude(args);
  }

  /**
   * 执行Claude命令
   */
  private async executeClaude(args: string[]): Promise<void> {
    logger.info(`执行Claude命令: ${'$'}{args.join(' ')}`);
    
    return new Promise<void>((resolve, reject) => {
      const child = spawn('node', [this.originalClaudePath, ...args], {
        stdio: 'pipe',
        cwd: process.cwd(),
        env: process.env
      });

      let outputBuffer = '';
      let hasDetectedLimit = false;

      // 处理标准输出
      child.stdout?.on('data', (data) => {
        const text = data.toString();
        outputBuffer += text;
        
        // 实时显示输出
        process.stdout.write(text);
        
        // 检测限制信息
        if (!hasDetectedLimit && this.detectLimit(text)) {
          hasDetectedLimit = true;
          const resetTime = this.extractResetTime(outputBuffer);
          
          if (resetTime) {
            logger.info(`检测到限制，重置时间: ${'$'}{resetTime.toLocaleString()}`);
            this.saveWaitingState(args, resetTime);
            
            // 终止当前进程
            child.kill('SIGTERM');
            
            // 显示等待信息
            this.showWaitingMessage(resetTime);
            
            // 设置自动恢复
            this.scheduleAutoResume(args, resetTime);
            
            resolve();
            return;
          }
        }
      });

      // 处理标准错误
      child.stderr?.on('data', (data) => {
        const text = data.toString();
        process.stderr.write(text);
        logger.error(`Claude错误输出: ${'$'}{text.trim()}`);
      });

      // 处理进程结束
      child.on('close', (code) => {
        if (code === 0) {
          logger.info('Claude命令执行成功');
          this.clearState();
        } else if (!hasDetectedLimit) {
          logger.error(`Claude命令执行失败，退出代码: ${'$'}{code}`);
        }
        resolve();
      });

      child.on('error', (error) => {
        logger.error(`执行Claude命令时出错: ${'$'}{error.message}`);
        reject(error);
      });
    });
  }

  /**
   * 检测是否遇到限制
   */
  private detectLimit(output: string): boolean {
    const limitPatterns = [
      /limit reset at/i,
      /rate limit/i,
      /too many requests/i,
      /quota exceeded/i,
      /limit reached/i,
      /usage limit/i,
      /pro.*limit/i
    ];

    return limitPatterns.some(pattern => pattern.test(output));
  }

  /**
   * 从输出中提取重置时间
   */
  private extractResetTime(output: string): Date | null {
    // 匹配各种时间格式
    const patterns = [
      /(?:limit\\s+)?reset\\s+at\\s+(\\d{1,2}):(\\d{2})(?:\\s*(AM|PM))?/i,
      /(?:limit\\s+)?reset\\s+in\\s+(\\d+)\\s*(?:minute|min)s?/i,
      /(?:limit\\s+)?reset\\s+in\\s+(\\d+)\\s*(?:hour|hr)s?\\s*(?:(?:and\\s+)?(\\d+)\\s*(?:minute|min)s?)?/i,
      /try\\s+again\\s+at\\s+(\\d{1,2}):(\\d{2})(?:\\s*(AM|PM))?/i
    ];

    for (const pattern of patterns) {
      const match = output.match(pattern);
      if (match) {
        return this.parseTimeMatch(match);
      }
    }

    // 默认1小时后重试
    const defaultTime = new Date();
    defaultTime.setHours(defaultTime.getHours() + 1);
    logger.warn('未能解析重置时间，使用默认1小时后重试');
    return defaultTime;
  }

  /**
   * 解析时间匹配结果
   */
  private parseTimeMatch(match: RegExpMatchArray): Date | null {
    const now = new Date();
    
    // 格式1: HH:MM [AM/PM]
    if (match[1] && match[2]) {
      const hours = parseInt(match[1]);
      const minutes = parseInt(match[2]);
      const ampm = match[3];
      
      const resetTime = new Date(now);
      let adjustedHours = hours;
      
      if (ampm) {
        if (ampm.toUpperCase() === 'PM' && hours !== 12) {
          adjustedHours += 12;
        } else if (ampm.toUpperCase() === 'AM' && hours === 12) {
          adjustedHours = 0;
        }
      }
      
      resetTime.setHours(adjustedHours, minutes, 0, 0);
      
      // 如果时间已过，设为明天
      if (resetTime <= now) {
        resetTime.setDate(resetTime.getDate() + 1);
      }
      
      return resetTime;
    }
    
    // 格式2: 相对时间（分钟）
    if (match[1] && !match[2]) {
      const minutes = parseInt(match[1]);
      const resetTime = new Date(now);
      resetTime.setMinutes(resetTime.getMinutes() + minutes);
      return resetTime;
    }
    
    return null;
  }

  /**
   * 显示等待消息
   */
  private showWaitingMessage(resetTime: Date): void {
    const now = new Date();
    const waitTime = resetTime.getTime() - now.getTime();
    const hours = Math.floor(waitTime / (1000 * 60 * 60));
    const minutes = Math.floor((waitTime % (1000 * 60 * 60)) / (1000 * 60));
    
    console.log('');
    console.log(chalk.yellow('⚠️  检测到Claude Pro使用限制'));
    console.log(chalk.blue(`⏰ 重置时间: ${'$'}{resetTime.toLocaleString()}`));
    console.log(chalk.green(`⏳ 等待时间: ${'$'}{hours}小时${'$'}{minutes}分钟`));
    console.log(chalk.cyan('🤖 任务将在重置时间到达后自动继续'));
    console.log(chalk.gray('💡 你现在可以关闭终端，系统会在后台等待'));
    console.log('');
  }

  /**
   * 设置自动恢复
   */
  private scheduleAutoResume(args: string[], resetTime: Date): void {
    const now = new Date();
    const waitTime = resetTime.getTime() - now.getTime();
    
    if (waitTime > 0) {
      logger.info(`设置自动恢复定时器: ${'$'}{waitTime}ms`);
      
      setTimeout(async () => {
        console.log(chalk.green('🔔 限制时间已重置，自动恢复执行...'));
        logger.info('自动恢复执行Claude命令');
        
        try {
          await this.executeClaude(args);
          this.clearState();
        } catch (error) {
          logger.error(`自动恢复执行失败: ${'$'}{error}`);
          console.error(chalk.red('❌ 自动恢复执行失败，请手动重试'));
        }
      }, waitTime);
    }
  }

  /**
   * 保存等待状态
   */
  private saveWaitingState(command: string[], resetTime: Date): void {
    const state: WrapperState = {
      isWaiting: true,
      originalCommand: command,
      resetTime,
      retryCount: 0,
      maxRetries: 3
    };
    
    try {
      writeFileSync(this.stateFile, JSON.stringify(state, null, 2));
      logger.info('等待状态已保存');
    } catch (error) {
      logger.error(`保存状态失败: ${'$'}{error}`);
    }
  }

  /**
   * 加载状态
   */
  private loadState(): WrapperState {
    try {
      if (existsSync(this.stateFile)) {
        const data = readFileSync(this.stateFile, 'utf-8');
        const parsed = JSON.parse(data);
        
        // 转换日期字符串为Date对象
        if (parsed.resetTime) {
          parsed.resetTime = new Date(parsed.resetTime);
        }
        
        return parsed;
      }
    } catch (error) {
      logger.error(`加载状态失败: ${'$'}{error}`);
    }
    
    return {
      isWaiting: false,
      originalCommand: [],
      resetTime: null,
      retryCount: 0,
      maxRetries: 3
    };
  }

  /**
   * 清除状态
   */
  private clearState(): void {
    try {
      if (existsSync(this.stateFile)) {
        const fs = require('fs');
        fs.unlinkSync(this.stateFile);
        logger.info('状态已清除');
      }
    } catch (error) {
      logger.error(`清除状态失败: ${'$'}{error}`);
    }
  }

  /**
   * 获取当前状态
   */
  getStatus(): { isWaiting: boolean; resetTime: Date | null; command: string[] } {
    const state = this.loadState();
    return {
      isWaiting: state.isWaiting,
      resetTime: state.resetTime,
      command: state.originalCommand
    };
  }
}

// 主程序入口
async function main() {
  const wrapper = new ClaudeWrapper();
  const args = process.argv.slice(2);

  // 处理特殊命令
  if (args[0] === '--status') {
    const status = wrapper.getStatus();
    console.log('📊 Claude Wrapper 状态:');
    console.log(`🔄 等待状态: ${'$'}{status.isWaiting ? '等待中' : '空闲'}`);
    if (status.isWaiting && status.resetTime) {
      console.log(`⏰ 重置时间: ${'$'}{status.resetTime.toLocaleString()}`);
      console.log(`📝 原始命令: claude ${'$'}{status.command.join(' ')}`);
    }
    return;
  }

  if (args[0] === '--help' || args[0] === '-h') {
    console.log('Claude Code 智能包装器');
    console.log('');
    console.log('用法:');
    console.log('  claude [Claude Code参数]    执行Claude命令');
    console.log('  claude --status             显示当前状态');
    console.log('  claude --help               显示此帮助信息');
    console.log('');
    console.log('功能:');
    console.log('  • 自动检测Claude Pro使用限制');
    console.log('  • 智能等待到重置时间');
    console.log('  • 自动恢复执行任务');
    console.log('  • 后台状态保持');
    console.log('');
    return;
  }

  try {
    await wrapper.run(args);
  } catch (error) {
    logger.error(`Wrapper执行失败: ${'$'}{error}`);
    console.error(chalk.red('❌ 执行失败，请查看日志文件: .claude-wrapper.log'));
    process.exit(1);
  }
}

// 处理进程信号
process.on('SIGINT', () => {
  console.log(chalk.yellow('\\n🔄 正在保存状态并退出...'));
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log(chalk.yellow('\\n🔄 正在保存状态并退出...'));
  process.exit(0);
});

// 未捕获异常处理
process.on('unhandledRejection', (reason, promise) => {
  logger.error(`未处理的Promise拒绝: ${'$'}{reason}`);
  console.error(chalk.red('❌ 程序异常，详情请查看日志'));
});

// 启动主程序
if (import.meta.url === `file://${'$'}{process.argv[1]}`) {
  main().catch((error) => {
    logger.error(`主程序异常: ${'$'}{error}`);
    process.exit(1);
  });
}
"@

$wrapperPath = Join-Path $InstallDir "src\claude-wrapper.ts"
$wrapperSource | Out-File -FilePath $wrapperPath -Encoding UTF8

Write-Host "✅ 项目文件创建完成" -ForegroundColor Green

# 安装依赖
Write-Host ""
Write-Host "📦 安装依赖..." -ForegroundColor Yellow
Push-Location $InstallDir
try {
    & npm install
    Write-Host "✅ 依赖安装成功" -ForegroundColor Green
} catch {
    Write-Host "❌ 依赖安装失败" -ForegroundColor Red
    Pop-Location
    exit 1
}

# 构建项目
Write-Host ""
Write-Host "🔨 构建项目..." -ForegroundColor Yellow
try {
    & npm run build
    Write-Host "✅ 项目构建成功" -ForegroundColor Green
} catch {
    Write-Host "❌ 项目构建失败" -ForegroundColor Red
    Pop-Location
    exit 1
}

# 配置PATH
if (-not $Local) {
    Write-Host ""
    Write-Host "🔧 配置系统PATH..." -ForegroundColor Yellow
    
    $currentPATH = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    if ($currentPATH -notlike "*$InstallDir*") {
        $newPATH = "$InstallDir;$currentPATH"
        [Environment]::SetEnvironmentVariable("PATH", $newPATH, "User")
        Write-Host "✅ PATH配置完成" -ForegroundColor Green
        
        # 刷新当前会话的PATH
        $env:Path = $newPATH
    } else {
        Write-Host "✅ PATH已配置" -ForegroundColor Green
    }
    
    # 创建claude命令
    $claudeCmd = @"
@echo off
node "$InstallDir\dist\claude-wrapper.js" %*
"@
    $claudeCmdPath = Join-Path $InstallDir "claude.cmd"
    $claudeCmd | Out-File -FilePath $claudeCmdPath -Encoding ASCII
    
    Write-Host "✅ claude命令已创建" -ForegroundColor Green
}

Pop-Location

# 创建便捷脚本
$statusScript = @"
@echo off
echo 📊 Claude Wrapper 状态检查
node "$InstallDir\dist\claude-wrapper.js" --status
pause
"@

$statusScriptPath = Join-Path $InstallDir "check-status.cmd"
$statusScript | Out-File -FilePath $statusScriptPath -Encoding UTF8

Write-Host ""
Write-Host "🎉 安装完成！" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host ""

if ($Local) {
    Write-Host "📋 本地安装完成，使用方法：" -ForegroundColor Yellow
    Write-Host "cd `"$InstallDir`"" -ForegroundColor Gray
    Write-Host ".\claude.cmd --help" -ForegroundColor Gray
} else {
    Write-Host "📋 全局安装完成，使用方法：" -ForegroundColor Yellow
    Write-Host "claude --help  # 显示帮助" -ForegroundColor Gray
    Write-Host "claude --status  # 检查状态" -ForegroundColor Gray
    Write-Host "claude /build --comprehensive  # 正常使用" -ForegroundColor Gray
}

Write-Host ""
Write-Host "💡 特性：" -ForegroundColor Yellow
Write-Host "✅ 自动检测Claude Pro使用限制" -ForegroundColor Green
Write-Host "✅ 智能等待并自动继续任务" -ForegroundColor Green
Write-Host "✅ 支持终端最小化运行" -ForegroundColor Green
Write-Host "✅ 状态持久化" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 现在可以正常使用claude命令，遇到限制会自动处理！" -ForegroundColor Cyan