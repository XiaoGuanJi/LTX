#!/bin/bash
#
# Copyright [2023] [LAOLIPEF]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="MD5SLCS"

echo "MD5递归导出工具"
echo "========================"
echo "根目录: $SCRIPT_DIR"
echo "输出文件: $OUTPUT_FILE"
echo "========================"

# 切换到脚本目录
cd "$SCRIPT_DIR"

# 检查输出文件是否已存在
if [ -f "$OUTPUT_FILE" ]; then
    echo "警告: 输出文件 $OUTPUT_FILE 已存在！"
    echo "文件信息:"
    echo "  - 大小: $(du -h "$OUTPUT_FILE" | cut -f1)"
    echo "  - 修改时间: $(date -r "$OUTPUT_FILE" "+%Y-%m-%d %H:%M:%S")"
    echo "  - 包含文件数: $(grep -c "^[^#]" "$OUTPUT_FILE" 2>/dev/null || echo "未知")"
    echo ""
    
    # 用户确认是否覆盖
    while true; do
        read -p "是否覆盖现有文件？(y/n): " choice
        case "$choice" in
            [Yy]* )
                echo "正在覆盖现有文件..."
                break
                ;;
            [Nn]* )
                echo "操作已取消"
                exit 0
                ;;
            * )
                echo "请输入 y 或 n"
                ;;
        esac
    done
else
    # 文件不存在，确认是否创建
    echo "输出文件 $OUTPUT_FILE 不存在，将创建新文件。"
    while true; do
        read -p "是否继续导出MD5？(y/n): " choice
        case "$choice" in
            [Yy]* )
                echo "开始导出MD5..."
                break
                ;;
            [Nn]* )
                echo "操作已取消"
                exit 0
                ;;
            * )
                echo "请输入 y 或 n"
                ;;
        esac
    done
fi

# 备份已存在的文件
if [ -f "$OUTPUT_FILE" ]; then
    backup_file="${OUTPUT_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$OUTPUT_FILE" "$backup_file"
    echo "已备份原文件到: $backup_file"
fi

# 生成MD5报告
echo "正在递归计算MD5值..."
echo "这可能需要一些时间，请稍候..."
echo

# 生成文件头
{
    echo "# MD5递归校验报告"
    echo "# 生成时间: $(date)"
    echo "# 根目录: $SCRIPT_DIR"
    echo "# 输出文件: $OUTPUT_FILE"
    echo "# 格式: 文件相对路径 MD5值"
    echo ""
} > "$OUTPUT_FILE"

# 获取文件总数用于进度显示
echo "正在扫描文件..."
total_files=$(find . -type f \( ! -name "$OUTPUT_FILE" ! -name "$(basename "$0")" ! -name "*.bak.*" \) | wc -l)
echo "找到 $total_files 个文件，开始计算MD5..."
echo

# 进度计数
current=0

# 递归处理所有文件
find . -type f \( ! -name "$OUTPUT_FILE" ! -name "$(basename "$0")" ! -name "*.bak.*" \) | while read file; do
    if [ -r "$file" ]; then
        ((current++))
        # 计算MD5并格式化输出
        md5_value=$(md5sum "$file" 2>/dev/null | awk '{print $1}')
        if [ -n "$md5_value" ]; then
            # 去除路径前的./
            file_path="${file#./}"
            echo "$file_path $md5_value" >> "$OUTPUT_FILE"
            
            # 显示进度（每10个文件显示一次）
            if [ $((current % 10)) -eq 0 ] || [ $current -eq $total_files ]; then
                percent=$((current * 100 / total_files))
                printf "进度: %3d%% [%d/%d] - 最近文件: %s\\r" \
                    "$percent" "$current" "$total_files" \
                    "$(basename "$file" | cut -c1-20)"
            fi
        else
            echo "警告: 无法计算 $file 的MD5值" >&2
        fi
    fi
done

echo
echo

# 添加统计信息
actual_count=$(grep -c "^[^#]" "$OUTPUT_FILE")
{
    echo ""
    echo "# 统计信息"
    echo "# 总文件数: $actual_count"
    echo "# 完成时间: $(date)"
    echo "# 文件大小: $(du -h "$OUTPUT_FILE" | cut -f1)"
} >> "$OUTPUT_FILE"

echo "========================"
echo "MD5导出完成！"
echo "输出文件: $OUTPUT_FILE"
echo "总文件数: $actual_count"
echo "文件大小: $(du -h "$OUTPUT_FILE" | cut -f1)"

# 显示前几个文件作为示例
echo ""
echo "前5个文件的MD5示例:"
echo "----------------"
head -n 10 "$OUTPUT_FILE" | grep -v "^#"
