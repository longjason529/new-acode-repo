#!/usr/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Error handling
set -e
trap 'log_error "Script failed on line $LINENO"' ERR

# =====================================================
# 1. CHECK PREREQUISITES
# =====================================================
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Java
    if ! command -v java &> /dev/null; then
        log_error "Java is not installed. Please install JDK 11 or higher."
        exit 1
    fi
    JAVA_VERSION=$(java -version 2>&1 | grep "version" | head -1)
    log_success "Java found: $JAVA_VERSION"
    
    # Check Gradle
    if ! command -v gradle &> /dev/null; then
        log_error "Gradle is not installed. Please install Gradle."
        exit 1
    fi
    GRADLE_VERSION=$(gradle --version | head -1)
    log_success "Gradle found: $GRADLE_VERSION"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed. Please install Node.js."
        exit 1
    fi
    NODE_VERSION=$(node --version)
    log_success "Node.js found: $NODE_VERSION"
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed. Please install npm."
        exit 1
    fi
    NPM_VERSION=$(npm --version)
    log_success "npm found: $NPM_VERSION"
}

# =====================================================
# 2. BUILD JAVA/GRADLE PROJECT
# =====================================================
build_gradle_project() {
    log_info "Building Java/Gradle project..."
    
    if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        gradle clean build --no-daemon
        log_success "Gradle build completed successfully"
    else
        log_warning "No build.gradle or build.gradle.kts found. Skipping Gradle build."
    fi
}

# =====================================================
# 3. SETUP NODE.JS DEPENDENCIES
# =====================================================
setup_nodejs() {
    log_info "Setting up Node.js dependencies..."
    
    if [ -f "package.json" ]; then
        npm install
        log_success "Node.js dependencies installed successfully"
    else
        log_warning "No package.json found. Skipping npm setup."
    fi
}

# =====================================================
# 4. START SERVICES/SERVERS
# =====================================================
start_services() {
    log_info "Starting services..."
    
    # Start Java application
    if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        log_info "Starting Java application in background..."
        gradle run --no-daemon &
        JAVA_PID=$!
        log_success "Java application started with PID: $JAVA_PID"
    fi
    
    # Start Node.js application
    if [ -f "package.json" ] && [ -f "server.js" ]; then
        log_info "Starting Node.js server in background..."
        npm start &
        NODE_PID=$!
        log_success "Node.js server started with PID: $NODE_PID"
    elif [ -f "package.json" ]; then
        log_warning "package.json found but no server.js. To start Node.js, run 'npm start' manually."
    fi
    
    log_info "Services are now running. Press Ctrl+C to stop."
}

# =====================================================
# 5. RUN TESTS
# =====================================================
run_tests() {
    log_info "Running tests..."
    
    # Run Gradle tests
    if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        log_info "Running Gradle/Java tests..."
        gradle test --no-daemon || log_warning "Some Gradle tests failed"
    fi
    
    # Run Node.js tests
    if [ -f "package.json" ]; then
        if grep -q "\"test\"" package.json; then
            log_info "Running Node.js tests..."
            npm test || log_warning "Some Node.js tests failed"
        else
            log_warning "No test script found in package.json"
        fi
    fi
    
    log_success "Test execution completed"
}

# =====================================================
# MAIN MENU
# =====================================================
show_menu() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}       Application Menu${NC}"
    echo -e "${BLUE}================================${NC}"
    echo "1. Check prerequisites"
    echo "2. Build Gradle project"
    echo "3. Setup Node.js dependencies"
    echo "4. Run tests"
    echo "5. Start services"
    echo "6. Full setup (1-5)"
    echo "7. Exit"
    echo -e "${BLUE}================================${NC}\n"
}

# =====================================================
# EXECUTE BASED ON ARGUMENT
# =====================================================
case "${1:-0}" in
    check)
        check_prerequisites
        ;;
    build)
        build_gradle_project
        ;;
    setup-node)
        setup_nodejs
        ;;
    test)
        run_tests
        ;;
    start)
        start_services
        ;;
    full)
        check_prerequisites
        build_gradle_project
        setup_nodejs
        run_tests
        start_services
        ;;
    interactive|"")
        while true; do
            show_menu
            read -p "Enter your choice: " choice
            case $choice in
                1) check_prerequisites ;;  
                2) build_gradle_project ;;  
                3) setup_nodejs ;;  
                4) run_tests ;;  
                5) start_services ;;  
                6) 
                    check_prerequisites
                    build_gradle_project
                    setup_nodejs
                    run_tests
                    start_services
                    ;;  
                7) 
                    log_info "Exiting application"
                    exit 0
                    ;;  
                *)
                    log_error "Invalid choice. Please try again."
                    ;;
            esac
        done
        ;;
    *)
        log_error "Unknown argument: $1"
        echo "Usage: $0 {check|build|setup-node|test|start|full|interactive}"
        exit 1
        ;;
esac

log_success "Application execution completed"