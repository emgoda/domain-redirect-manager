#!/bin/bash

# 域名跳转管理系统 - 一键安装脚本
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 域名跳转管理系统 - 安装脚本${NC}"
echo "=================================="

# 检查系统
check_system() {
    echo -e "${GREEN}📋 检查系统环境...${NC}"
    
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git未安装${NC}"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}⚠️ Docker未安装，将安装基础版本${NC}"
    fi
    
    echo -e "${GREEN}✅ 系统检查通过${NC}"
}

# 下载项目
download_project() {
    echo -e "${GREEN}📥 下载项目文件...${NC}"
    
    if [ -d "domain-redirect-manager" ]; then
        echo -e "${YELLOW}⚠️ 项目目录已存在，正在备份...${NC}"
        mv domain-redirect-manager domain-redirect-manager.backup.$(date +%s)
    fi
    
    git clone https://github.com/emgoda/domain-redirect-manager.git
    cd domain-redirect-manager
    
    echo -e "${GREEN}✅ 项目下载完成${NC}"
}

# 配置环境
setup_environment() {
    echo -e "${GREEN}⚙️ 配置环境...${NC}"
    
    # 创建环境变量文件
    if [ ! -f ".env" ]; then
        cp .env.example .env
        echo -e "${YELLOW}📝 请编辑 .env 文件配置您的参数${NC}"
    fi
    
    # 创建必要目录
    mkdir -p certificates logs
    chmod 755 certificates logs
    
    echo -e "${GREEN}✅ 环境配置完成${NC}"
}

# Docker部署
deploy_docker() {
    echo -e "${GREEN}🐳 使用Docker部署...${NC}"
    
    if command -v docker-compose &> /dev/null; then
        docker-compose up -d
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        docker compose up -d
    else
        echo -e "${RED}❌ Docker Compose未找到${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Docker部署完成${NC}"
}

# 传统部署
deploy_traditional() {
    echo -e "${GREEN}📦 传统部署方式...${NC}"
    
    # 安装Node.js依赖
    if command -v npm &> /dev/null; then
        npm install
        echo -e "${GREEN}✅ 依赖安装完成${NC}"
    else
        echo -e "${YELLOW}⚠️ Node.js未安装，跳过依赖安装${NC}"
    fi
    
    # 启动简单HTTP服务器
    if command -v python3 &> /dev/null; then
        echo -e "${GREEN}🌐 启动HTTP服务器...${NC}"
        echo -e "${YELLOW}访问: http://localhost:8000${NC}"
        python3 -m http.server 8000
    elif command -v python &> /dev/null; then
        echo -e "${GREEN}🌐 启动HTTP服务器...${NC}"
        echo -e "${YELLOW}访问: http://localhost:8000${NC}"
        python -m SimpleHTTPServer 8000
    else
        echo -e "${GREEN}✅ 文件已准备就绪${NC}"
        echo -e "${YELLOW}请使用Web服务器指向当前目录${NC}"
    fi
}

# 显示完成信息
show_completion() {
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}🎉 安装完成！${NC}"
    echo -e "${GREEN}================================${NC}"
    echo
    echo -e "${YELLOW}📊 访问地址:${NC}"
    echo "  本地: http://localhost:8000"
    echo "  GitHub: https://emgoda.github.io/domain-redirect-manager/"
    echo
    echo -e "${YELLOW}🔐 默认账号:${NC}"
    echo "  用户名: admin"
    echo "  密码: admin123"
    echo
    echo -e "${YELLOW}📁 项目目录: $(pwd)${NC}"
    echo -e "${YELLOW}📝 配置文件: $(pwd)/.env${NC}"
}

# 主函数
main() {
    check_system
    download_project
    setup_environment
    
    # 询问部署方式
    echo -e "${YELLOW}选择部署方式:${NC}"
    echo "1) Docker部署 (推荐)"
    echo "2) 传统部署"
    read -p "请选择 [1-2]: " choice
    
    case $choice in
        1)
            deploy_docker
            ;;
        2)
            deploy_traditional
            ;;
        *)
            echo -e "${RED}无效选择，使用传统部署${NC}"
            deploy_traditional
            ;;
    esac
    
    show_completion
}

# 运行主函数
main "$@"
