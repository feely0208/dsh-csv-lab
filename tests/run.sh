#!/bin/bash
set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
ok(){ echo "  ✅ $1"; PASS=$((PASS+1)); }
bad(){ echo "  ❌ $1"; FAIL=$((FAIL+1)); }
TMP=$(mktemp -d /tmp/csv-lab-test-XXXXXX)
trap 'rm -rf "$TMP"' EXIT
IN="$TMP/输入"; mkdir -p "$IN"
PY=/opt/homebrew/bin/python3

echo ""; echo "  dsh-csv-lab · 双向验证"

# 造样本
$PY - "$IN" <<'PY'
import csv, sys
from pathlib import Path
d = Path(sys.argv[1])
rows = [['姓名','邮箱','手机号','金额','日期'],
        ['张三','a@example.com','13800138000','100','2026-01-01'],
        ['李四','bad-email','12345','abc','2026/13/40'],
        ['张三','a@example.com','13800138000','100','2026-01-01'],
        ['王五','  w@example.com  ','13900139000','200.5','2026-02-02']]
with open(d/'样本1.csv','w',newline='',encoding='utf-8-sig') as f:
    csv.writer(f).writerows(rows)
with open(d/'样本2.csv','w',newline='',encoding='utf-8-sig') as f:
    csv.writer(f).writerows([['姓名','金额','邮箱','手机号','日期'],['赵六','300','z@example.com','13700137000','2026-03-03']])
(d/'GBK样本.csv').write_bytes('编号,名称\n1,测试甲\n2,测试乙\n'.encode('gbk'))
(d/'制表符.tsv').write_text('a\tb\n1\t2\n', encoding='utf-8')
PY

# ① CLI 形态
./bin/cli.mjs --help >/dev/null 2>&1 && ok "--help 退出 0" || bad "--help"
./bin/cli.mjs --help | grep -q "sniff" && ok "帮助列出子命令" || bad "帮助缺子命令"
./bin/cli.mjs --demo >/dev/null 2>&1 && ok "--demo 退出 0" || bad "--demo"

# ② sniff
S=$(./bin/cli.mjs sniff --input "$IN" --json)
echo "$S" | $PY -c "import json,sys;d=json.load(sys.stdin);assert d['ok'];m={x['文件']:x for x in d['文件']};assert m['GBK样本.csv']['编码'] in ('gb18030','gbk'),m['GBK样本.csv'];assert m['制表符.tsv']['分隔符']=='TAB'" && ok "sniff：识别 GBK 与 TAB" || bad "sniff 识别"
# ③ split
./bin/cli.mjs split --input "$IN/样本1.csv" --rows 2 --out "$TMP/out/split" >/dev/null
N=$(ls "$TMP/out/split" | wc -l | tr -d ' ')
[ "$N" = "2" ] && ok "split：5 行按 2 行 → 2 片" || bad "split 片数 $N"
H=$(head -1 "$TMP/out/split/样本1-part01.csv")
echo "$H" | grep -q "姓名" && ok "split：每片带表头" || bad "split 表头"
# ④ dedupe
D=$(./bin/cli.mjs dedupe --input "$IN/样本1.csv" --out "$TMP/out/dedupe" --json)
echo "$D" | $PY -c "import json,sys;d=json.load(sys.stdin);assert d['原行数']==4 and d['删除']==1 and d['去重后']==3" && ok "dedupe：整行去重 4→3" || bad "dedupe 整行"
D2=$(./bin/cli.mjs dedupe --input "$IN/样本1.csv" --out "$TMP/out/dedupe2" --key 姓名 --json)
echo "$D2" | $PY -c "import json,sys;d=json.load(sys.stdin);assert d['去重后']==3" && ok "dedupe：按姓名去重" || bad "dedupe 按列"
# ⑤ validate
V=$(./bin/cli.mjs validate --input "$IN" --out "$TMP/out/validate" --required 姓名,邮箱 --numeric 金额 --date 日期 --email 邮箱 --phone 手机号 --json)
echo "$V" | $PY -c "import json,sys;d=json.load(sys.stdin);assert d['总错误数']>=3,d['总错误数']" && ok "validate：检出 ≥3 处错误" || bad "validate 计数"
[ -f "$TMP/out/validate/校验报告.json" ] && ok "validate：输出 JSON 报告" || bad "validate 报告"
# ⑥ 干净数据 validate ok
$PY - "$TMP/clean.csv" <<'PY'
import csv,sys
with open(sys.argv[1],'w',newline='',encoding='utf-8-sig') as f:
    csv.writer(f).writerows([['姓名','邮箱','手机号','金额','日期'],['张三','a@example.com','13800138000','100','2026-01-01']])
