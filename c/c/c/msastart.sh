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
MONKEY_OUTPUT_FILE="MSALCS"

echo "猴值递归导出工具"
echo "========================"
echo "根目录: $SCRIPT_DIR"
echo "输出文件: $MONKEY_OUTPUT_FILE"
echo "========================"

# 切换到脚本目录
cd "$SCRIPT_DIR"

# 检查猴值文件是否已存在
if [ -f "$MONKEY_OUTPUT_FILE" ]; then
    echo "检测到猴值文件已存在: $MONKEY_OUTPUT_FILE"
    echo "文件信息:"
    echo "  - 大小: $(du -h "$MONKEY_OUTPUT_FILE" | cut -f1)"
    echo "  - 修改时间: $(date -r "$MONKEY_OUTPUT_FILE" "+%Y-%m-%d %H:%M:%S")"
    echo "  - 包含文件数: $(grep -c "^[^#]" "$MONKEY_OUTPUT_FILE" 2>/dev/null || echo "未知")"
    echo ""
    
    # 用户确认是否覆盖
    while true; do
        echo "请选择操作:"
        echo "1) 覆盖现有文件（重新计算所有文件）"
        echo "2) 追加新文件（只计算新增和未记录的文件）"
        echo "3) 跳过（不计算）"
        echo "4) 退出"
        read -p "请输入选项 (1-4): " choice
        
        case "$choice" in
            1)
                echo "选择: 覆盖现有文件"
                # 备份已存在的文件
                backup_file="${MONKEY_OUTPUT_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
                cp "$MONKEY_OUTPUT_FILE" "$backup_file"
                echo "已备份原文件到: $backup_file"
                # 清空现有文件
                > "$MONKEY_OUTPUT_FILE"
                break
                ;;
            2)
                echo "选择: 追加新文件"
                # 读取已存在的文件列表
                existing_files=$(grep -v "^#" "$MONKEY_OUTPUT_FILE" 2>/dev/null | awk '{print $1}' || echo "")
                echo "已记录 $((echo "$existing_files" | wc -l) 2>/dev/null || echo 0) 个文件"
                APPEND_MODE=true
                break
                ;;
            3)
                echo "选择: 跳过"
                echo "操作已取消"
                exit 0
                ;;
            4)
                echo "选择: 退出"
                exit 0
                ;;
            *)
                echo "无效选项，请输入 1-4"
                ;;
        esac
    done
else
    echo "猴值文件不存在: $MONKEY_OUTPUT_FILE，将创建新文件。"
    echo ""
fi

# 计算猴值函数
calculate_monkey_hash() {
    local file="$1"
    
    # 获取文件名（不含路径）
    local filename=$(basename "$file")
    
    # 提取文件名和后缀名
    local name_only="${filename%.*}"
    local extension="${filename##*.}"
    
    # 如果文件没有后缀名
    if [ "$name_only" = "$filename" ]; then
        name_only="$filename"
        extension=""
    fi
    
    # 获取文件的前128个字节的16进制表示
    local hex_content=""
    if [ -f "$file" ]; then
        # 使用od读取文件前128字节并转换为16进制
        hex_content=$(od -An -tx1 -N128 "$file" 2>/dev/null | tr -d ' \n' | head -c 256)
    fi
    
    # 将文件名、后缀名和16进制内容组合
    local combined="${name_only}${extension}${hex_content}"
    
    # 计算SHA256哈希值作为猴值
    local monkey_hash=$(echo -n "$combined" | sha256sum | cut -d' ' -f1)
    
    echo "$monkey_hash"
}

# 检查文件是否已存在
is_file_already_processed() {
    local file="$1"
    if [ "$APPEND_MODE" = true ] && [ -n "$existing_files" ]; then
        echo "$existing_files" | grep -Fxq "$file"
        return $?
    fi
    return 1
}

# 检查依赖工具
check_dependencies() {
    local missing_tools=""
    
    # 检查od工具
    if ! command -v od >/dev/null 2>&1; then
        missing_tools="od"
    fi
    
    # 检查sha256sum工具
    if ! command -v sha256sum >/dev/null 2>&1; then
        if [ -n "$missing_tools" ]; then
            missing_tools="$missing_tools, sha256sum"
        else
            missing_tools="sha256sum"
        fi
    fi
    
    if [ -n "$missing_tools" ]; then
        echo "错误: 缺少必要的工具: $missing_tools" >&2
        echo "" >&2
        echo "安装方法:" >&2
        echo "Ubuntu/Debian: sudo apt-get install coreutils" >&2
        echo "CentOS/RHEL: sudo yum install coreutils" >&2
        exit 1
    fi
}

