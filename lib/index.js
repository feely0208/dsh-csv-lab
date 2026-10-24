import { createPlugin, pkgRootFrom } from '@deepwhale-cn/dsh-guard-core/plugin';

export const { name, inject, apply } = createPlugin({
  name: 'csv-lab',
  pkgRoot: pkgRootFrom(import.meta.url),
  skillFile: 'skill/csv-lab.md',
  binFile: 'bin/cli.mjs',
  description: 'CSV 批量切分 / 去重 / 字段校验 / 清洗 / 合并 / 转 Excel（自动识别编码分隔符）',
  whenToUse: '用户提到「CSV 数据工具箱」或任务属于该场景时使用',
});
