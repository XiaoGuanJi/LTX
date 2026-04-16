#!/bin/bash
#
# 一键更新脚本
# 功能：检查并更新程序文件
#

# ======================
# 配置
# ======================
REPO_URL="https://github.com/XiaoGuanJi/LTX.git"
UPDATE_FILE="https://raw.githubusercontent.com/XiaoGuanJi/LTX/main/Updates/README.MD"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$SCRIPT_DIR/data"
CLONE_DIR="$DATA_DIR/Updates"
BACKUP_DIR="$DATA_DIR/backup_$(date +%Y%m%d_%H%M%S)"
TEMP_FILE="/tmp/update_check_$$.tmp"

# ======================
# 颜色定义
# ======================
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m' # 重置颜色

# ======================
# 打印函数
# ======================
print_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          程序更新检查工具                ║${NC}"
    echo -e "${CYAN}║         One-Click Updater v1.0           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo
}

print_step() {
    echo -e "${BLUE}[${YELLOW}*${BLUE}]${NC} $1"
}

print_success() {
    echo -e "${BLUE}[${GREEN}✓${BLUE}]${NC} $1"
}

print_error() {
    echo -e "${BLUE}[${RED}✗${BLUE}]${NC} $1"
}

print_warning() {
    echo -e "${BLUE}[${YELLOW}!${BLUE}]${NC} $1"
}

# ======================
# 检查工具
# ======================
check_tools() {
    print_step "检查必要的工具..."
    
    # 检查 git
    if ! command -v git &> /dev/null; then
        print_error "需要 git 工具，但未安装"
        echo "请先安装 git:"
        echo "  Ubuntu/Debian: sudo apt install git"
        echo "  CentOS/RHEL: sudo yum install git"
        echo "  macOS: brew install git"
        exit 1
    fi
    print_success "git 工具可用"
    
    # 检查 curl 或 wget
    if command -v curl &> /dev/null; then
        DOWNLOAD_TOOL="curl"
        print_success "使用 curl 下载文件"
    elif command -v wget &> /dev/null; then
        DOWNLOAD_TOOL="wget"
        print_success "使用 wget 下载文件"
    else
        print_warning "未找到 curl 或 wget，将跳过更新检查"
        DOWNLOAD_TOOL="none"
    fi
}

# ======================
# 检查更新
# ======================
check_update() {
    print_step "检查更新状态..."
    
    if [ "$DOWNLOAD_TOOL" = "none" ]; then
        print_warning "跳过在线检查，直接克隆更新"
        return 0
    fi
    
    # 下载更新配置文件
    if [ "$DOWNLOAD_TOOL" = "curl" ]; then
        curl -s -L "$UPDATE_FILE" -o "$TEMP_FILE" 2>/dev/null
    else
        wget -q "$UPDATE_FILE" -O "$TEMP_FILE" 2>/dev/null
    fi
    
    if [ $? -ne 0 ] || [ ! -s "$TEMP_FILE" ]; then
        print_warning "无法获取更新信息，继续执行克隆"
        return 0
    fi
    
    # 检查更新标记
    if grep -qi '<Updates"ok">' "$TEMP_FILE"; then
        print_success "发现新版本，准备更新"
        return 0
    elif grep -qi '<Updates"no">' "$TEMP_FILE"; then
        print_success "当前已是最新版本"
        echo
        echo -e "${GREEN}无需更新，程序退出${NC}"
        rm -f "$TEMP_FILE"
        exit 0
    else
        print_warning "更新标记格式不正确，继续执行"
        return 0
    fi
}

