#!/usr/bin/env node

import { spawn, execSync } from 'child_process';
import { writeFileSync, readFileSync, existsSync, unlinkSync } from 'fs';
import { join } from 'path';
import winston from 'winston';
import chalk from 'chalk';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);

// 配置日志
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.printf(({ timestamp, level, message }) => {
      return `${timestamp} [${level.toUpperCase()}] ${message}`;
    })
  ),
  transports: [
    new winston.transports.File({ 
      filename: join(process.cwd(), '.claude-wrapper.log'),
      maxsize: 2 * 1024 * 1024, // 2MB
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
    
    // 找到原始的Claude可执行文件
    this.originalClaudePath = this.findOriginalClaude();
  }

  /**
   * 智能查找原始Claude可执行文件
   */
  private findOriginalClaude(): string {
    
    try {
      // 方法1: 直接使用备份的Claude命令（避免循环调用）
      const backupPath = 'D:\\npm-global\\claude.cmd.backup';
      if (existsSync(backupPath)) {
        logger.info(`使用备份的Claude CMD: ${backupPath}`);
        return backupPath;
      }
    } catch (error) {
      logger.warn('备份文件不存在，尝试其他方法');
    }

    try {
      // 方法2: 查找npm全局安装路径
      const npmRoot = execSync('npm root -g', { encoding: 'utf8', stdio: 'pipe' }).trim();
      const claudePath = join(npmRoot, '@anthropic-ai', 'claude-code', 'cli.js');
      if (existsSync(claudePath)) {
        logger.info(`找到npm全局Claude路径: ${claudePath}`);
        return claudePath;
      }
    } catch (error) {
      logger.warn('npm root -g命令执行失败');
    }

    // 方法3: 检查常见路径
    const possiblePaths = [
      process.env.APPDATA ? join(process.env.APPDATA, 'npm', 'node_modules', '@anthropic-ai', 'claude-code', 'cli.js') : '',
      process.env.LOCALAPPDATA ? join(process.env.LOCALAPPDATA, 'npm', 'node_modules', '@anthropic-ai', 'claude-code', 'cli.js') : '',
      'D:\\npm-global\\node_modules\\@anthropic-ai\\claude-code\\cli.js',
      'C:\\npm\\node_modules\\@anthropic-ai\\claude-code\\cli.js',
      join(process.env.PROGRAMFILES || 'C:\\Program Files', 'nodejs', 'node_modules', '@anthropic-ai', 'claude-code', 'cli.js')
    ].filter(p => p && existsSync(p));

    if (possiblePaths.length > 0) {
      logger.info(`找到Claude路径: ${possiblePaths[0]}`);
      return possiblePaths[0];
    }

    // 方法4: 使用npm list检查
    try {
      const npmList = execSync('npm list -g @anthropic-ai/claude-code --depth=0', { encoding: 'utf8', stdio: 'pipe' });
      if (npmList.includes('claude-code@')) {
        const globalPath = execSync('npm root -g', { encoding: 'utf8', stdio: 'pipe' }).trim();
        const claudePath = join(globalPath, '@anthropic-ai', 'claude-code', 'cli.js');
        if (existsSync(claudePath)) {
          logger.info(`通过npm list找到Claude路径: ${claudePath}`);
          return claudePath;
        }
      }
    } catch (error) {
      logger.warn('npm list命令执行失败');
    }

    // 如果都找不到，返回默认命令
    logger.warn('未找到Claude安装路径，使用默认claude命令');
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
        console.log(chalk.yellow(`⏳ 还需要等待 ${minutes} 分钟才能继续执行任务`));
        console.log(chalk.gray(`重置时间: ${state.resetTime.toLocaleString()}`));
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
    logger.info(`执行Claude命令: ${args.join(' ')}`);
    logger.info(`使用Claude路径: ${this.originalClaudePath}`);
    
    return new Promise<void>((resolve, reject) => {
      let child;
      
      // 如果路径是.js文件，用node执行；否则直接执行
      if (this.originalClaudePath.endsWith('.js')) {
        child = spawn('node', [this.originalClaudePath, ...args], {
          stdio: 'pipe',
          cwd: process.cwd(),
          env: process.env
        });
      } else {
        // 直接执行.cmd或其他可执行文件，使用shell模式处理.cmd
        child = spawn(this.originalClaudePath, args, {
          stdio: 'pipe',
          cwd: process.cwd(),
          env: process.env,
          shell: true
        });
      }

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
            logger.info(`检测到限制，重置时间: ${resetTime.toLocaleString()}`);
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
        logger.error(`Claude错误输出: ${text.trim()}`);
      });

      // 处理进程结束
      child.on('close', (code) => {
        if (code === 0) {
          logger.info('Claude命令执行成功');
          this.clearState();
        } else if (!hasDetectedLimit) {
          logger.error(`Claude命令执行失败，退出代码: ${code}`);
        }
        resolve();
      });

      child.on('error', (error) => {
        logger.error(`执行Claude命令时出错: ${error.message}`);
        reject(error);
      });
    });
  }

  /**
   * 检测是否遇到限制
   */
  private detectLimit(output: string): boolean {
    const limitPatterns = [
      // Claude Pro 特定限制
      /limit reset at/i,
      /usage limit.*reset/i,
      /you.*reached.*limit/i,
      /pro.*limit.*reached/i,
      /limit.*will.*reset/i,
      
      // 通用速率限制
      /rate limit/i,
      /rate.limit.exceeded/i,
      /too many requests/i,
      /quota exceeded/i,
      /limit reached/i,
      /usage limit/i,
      /api.*limit/i,
      
      // HTTP错误代码
      /429.*too many requests/i,
      /503.*service unavailable/i,
      
      // Anthropic 特定消息
      /please.*try.*again.*later/i,
      /temporarily.*unavailable/i,
      /usage.*quota.*exceeded/i,
      
      // 中文限制消息
      /使用限制/,
      /请稍后再试/,
      /配额已用完/,
      /限制.*重置/
    ];

    return limitPatterns.some(pattern => pattern.test(output));
  }

  /**
   * 从输出中提取重置时间
   */
  private extractResetTime(output: string): Date | null {
    logger.info(`尝试从输出中解析重置时间: ${output.substring(0, 500)}...`);
    
    // 匹配各种时间格式
    const patterns = [
      // 绝对时间格式
      /(?:limit\s+|usage\s+)?(?:reset|available)\s+at\s+(\d{1,2}):(\d{2})(?:\s*(AM|PM))?/i,
      /try\s+again\s+(?:at\s+)?(\d{1,2}):(\d{2})(?:\s*(AM|PM))?/i,
      /available\s+at\s+(\d{1,2}):(\d{2})(?:\s*(AM|PM))?/i,
      /reset\s+(?:time|at)\s*:?\s*(\d{1,2}):(\d{2})(?:\s*(AM|PM))?/i,
      
      // 相对时间格式 - 分钟
      /(?:limit\s+)?reset\s+in\s+(\d+)\s*(?:minute|min)s?/i,
      /try\s+(?:again\s+)?in\s+(\d+)\s*(?:minute|min)s?/i,
      /available\s+in\s+(\d+)\s*(?:minute|min)s?/i,
      /wait\s+(\d+)\s*(?:minute|min)s?/i,
      
      // 相对时间格式 - 小时和分钟
      /(?:limit\s+)?reset\s+in\s+(\d+)\s*(?:hour|hr)s?\s*(?:(?:and\s+)?(\d+)\s*(?:minute|min)s?)?/i,
      /try\s+(?:again\s+)?in\s+(\d+)\s*(?:hour|hr)s?\s*(?:(?:and\s+)?(\d+)\s*(?:minute|min)s?)?/i,
      /available\s+in\s+(\d+)\s*(?:hour|hr)s?\s*(?:(?:and\s+)?(\d+)\s*(?:minute|min)s?)?/i,
      
      // 数字后跟单位
      /(\d+)\s*(?:hour|hr)s?\s*(?:(?:and\s+)?(\d+)\s*(?:minute|min)s?)?/i,
      /(\d+)\s*(?:minute|min)s?/i,
      
      // 中文时间格式
      /(\d+)\s*小时\s*(\d+)?\s*分钟?/,
      /(\d+)\s*分钟/,
      /(\d+):(\d+)\s*(?:上午|下午)?/,
      /重置时间.*?(\d{1,2}):(\d{2})/,
      
      // ISO时间格式
      /(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})/,
      /(\d{2}:\d{2}:\d{2})/
    ];

    for (let i = 0; i < patterns.length; i++) {
      const pattern = patterns[i];
      const match = output.match(pattern);
      if (match) {
        logger.info(`匹配到模式 ${i}: ${match[0]}`);
        const result = this.parseTimeMatch(match, i);
        if (result) {
          logger.info(`解析成功，重置时间: ${result.toLocaleString()}`);
          return result;
        }
      }
    }

    // 默认等待时间策略
    const defaultWaitMinutes = this.getDefaultWaitTime();
    const defaultTime = new Date();
    defaultTime.setMinutes(defaultTime.getMinutes() + defaultWaitMinutes);
    logger.warn(`未能解析重置时间，使用默认等待 ${defaultWaitMinutes} 分钟`);
    return defaultTime;
  }

  /**
   * 获取默认等待时间（分钟）
   */
  private getDefaultWaitTime(): number {
    const now = new Date();
    const hour = now.getHours();
    
    // 根据时间段调整默认等待时间
    if (hour >= 9 && hour < 18) {
      return 60; // 工作时间：1小时
    } else if (hour >= 18 && hour < 22) {
      return 30; // 晚上：30分钟
    } else {
      return 120; // 深夜/凌晨：2小时
    }
  }

  /**
   * 解析时间匹配结果
   */
  private parseTimeMatch(match: RegExpMatchArray, patternIndex: number): Date | null {
    const now = new Date();
    logger.info(`解析时间匹配，模式索引: ${patternIndex}, 匹配组: [${match.slice(1).join(', ')}]`);
    
    // 绝对时间格式 (模式 0-3): HH:MM [AM/PM]
    if (patternIndex <= 3 && match[1] && match[2]) {
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
    
    // 相对时间格式 - 仅分钟 (模式 4-7, 14)
    if ((patternIndex >= 4 && patternIndex <= 7) || patternIndex === 14) {
      if (match[1] && !match[2]) {
        const minutes = parseInt(match[1]);
        const resetTime = new Date(now);
        resetTime.setMinutes(resetTime.getMinutes() + minutes);
        return resetTime;
      }
    }
    
    // 相对时间格式 - 小时和分钟 (模式 8-13)
    if (patternIndex >= 8 && patternIndex <= 13) {
      const hours = parseInt(match[1]) || 0;
      const minutes = parseInt(match[2]) || 0;
      const resetTime = new Date(now);
      resetTime.setHours(resetTime.getHours() + hours, resetTime.getMinutes() + minutes);
      return resetTime;
    }
    
    // 中文时间格式 (模式 15-18)
    if (patternIndex >= 15 && patternIndex <= 18) {
      if (patternIndex === 15) { // X小时Y分钟
        const hours = parseInt(match[1]) || 0;
        const minutes = parseInt(match[2]) || 0;
        const resetTime = new Date(now);
        resetTime.setHours(resetTime.getHours() + hours, resetTime.getMinutes() + minutes);
        return resetTime;
      } else if (patternIndex === 16) { // X分钟
        const minutes = parseInt(match[1]);
        const resetTime = new Date(now);
        resetTime.setMinutes(resetTime.getMinutes() + minutes);
        return resetTime;
      } else if (patternIndex === 17 || patternIndex === 18) { // HH:MM 格式
        const hours = parseInt(match[1]);
        const minutes = parseInt(match[2]);
        const resetTime = new Date(now);
        resetTime.setHours(hours, minutes, 0, 0);
        
        // 如果时间已过，设为明天
        if (resetTime <= now) {
          resetTime.setDate(resetTime.getDate() + 1);
        }
        return resetTime;
      }
    }
    
    // ISO时间格式 (模式 19-20)
    if (patternIndex >= 19 && patternIndex <= 20) {
      try {
        return new Date(match[1]);
      } catch (error) {
        logger.warn(`ISO时间解析失败: ${match[1]}`);
        return null;
      }
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
    console.log(chalk.blue(`⏰ 重置时间: ${resetTime.toLocaleString()}`));
    console.log(chalk.green(`⏳ 等待时间: ${hours}小时${minutes}分钟`));
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
      logger.info(`设置自动恢复定时器: ${waitTime}ms`);
      
      setTimeout(async () => {
        console.log(chalk.green('🔔 限制时间已重置，自动恢复执行...'));
        logger.info('自动恢复执行Claude命令');
        
        try {
          await this.executeClaude(args);
          this.clearState();
        } catch (error) {
          logger.error(`自动恢复执行失败: ${error}`);
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
      logger.error(`保存状态失败: ${error}`);
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
      logger.error(`加载状态失败: ${error}`);
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
        unlinkSync(this.stateFile);
        logger.info('状态已清除');
      }
    } catch (error) {
      logger.error(`清除状态失败: ${error}`);
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
    console.log(`🔄 等待状态: ${status.isWaiting ? '等待中' : '空闲'}`);
    if (status.isWaiting && status.resetTime) {
      console.log(`⏰ 重置时间: ${status.resetTime.toLocaleString()}`);
      console.log(`📝 原始命令: claude ${status.command.join(' ')}`);
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
    logger.error(`Wrapper执行失败: ${error}`);
    console.error(chalk.red('❌ 执行失败，请查看日志文件: .claude-wrapper.log'));
    process.exit(1);
  }
}

// 处理进程信号
process.on('SIGINT', () => {
  console.log(chalk.yellow('\n🔄 正在保存状态并退出...'));
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log(chalk.yellow('\n🔄 正在保存状态并退出...'));
  process.exit(0);
});

// 未捕获异常处理
process.on('unhandledRejection', (reason, promise) => {
  logger.error(`未处理的Promise拒绝: ${reason}`);
  console.error(chalk.red('❌ 程序异常，详情请查看日志'));
});

// 启动主程序
main().catch((error) => {
  console.error(`主程序异常: ${error}`);
  process.exit(1);
});