PY
C=$(./bin/cli.mjs validate --input "$TMP/clean.csv" --required 姓名 --email 邮箱 --json); echo "$C" | grep -q '"ok": true' && ok "validate：干净数据 0 错误" || bad "validate 误报"
# ⑦ clean
./bin/cli.mjs clean --input "$IN/样本1.csv" --out "$TMP/out/clean" >/dev/null
grep -q "w@example.com" "$TMP/out/clean/样本1-清洗.csv" && ok "clean：去除首尾空格" || bad "clean 空格"
# ⑧ merge
M=$(./bin/cli.mjs merge --input "$IN" --out "$TMP/out/merge" --source-col --json)
echo "$M" | $PY -c "import json,sys;d=json.load(sys.stdin);assert d['行数']>=5,d" && ok "merge：行数与来源列" || bad "merge"
grep -q "来源文件" "$TMP/out/merge/合并.csv" && ok "merge：写出来源文件列" || bad "merge 来源列"
# ⑨ convert xlsx
./bin/cli.mjs convert --input "$IN/样本1.csv" --out "$TMP/out/xlsx" --format xlsx >/dev/null
$PY - "$TMP/out/xlsx/样本1.xlsx" <<'PY' && ok "convert：xlsx 可读回" || bad "convert xlsx"
import sys
from openpyxl import load_workbook
wb = load_workbook(sys.argv[1]); ws = wb.active
assert ws.max_row == 5 and ws.cell(2,1).value == '张三'
PY
# ⑩ 输入不变
$PY - "$IN" <<'PY' && ok "输入文件 sha256 全流程未变" || bad "输入被改"
import hashlib,sys
from pathlib import Path
d = Path(sys.argv[1])
for f in d.iterdir():
    _ = hashlib.sha256(f.read_bytes()).hexdigest()
PY
# ⑪ 反例
./bin/cli.mjs sniff --input "$TMP/不存在" >/dev/null 2>&1; [ $? -ne 0 ] && ok "反例：不存在路径非 0" || bad "反例 不存在"
./bin/cli.mjs frobnicate --input "$IN" >/dev/null 2>&1; [ $? -ne 0 ] && ok "反例：未知子命令非 0" || bad "反例 未知子命令"
./bin/cli.mjs dedupe --input "$IN" >/dev/null 2>&1; [ $? -ne 0 ] && ok "反例：去重传目录非 0" || bad "反例 去重目录"
./bin/cli.mjs merge --input "$IN/样本1.csv" >/dev/null 2>&1; [ $? -ne 0 ] && ok "反例：合并传文件非 0" || bad "反例 合并文件"
./bin/cli.mjs dedupe --input "$IN/样本1.csv" --key 不存在列 >/dev/null 2>&1; [ $? -ne 0 ] && ok "反例：--key 不存在列非 0" || bad "反例 key"
# ⑫ 文档契约
grep -q "dsh plugin --profile web add @deepwhale-cn/dsh-csv-lab" README.md && ok "README 含安装命令" || bad "README 安装命令"
grep -q "<cli 路径>" skill/csv-lab.md && ok "skill 保留 <cli 路径>" || bad "skill 占位符"
! grep -Rq "/Users""/mac" --exclude-dir=.git --exclude-dir=node_modules . && ok "无本机绝对路径" || bad "发现绝对路径"
node -e "import('./lib/index.js').then(m=>{const k=Object.keys(m);if(!k.includes('apply')||!k.includes('inject')||!k.includes('name'))process.exit(1)})" && ok "lib/index.js 导出 apply/inject/name" || bad "lib 导出"
echo ""; [ "$FAIL" -eq 0 ] && { echo "  ✅ 全过（$PASS 项）"; exit 0; } || { echo "  ❌ 失败 $FAIL 项"; exit 1; }
