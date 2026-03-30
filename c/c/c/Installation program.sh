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

#!/bin/bash

# 显示欢迎信息
echo "==============================================="
echo "   欢迎使用 LAOLIPEF 开发项目安装程序"
echo "==============================================="
echo ""

# LAOLIPEF项目信息
echo "LAOLIPEF 开发框架安装程序"
echo "版本: 1.0"
echo "文件格式: .lzx32"
echo ""

# 用户协议
echo "LAOLIPEF 项目安装用户协议"
echo "=========================="
echo "1. 本安装程序用于安装LAOLIPEF开发项目文件"
echo "2. 安装过程将解压.lzx32项目文件到指定目录"
echo "3. 请确保您有合法的项目使用权限"
echo "4. 安装可能会覆盖现有文件，请提前备份重要数据"
echo "5. 安装完成后请按照项目文档进行配置"
echo ""

echo "是否同意用户协议并继续安装？(y/n): "
read -r agreement

if [ "$agreement" != "y" ] && [ "$agreement" != "Y" ]; then
    echo "您已拒绝用户协议，安装程序退出。"
    exit 1
fi

echo ""
echo "✓ 已同意用户协议"
echo "------------------------------------------"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR/c"

# 创建安装目录
echo "创建安装目录: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# 查找LAOLIPEF项目文件
echo "正在扫描LAOLIPEF项目文件..."
echo "------------------------------------------"

lzx32_files=("$SCRIPT_DIR"/*.lzx32)

if [ ${#lzx32_files[@]} -eq 0 ] || [ ! -f "${lzx32_files[0]}" ]; then
    echo "未找到LAOLIPEF项目文件(.lzx32)"
    echo ""
    echo "请将.lzx32项目文件放置在与安装脚本相同的目录下"
    exit 1
fi

# 显示找到的项目文件
echo "找到以下LAOLIPEF项目文件:"
echo "------------------------------------------"
for i in "${!lzx32_files[@]}"; do
    filename=$(basename "${lzx32_files[$i]}")
    size=$(du -h "${lzx32_files[$i]}" | cut -f1)
    file_info=$(file "${lzx32_files[$i]}")
    echo "$((i+1)). $filename ($size)"
    echo "   类型: $file_info"
done
echo "------------------------------------------"

# 选择要安装的项目文件
if [ ${#lzx32_files[@]} -gt 1 ]; then
    echo "请选择要安装的项目文件 (1-${#lzx32_files[@]}): "
    read -r choice
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#lzx32_files[@]}" ]; then
        echo "无效的选择，安装程序退出。"
        exit 1
    fi
    
    selected_file="${lzx32_files[$((choice-1))]}"
else
    selected_file="${lzx32_files[0]}"
fi

filename=$(basename "$selected_file")
echo "选择安装: $filename"
echo "安装目录: $INSTALL_DIR"
echo ""

# 确认安装
echo "是否开始安装？(y/n): "
read -r confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "安装已取消。"
    exit 0
fi

echo "开始安装LAOLIPEF项目..."
echo "==============================================="

# 安装过程
echo "步骤1: 检查文件完整性..."
file_size=$(du -h "$selected_file" | cut -f1)
file_type=$(file "$selected_file")
echo "文件大小: $file_size"
echo "文件类型: $file_type"
echo ""

echo "步骤2: 准备解压环境..."
echo "安装目录: $INSTALL_DIR"
echo "清空安装目录..."
rm -rf "$INSTALL_DIR"/*
mkdir -p "$INSTALL_DIR"
echo "✓ 安装目录准备完成"
echo ""

echo "步骤3: 开始解压项目文件..."
echo "------------------------------------------"
echo "详细提取过程:"
echo "------------------------------------------"

# 使用tar的详细模式显示提取过程
cd "$INSTALL_DIR"

# 尝试不同的解压方式并显示详细过程
extract_success=false

echo "尝试标准tar格式解压..."
if tar -xvf "$selected_file" 2>/dev/null; then
    echo "✓ 使用标准tar格式解压成功"
    extract_success=true
else
    echo "尝试gzip压缩格式解压..."
    if tar -xzvf "$selected_file" 2>/dev/null; then
        echo "✓ 使用gzip压缩格式解压成功"
        extract_success=true
    else
        echo "尝试bzip2压缩格式解压..."
        if tar -xjvf "$selected_file" 2>/dev/null; then
            echo "✓ 使用bzip2压缩格式解压成功"
            extract_success=true
        else
            echo "尝试xz压缩格式解压..."
            if tar -xJvf "$selected_file" 2>/dev/null; then
                echo "✓ 使用xz压缩格式解压成功"
                extract_success=true
            else
                echo "❌ 所有解压方式都失败"
            fi
        fi
    fi
fi

echo "------------------------------------------"

if [ "$extract_success" = false ]; then
    echo "❌ 项目文件解压失败！"
    echo "可能的原因："
    echo "- 文件损坏或格式不正确"
    echo "- 不是有效的LAOLIPEF项目文件"
    echo "- 不支持的文件压缩格式"
    exit 1
fi

echo "步骤4: 分析安装结果..."
echo "------------------------------------------"

# 显示详细的文件树
echo "安装目录结构:"
echo "------------------------------------------"
if command -v tree >/dev/null 2>&1; then
    tree "$INSTALL_DIR" -L 3
else
    find "$INSTALL_DIR" -type f | head -20
    echo "... (更多文件)"
fi

echo "------------------------------------------"

# 统计信息
total_files=$(find "$INSTALL_DIR" -type f | wc -l)
total_dirs=$(find "$INSTALL_DIR" -type d | wc -l)
install_size=$(du -sh "$INSTALL_DIR" | cut -f1)

echo "安装统计:"
echo "- 文件数量: $total_files 个"
echo "- 目录数量: $total_dirs 个"
echo "- 安装大小: $install_size"
echo ""

# 检查常见的LAOLIPEF项目文件
echo "项目文件检查:"
if [ -f "$INSTALL_DIR/package.json" ]; then
    echo "✓ 找到 package.json (Node.js项目)"
fi
if [ -f "$INSTALL_DIR/requirements.txt" ]; then
    echo "✓ 找到 requirements.txt (Python项目)"
fi
if [ -f "$INSTALL_DIR/pom.xml" ]; then
    echo "✓ 找到 pom.xml (Java Maven项目)"
fi
if [ -f "$INSTALL_DIR/README.md" ]; then
    echo "✓ 找到 README.md (项目文档)"
fi
if [ -f "$INSTALL_DIR/.gitignore" ]; then
    echo "✓ 找到 .gitignore (Git配置)"
fi

echo ""
echo "步骤5: 设置文件权限..."
# 设置执行权限（如果存在可执行文件）
find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \; 2>/dev/null
find "$INSTALL_DIR" -name "*.py" -exec chmod +x {} \; 2>/dev/null
find "$INSTALL_DIR" -name "*.bin" -exec chmod +x {} \; 2>/dev/null
echo "✓ 文件权限设置完成"

echo "==============================================="
echo "🎉 LAOLIPEF项目安装完成！"
echo ""
echo "安装摘要:"
echo "- 项目文件: $filename"
echo "- 安装目录: $INSTALL_DIR"
echo "- 文件数量: $total_files 个"
echo "- 安装大小: $install_size"
echo ""
echo "下一步操作建议:"
echo "1. 查看 README.md 了解项目信息"
echo "2. 检查配置文件并进行相应配置"
echo "3. 运行项目初始化脚本(如果存在)"
echo "4. 参考项目文档进行开发"
echo ""
echo "感谢使用LAOLIPEF开发框架！"
echo "==============================================="
