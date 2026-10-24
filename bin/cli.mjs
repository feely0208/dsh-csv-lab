#!/usr/bin/env node
/** dsh-csv-lab —— CSV 数据工具箱（Node 只做参数转发，逻辑在 lib/csv_tool.py） */
import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const 根 = join(dirname(fileURLToPath(import.meta.url)), '..');
const PY = process.env.CSV_LAB_PYTHON || process.env.DSH_PYTHON || '/opt/homebrew/bin/python3';
const 脚本 = join(根, 'lib', 'csv_tool.py');
const argv = process.argv.slice(2);

if (!existsSync(PY)) {
  console.error('缺少 python3：请先安装 python3（macOS 可用 brew install python3）');
  process.exit(3);
}

const 参数 = [...argv];
const 动作 = argv.find((a) => !a.startsWith('-')) || '';

if (动作 === 'convert' && !argv.includes('--json')) {
  // 缺 openpyxl 时由 Python 端给出明确提示并以 3 退出
}

const r = spawnSync(PY, [脚本, ...参数], { stdio: 'inherit', env: process.env });
if (r.error) {
  console.error('执行失败：' + r.error.message);
  process.exit(3);
}
process.exit(r.status === null ? 1 : r.status);