# 生成猴值报告
generate_monkey_report() {
    local output_file="$1"
    local append_mode="${2:-false}"
    
    echo "正在递归计算猴值..."
    echo "模式: $([ "$append_mode" = true ] && echo "追加模式" || echo "覆盖模式")"
    echo "这可能需要一些时间，请稍候..."
    echo
    
    # 如果不是追加模式，生成新的文件头
    if [ "$append_mode" != true ]; then
        {
            echo "# 猴值递归校验报告"
            echo "# 生成时间: $(date)"
            echo "# 根目录: $SCRIPT_DIR"
            echo "# 输出文件: $output_file"
            echo "# 格式: 文件相对路径 猴值"
            echo ""
        } > "$output_file"
    else
        echo "# 追加模式开始时间: $(date)" >> "$output_file"
    fi
    
    # 获取文件总数用于进度显示
    echo "正在扫描文件..."
    
    # 构建查找条件
    find_cmd="find . -type f"
    find_cmd="$find_cmd ! -name \"$output_file\""
    find_cmd="$find_cmd ! -name \"$(basename "$0")\""
    find_cmd="$find_cmd ! -name \"*.bak.*\""
    
    # 排除输出文件
    exclude_files=("$output_file" "$(basename "$0")")
    for exclude in "${exclude_files[@]}"; do
        find_cmd="$find_cmd ! -name \"$exclude\""
    done
    
    # 计算总文件数
    total_files=$(eval "$find_cmd" | wc -l)
    
    if [ "$append_mode" = true ] && [ -n "$existing_files" ]; then
        existing_count=$(echo "$existing_files" | wc -l 2>/dev/null || echo 0)
        echo "找到 $total_files 个文件，其中 $existing_count 个已记录，开始计算剩余文件..."
    else
        echo "找到 $total_files 个文件，开始计算猴值..."
    fi
    
    echo
    
    # 进度计数
    current=0
    processed_count=0
    skipped_count=0
    
    # 递归处理所有文件
    eval "$find_cmd" | while read file; do
        if [ -r "$file" ]; then
            ((current++))
            
            # 获取相对路径
            file_path="${file#./}"
            
            # 在追加模式下，检查文件是否已处理
            if [ "$append_mode" = true ] && is_file_already_processed "$file_path"; then
                ((skipped_count++))
                # 显示跳过进度
                if [ $((current % 50)) -eq 0 ] || [ $current -eq $total_files ]; then
                    percent=$((current * 100 / total_files))
                    printf "进度: %3d%% [%d/%d] - 跳过: %d - 最近文件: %s\\r" \
                        "$percent" "$current" "$total_files" "$skipped_count" \
                        "$(basename "$file" | cut -c1-20)"
                fi
                continue
            fi
            
            # 计算猴值
            monkey_value=$(calculate_monkey_hash "$file" 2>/dev/null)
            if [ -n "$monkey_value" ]; then
                echo "$file_path $monkey_value" >> "$output_file"
                ((processed_count++))
                
                # 显示进度（每10个文件显示一次）
                if [ $((current % 10)) -eq 0 ] || [ $current -eq $total_files ]; then
                    percent=$((current * 100 / total_files))
                    printf "进度: %3d%% [%d/%d] - 新增: %d - 最近文件: %s\\r" \
                        "$percent" "$current" "$total_files" "$processed_count" \
                        "$(basename "$file" | cut -c1-20)"
                fi
            else
                echo "警告: 无法计算 $file 的猴值" >&2
            fi
        fi
    done
    
    echo
    echo
    
    # 如果不是追加模式，添加统计信息
    if [ "$append_mode" != true ]; then
        actual_count=$(grep -c "^[^#]" "$output_file")
        {
            echo ""
            echo "# 统计信息"
            echo "# 总文件数: $actual_count"
            echo "# 完成时间: $(date)"
            echo "# 文件大小: $(du -h "$output_file" | cut -f1)"
        } >> "$output_file"
    else
        echo "# 追加完成时间: $(date)" >> "$output_file"
        echo "# 本次新增文件数: $processed_count" >> "$output_file"
        if [ $skipped_count -gt 0 ]; then
            echo "# 跳过已存在文件数: $skipped_count" >> "$output_file"
        fi
    fi
    
    echo "========================================"
    echo "猴值导出完成！"
    echo "输出文件: $output_file"
    if [ "$append_mode" = true ]; then
        echo "模式: 追加"
        echo "本次新增文件数: $processed_count"
        if [ $skipped_count -gt 0 ]; then
            echo "跳过已存在文件数: $skipped_count"
        fi
    else
        echo "模式: 覆盖"
        echo "总文件数: $processed_count"
    fi
    echo "文件大小: $(du -h "$output_file" | cut -f1)"
    
    # 显示前几个文件作为示例
    if [ $processed_count -gt 0 ]; then
        echo ""
        echo "最后5个处理的文件:"
        echo "----------------"
        tail -n 5 "$output_file" | grep -v "^#"
    fi
}

# 主执行流程
main() {
    # 检查依赖工具
    check_dependencies
    
    # 生成猴值报告
    generate_monkey_report "$MONKEY_OUTPUT_FILE" "$APPEND_MODE"
}

# 运行主函数
main
