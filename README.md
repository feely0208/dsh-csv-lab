# @deepwhale-cn/dsh-csv-lab

[![Listed on dsh-plugin.org](https://dsh-plugin.org/badges/listed.svg)](https://dsh-plugin.org/plugins/feely0208/dsh-csv-lab)

**CSV 数据工具箱**：批量切分 / 去重 / 字段校验 / 清洗 / 合并 / 转 Excel，自动识别编码与分隔符。

## 不装会怎样

几十万行的 CSV 打不开、GBK 导出的表格全是乱码、合并多个表要手工对表头、手机号/日期错漏靠眼睛找——这些活 Excel 里做一遍要半天，还容易漏。

## 能做什么

| 子命令 | 做什么 |
|---|---|
| `sniff` | 识别编码（UTF-8/GBK/GB18030）、分隔符（逗号/制表符/分号）、是否有表头 |
| `split` | 按行数切分大文件（默认每片 10000 行，保留表头） |
| `dedupe` | 整行去重，或 `--key 姓名,手机号` 按列去重 |
| `validate` | 字段校验：必填、数字、日期、邮箱、手机号；输出 `校验报告.json` |
| `clean` | 去首尾空格、删空行、规范表头 |
| `merge` | 合并目录内多个 CSV，按表头名映射，`--source-col` 加来源文件列 |
| `convert` | CSV → Excel（xlsx），或 Excel → CSV（每个工作表一个文件） |

全部本地处理，不联网、不上传；默认输出到 `<输入目录>/_输出`，不改输入文件。

## 不能做什么

- ❌ 不是数据库：不做跨表 JOIN、聚合查询、SQL；大文件是切分而不是索引查询；
- ❌ 不做 Excel 公式重算、样式/图表/宏（只读写值）；
- ❌ 不猜测业务字段含义：校验规则由你通过 `--required/--numeric/--date/--email/--phone` 指定；
- ❌ 不处理 XML/JSON/Parquet；不支持加密或损坏文件（会明确报错）；
- ❌ 分隔符/编码识别是启发式，极短文件可能识别错，可用 `--json` 看识别结果。

## 安装

```bash
dsh plugin --profile web add @deepwhale-cn/dsh-csv-lab
```

运行依赖本机 **python3**（转 Excel 另需 openpyxl，缺时会打印安装命令）：

```bash
python3 -m pip install openpyxl
```

## 用法

```bash
dsh-csv-lab --demo

dsh-csv-lab sniff --input ./数据
dsh-csv-lab split --input ./大表.csv --rows 50000 --out ./分片
dsh-csv-lab dedupe --input ./客户.csv --key 手机号 --out ./去重
dsh-csv-lab validate --input ./客户.csv --required 姓名,手机号 --email 邮箱 --date 生日 --json
dsh-csv-lab clean --input ./客户.csv --out ./清洗
dsh-csv-lab merge --input ./月度 --source-col --out ./合并
dsh-csv-lab convert --input ./数据 --format xlsx --out ./excel
```

## License

MIT © 温州深鲸智能科技有限公司