# ======================
# 备份当前文件
# ======================
backup_current() {
    print_step "备份当前文件..."
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    # 备份当前目录下的脚本文件
    for file in "$SCRIPT_DIR"/*.sh; do
        if [ -f "$file" ] && [ "$file" != "$0" ]; then
            cp "$file" "$BACKUP_DIR/"
            echo "  📄 备份: $(basename "$file")"
        fi
    done
    
    print_success "备份完成: $BACKUP_DIR"
}

# ======================
# 克隆仓库
# ======================
clone_repository() {
    print_step "克隆更新仓库..."
    
    # 如果已有克隆目录，先备份
    if [ -d "$CLONE_DIR" ]; then
        mv "$CLONE_DIR" "${CLONE_DIR}_old_$(date +%H%M%S)"
        print_warning "已有更新目录，已重命名备份"
    fi
    
    # 克隆仓库
    echo -e "${CYAN}正在克隆: $REPO_URL${NC}"
    echo "这可能需要几秒钟，请耐心等待..."
    echo
    
    git clone --depth 1 "$REPO_URL" "$CLONE_DIR" 2>&1 | \
        while IFS= read -r line; do
            echo "  $line"
        done
    
    if [ $? -ne 0 ]; then
        print_error "克隆失败，请检查网络连接"
        exit 1
    fi
    
    print_success "仓库克隆完成"
}

# ======================
# 显示文件位置
# ======================
show_file_locations() {
    echo
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ 更新完成！文件位置如下：${NC}"
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
    echo
    
    # 显示主要文件
    echo -e "${YELLOW}📁 更新文件存储位置：${NC}"
    echo -e "  ${BLUE}➜${NC} $CLONE_DIR"
    echo
    
    echo -e "${YELLOW}📄 关键文件：${NC}"
    
    # 检查新版本检查脚本
    if [ -f "$CLONE_DIR/Updates/Check for updates.sh" ]; then
        echo -e "  ${GREEN}✓${NC} 新检查脚本: $CLONE_DIR/Updates/Check for updates.sh"
    elif [ -f "$CLONE_DIR/Updates/check_update.sh" ]; then
        echo -e "  ${GREEN}✓${NC} 新检查脚本: $CLONE_DIR/Updates/check_update.sh"
    fi
    
    # 检查新版本主程序
    for file in "$CLONE_DIR/Updates"/*.sh; do
        if [ -f "$file" ] && [[ "$(basename "$file")" != *"check"* ]] && [[ "$(basename "$file")" != *"Check"* ]]; then
            echo -e "  ${GREEN}✓${NC} 新版本程序: $file"
        fi
    done
    
    echo
    echo -e "${YELLOW}🔧 备份文件位置：${NC}"
    echo -e "  ${BLUE}➜${NC} $BACKUP_DIR"
    
    echo
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
}

# ======================
# 复制新文件
# ======================
copy_new_files() {
    print_step "准备新版本文件..."
    
    # 如果Updates目录中有脚本文件
    if [ -d "$CLONE_DIR/Updates" ]; then
        echo "更新目录中的文件："
        echo
        
        for file in "$CLONE_DIR/Updates"/*.sh; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                echo -e "  ${CYAN}📦${NC} $filename"
                
                # 如果是检查更新脚本，复制到当前目录
                if [[ "$filename" == *"check"* ]] || [[ "$filename" == *"Check"* ]]; then
                    cp "$file" "$SCRIPT_DIR/check_update.sh"
                    chmod +x "$SCRIPT_DIR/check_update.sh"
                    echo -e "    ${GREEN}→${NC} 已复制为: $SCRIPT_DIR/check_update.sh"
                fi
            fi
        done
    fi
    
    print_success "文件准备完成"
}

# ======================
# 清理旧版本
# ======================
cleanup_old() {
    print_step "清理临时文件..."
    
    # 删除临时文件
    rm -f "$TEMP_FILE"
    
    # 提示删除旧脚本
    echo
    echo -e "${YELLOW}🗑️ 旧版本清理：${NC}"
    echo -e "  当前脚本已完成更新任务，可以安全删除"
    echo -e "  新的检查更新脚本: ${GREEN}$SCRIPT_DIR/check_update.sh${NC}"
    echo
    echo -e "  建议手动执行: ${CYAN}rm \"$0\"${NC}"
    
    print_success "清理完成"
}

# ======================
# 主函数
# ======================
main() {
    print_header
    
    # 1. 检查工具
    check_tools
    echo
    
    # 2. 检查更新
    check_update
    echo
    
    # 3. 备份当前文件
    backup_current
    echo
    
    # 4. 克隆仓库
    clone_repository
    echo
    
    # 5. 复制新文件
    copy_new_files
    echo
    
    # 6. 显示文件位置
    show_file_locations
    echo
    
    # 7. 清理
    cleanup_old
    echo
    
    # 完成提示
    echo -e "${GREEN}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ 更新流程完成！${NC}"
    echo -e "${GREEN}══════════════════════════════════════════${NC}"
    echo
    echo -e "下一步操作建议："
    echo -e "1. ${CYAN}查看新文件${NC}: ls -la \"$CLONE_DIR/\""
    echo -e "2. ${CYAN}运行新检查脚本${NC}: ./check_update.sh"
    echo -e "3. ${CYAN}删除旧脚本${NC}: rm \"$0\""
    echo
    echo -e "${YELLOW}按回车键退出...${NC}"
    read -r
}

# ======================
# 启动程序
# ======================
main "$@"
