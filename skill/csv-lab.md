# CSV 数据工具箱

**一句话**：CSV 批量切分 / 去重 / 字段校验 / 清洗 / 合并 / 转 Excel（自动识别编码分隔符）。

## 什么时候用

用户要处理 CSV/TSV 表格：文件太大打不开、多个表要合并、要去重、要检查手机号/日期/邮箱/数字格式、要清洗空格和空行、要 CSV 与 Excel 互转时。

## 怎么调用

```bash
<cli 路径> --help
```

```bash
<cli 路径> --demo

# 看编码/分隔符
<cli 路径> sniff --input ./数据 --json

# 大文件切分（每片 5 万行，保留表头）
<cli 路径> split --input ./大表.csv --rows 50000 --out ./分片

# 去重（整行 / 指定列）
<cli 路径> dedupe --input ./客户.csv [--key 手机号,姓名] --out ./去重

# 字段校验（报告写到 <out>/校验报告.json）
<cli 路径> validate --input ./客户.csv --required 姓名,手机号 --email 邮箱 --date 生日 --numeric 金额 --json

# 清洗（去空格、删空行）
<cli 路径> clean --input ./客户.csv --out ./清洗

# 合并目录内多个 CSV（按表头映射）
<cli 路径> merge --input ./月度 --source-col --out ./合并

# 转 Excel
<cli 路径> convert --input ./数据 --format xlsx --out ./excel
```

## 边界（必须向用户说清）

- 默认只写 `--out`（缺省 `<输入目录>/_输出`），**不改输入文件**；同名不覆盖，自动加序号；
- `validate` 的规则必须由用户指定列名，不猜业务含义；
- 转 Excel 需要本机 openpyxl，缺依赖会报 `python3 -m pip install openpyxl` 并以退出码 3 结束；
- 不做 SQL/JOIN、不做公式/样式/图表/宏、不支持加密或损坏文件；
- 编码/分隔符是启发式识别，极短或格式混乱的文件可能误判，先 `sniff --json` 确认。
