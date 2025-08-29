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
   * 查找原始Claude可执行文件
   */
  private findOriginalClaude(): string {
    const possiblePaths = [
      'D:\\npm-global\\node_modules\\@anthropic-ai\\claude-code\\cli.js',
      'C:\\Users\\Administrator\\AppData\\Roaming\\npm\\node_modules\\@anthropic-ai\\claude-code\\cli.js'
    ];

    for (const path of possiblePaths) {
      if (existsSync(path)) {
        return path;
      }
    }

    // 如果找不到，使用系统PATH中的claude
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
      /(?:limit\s+)?reset\s+at\s+(\d{1,2}):(\d{2})(?:\s*(AM|PM))?/i,
      /(?:limit\s+)?reset\s+in\s+(\d+)\s*(?:minute|min)s?/i,
      /(?:limit\s+)?reset\s+in\s+(\d+)\s*(?:hour|hr)s?\s*(?:(?:and\s+)?(\d+)\s*(?:minute|min)s?)?/i,
      /try\s+again\s+at\s+(\d{1,2}):(\d{2})(?:\s*(AM|PM))?/i
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
    
    // 格式3: 小时和分钟
    if (match[1] && match[2]) {
      const hours = parseInt(match[1]);
      const minutes = parseInt(match[2]) || 0;
      const resetTime = new Date(now);
      resetTime.setHours(resetTime.getHours() + hours, resetTime.getMinutes() + minutes);
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
        const fs = require('fs');
        fs.unlinkSync(this.stateFile);
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
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((error) => {
    logger.error(`主程序异常: ${error}`);
    process.exit(1);
  });
}