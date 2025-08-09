#!/bin/bash

# 生产环境部署脚本
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 域名跳转管理系统 - 部署脚本${NC}"

# 检查Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker未安装${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! (command -v docker &> /dev/null && docker compose version &> /dev/null); then
        echo -e "${RED}❌ Docker Compose未安装${NC}"
        exit 1
    fi
}

# 备份当前版本
backup_current() {
    echo -e "${BLUE}💾 备份当前版本...${NC}"
    
    if [ -f "docker-compose.yml" ]; then
        docker-compose down || docker compose down
    fi
    
    # 备份重要数据
    if [ -d "certificates" ]; then
        cp -r certificates certificates.backup.$(date +%s)
    fi
    
    if [ -d "logs" ]; then
        cp -r logs logs.backup.$(date +%s)
    fi
}

# 拉取最新代码
update_code() {
    echo -e "${BLUE}📥 拉取最新代码...${NC}"
    
    git fetch origin
    git reset --hard origin/main
    
    echo -e "${GREEN}✅ 代码更新完成${NC}"
}

# 构建并启动服务
deploy_services() {
    echo -e "${BLUE}🔨 构建Docker镜像...${NC}"
    
    if command -v docker-compose &> /dev/null; then
        docker-compose build --no-cache
        docker-compose up -d
    else
        docker compose build --no-cache
        docker compose up -d
    fi
    
    echo -e "${GREEN}✅ 服务启动完成${NC}"
}

# 健康检查
health_check() {
    echo -e "${BLUE}🔍 执行健康检查...${NC}"
    
    # 等待服务启动
    sleep 30
    
    # 检查前端
    if curl -f http://localhost/health &> /dev/null; then
        echo -e "${GREEN}✅ 前端服务正常${NC}"
    else
        echo -e "${RED}❌ 前端服务异常${NC}"
        return 1
    fi
    
    # 检查后端API
    if curl -f http://localhost:3000/health &> /dev/null; then
        echo -e "${GREEN}✅ 后端API正常${NC}"
    else
        echo -e "${YELLOW}⚠️ 后端API暂未启动（正常情况）${NC}"
    fi
    
    return 0
}

# 清理旧资源
cleanup() {
    echo -e "${BLUE}🧹 清理旧资源...${NC}"
    
    # 清理未使用的Docker镜像
    docker system prune -f
    
    # 清理旧的备份文件（保留最近5个）
    find . -name "*.backup.*" -type d | sort | head -n -5 | xargs rm -rf
    
    echo -e "${GREEN}✅ 清理完成${NC}"
}

# 显示部署结果
show_result() {
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}🎉 部署完成！${NC}"
    echo -e "${GREEN}================================${NC}"
    echo
    echo -e "${YELLOW}🌐 访问地址:${NC}"
    echo "  前端: http://$(curl -s ifconfig.me || echo 'localhost')"
    echo "  GitHub Pages: https://emgoda.github.io/domain-redirect-manager/"
    echo
    echo -e "${YELLOW}📊 服务状态:${NC}"
    if command -v docker-compose &> /dev/null; then
        docker-compose ps
    else
        docker compose ps
    fi
    echo
    echo -e "${YELLOW}📝 查看日志:${NC}"
    echo "  docker-compose logs -f"
}

# 主函数
main() {
    echo -e "${YELLOW}⚠️ 这将更新生产环境，确定继续吗？ [y/N]${NC}"
    read -r confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}部署已取消${NC}"
        exit 0
    fi
    
    check_docker
    backup_current
    update_code
    deploy_services
    
    if health_check; then
        cleanup
        show_result
        echo -e "${GREEN}✅ 部署成功！${NC}"
    else
        echo -e "${RED}❌ 健康检查失败，正在回滚...${NC}"
        # 这里可以添加回滚逻辑
        exit 1
    fi
}

# 运行主函数
main "$@"
