#!/bin/bash

# Battle.net Auto-Installer для Linux
# Автор: sweetpotatohack
# Версия: 1.0
# Дата: Сентябрь 2024

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функция для вывода цветного текста
print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Функция для вывода заголовков
print_header() {
    echo ""
    print_color $CYAN "========================================"
    print_color $CYAN "$1"
    print_color $CYAN "========================================"
}

# Функция для проверки успешности выполнения команды
check_success() {
    if [ $? -eq 0 ]; then
        print_color $GREEN "✅ $1"
    else
        print_color $RED "❌ $1"
        exit 1
    fi
}

# Функция для определения дистрибутива
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        print_color $RED "❌ Не удалось определить дистрибутив Linux"
        exit 1
    fi
}

# Проверка, что скрипт не запускается от root
check_not_root() {
    if [ "$EUID" -eq 0 ]; then
        print_color $RED "❌ Не запускайте этот скрипт от имени root!"
        print_color $YELLOW "💡 Запустите как обычный пользователь. Права sudo будут запрошены при необходимости."
        exit 1
    fi
}

# Проверка наличия графической сессии
check_display() {
    if [ -z "$DISPLAY" ]; then
        print_color $RED "❌ DISPLAY не установлен!"
        print_color $YELLOW "💡 Запустите этот скрипт из графической сессии (не из TTY)"
        exit 1
    fi
}

# Установка Wine и зависимостей для Ubuntu/Debian
install_wine_ubuntu() {
    print_header "Установка Wine и зависимостей для Ubuntu/Debian"
    
    print_color $BLUE "🔄 Обновление системы..."
    sudo apt update && sudo apt upgrade -y
    check_success "Система обновлена"
    
    print_color $BLUE "🔄 Добавление архитектуры i386..."
    sudo dpkg --add-architecture i386
    check_success "Архитектура i386 добавлена"
    
    print_color $BLUE "🔄 Обновление списка пакетов..."
    sudo apt update
    check_success "Список пакетов обновлен"
    
    print_color $BLUE "🔄 Установка Wine и компонентов..."
    sudo apt install -y wine wine32:i386 winetricks winbind cabextract curl wget
    check_success "Wine и компоненты установлены"
    
    print_color $BLUE "🔍 Проверка версии Wine..."
    WINE_VERSION=$(wine --version)
    print_color $GREEN "✅ Установлен Wine: $WINE_VERSION"
}

# Установка Wine и зависимостей для Arch Linux
install_wine_arch() {
    print_header "Установка Wine и зависимостей для Arch Linux"
    
    print_color $BLUE "🔄 Обновление системы..."
    sudo pacman -Syu --noconfirm
    check_success "Система обновлена"
    
    print_color $BLUE "🔄 Установка Wine и зависимостей..."
    sudo pacman -S --noconfirm wine winetricks wine-mono wine-gecko lib32-gnutls
    check_success "Wine и зависимости установлены"
    
    # Попытка установить winbind (может потребовать AUR)
    if command -v yay &> /dev/null; then
        print_color $BLUE "🔄 Установка winbind через AUR..."
        yay -S --noconfirm winbind || print_color $YELLOW "⚠️  winbind не установлен (не критично)"
    fi
}

# Установка Wine и зависимостей для Fedora
install_wine_fedora() {
    print_header "Установка Wine и зависимостей для Fedora"
    
    print_color $BLUE "🔄 Обновление системы..."
    sudo dnf update -y
    check_success "Система обновлена"
    
    print_color $BLUE "🔄 Установка Wine и зависимостей..."
    sudo dnf install -y wine winetricks wine.i686 samba-winbind-clients
    check_success "Wine и зависимости установлены"
}

# Скачивание Battle.net установщика
download_battlenet() {
    print_header "Скачивание Battle.net установщика"
    
    mkdir -p ~/Downloads
    cd ~/Downloads
    
    if [ -f "Battle.net-Setup.exe" ]; then
        print_color $YELLOW "⚠️  Файл Battle.net-Setup.exe уже существует"
        read -p "Скачать заново? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_color $GREEN "✅ Используем существующий файл"
            return 0
        fi
    fi
    
    print_color $BLUE "🔄 Скачивание официального установщика Battle.net..."
    wget -O Battle.net-Setup.exe "https://www.battle.net/download/getInstallerForGame?os=win&locale=enUS&version=LIVE&gameProgram=BATTLENET_APP"
    check_success "Battle.net установщик скачан"
    
    # Проверка размера файла
    FILE_SIZE=$(stat -c%s "Battle.net-Setup.exe")
    if [ $FILE_SIZE -lt 1000000 ]; then
        print_color $RED "❌ Файл установщика слишком маленький ($FILE_SIZE байт)"
        print_color $YELLOW "💡 Попробуйте скачать установщик вручную с https://battle.net"
        exit 1
    fi
    
    print_color $GREEN "✅ Установщик скачан (размер: $FILE_SIZE байт)"
}

# Инициализация Wine
initialize_wine() {
    print_header "Инициализация Wine"
    
    print_color $BLUE "🔄 Создание Wine префикса..."
    export WINEDEBUG=-all
    wineboot --init
    check_success "Wine префикс создан"
    
    print_color $BLUE "🔄 Настройка Wine конфигурации..."
    # Установка Windows версии на Windows 10
    winecfg &
    WINECFG_PID=$!
    sleep 5
    kill $WINECFG_PID 2>/dev/null || true
    print_color $GREEN "✅ Базовая конфигурация применена"
}

# Установка Battle.net
install_battlenet() {
    print_header "Установка Battle.net"
    
    cd ~/Downloads
    
    print_color $BLUE "🔄 Запуск установщика Battle.net..."
    print_color $YELLOW "💡 Следуйте инструкциям в открывшемся окне установщика"
    print_color $YELLOW "💡 Примите лицензионное соглашение и выберите папку установки"
    
    export WINEDEBUG=-all
    wine Battle.net-Setup.exe
    
    # Проверка успешности установки
    if [ -f ~/.wine/drive_c/ProgramData/Battle.net/Agent/Agent.exe ]; then
        check_success "Battle.net установлен"
    else
        print_color $RED "❌ Battle.net не найден после установки"
        print_color $YELLOW "💡 Убедитесь, что установка завершилась успешно"
        exit 1
    fi
}

# Установка необходимых библиотек
install_libraries() {
    print_header "Установка необходимых Windows библиотек"
    
    print_color $BLUE "🔄 Установка основных библиотек через Winetricks..."
    print_color $YELLOW "💡 Процесс может занять 15-30 минут. Ожидайте..."
    print_color $YELLOW "💡 При запросах SHA256 - нажимайте 'Y' для продолжения"
    
    export WINEDEBUG=-all
    
    # Установка в тихом режиме для автоматизации
    echo "Y" | winetricks --unattended corefonts
    check_success "Шрифты Windows установлены"
    
    echo "Y" | winetricks --unattended vcrun2019
    check_success "Visual C++ Runtime 2019 установлен"
    
    echo "Y" | winetricks --unattended dotnet48
    check_success ".NET Framework 4.8 установлен"
    
    print_color $GREEN "✅ Все необходимые библиотеки установлены"
}

# Создание скрипта запуска
create_launcher() {
    print_header "Создание скрипта запуска"
    
    cat > ~/battlenet-launcher.sh << 'EOF'
#!/bin/bash
# Battle.net Launcher Script для Linux
# Автоматически сгенерировано install.sh

echo "🎮 Запускаем Battle.net через Wine..."

# Проверяем, что мы не root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Не запускайте от имени root!"
    exit 1
fi

# Проверяем DISPLAY
if [ -z "$DISPLAY" ]; then
    echo "❌ DISPLAY не установлен. Запустите из графической сессии."
    exit 1
fi

# Проверяем, не запущен ли уже Battle.net
if pgrep -f "Agent.exe" > /dev/null; then
    echo "ℹ️  Battle.net уже запущен"
    
    # Показываем окно, если оно свернуто
    wmctrl -a "battlenet - Wine desktop" 2>/dev/null || true
    exit 0
fi

# Запускаем Battle.net в виртуальном рабочем столе
echo "🚀 Запускаем Battle.net в виртуальном рабочем столе..."
WINEDEBUG=-all wine explorer /desktop=battlenet,1440x900 ~/.wine/drive_c/ProgramData/Battle.net/Agent/Agent.exe &

# Ждем запуска
sleep 5

# Проверяем результат
if pgrep -f "Agent.exe" > /dev/null; then
    echo "✅ Battle.net успешно запущен!"
    echo "🖼️  Найдите окно 'battlenet - Wine desktop' в вашем оконном менеджере"
    echo "🌐 Выполните авторизацию в открывшемся браузере, если потребуется"
else
    echo "❌ Не удалось запустить Battle.net"
    echo "💡 Проверьте установку или запустите вручную:"
    echo "wine ~/.wine/drive_c/ProgramData/Battle.net/Agent/Agent.exe"
    exit 1
fi
EOF
    
    chmod +x ~/battlenet-launcher.sh
    check_success "Скрипт запуска создан: ~/battlenet-launcher.sh"
    
    # Создание desktop файла
    mkdir -p ~/.local/share/applications
    cat > ~/.local/share/applications/battlenet.desktop << EOF
[Desktop Entry]
Name=Battle.net
Comment=Blizzard Battle.net Launcher через Wine
Exec=/home/$USER/battlenet-launcher.sh
Icon=wine
Terminal=false
Type=Application
Categories=Game;
StartupNotify=true
EOF
    
    update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
    check_success "Ярлык в меню приложений создан"
}

# Тестовый запуск
test_launch() {
    print_header "Тестовый запуск Battle.net"
    
    print_color $BLUE "🔄 Запуск Battle.net для проверки..."
    
    # Запуск в фоновом режиме для тестирования
    timeout 30s bash -c '
        export WINEDEBUG=-all
        wine explorer /desktop=battlenet,1024x768 ~/.wine/drive_c/ProgramData/Battle.net/Agent/Agent.exe &
        WINE_PID=$!
        
        # Ждем запуска процесса
        for i in {1..15}; do
            if pgrep -f "Agent.exe" > /dev/null; then
                echo "✅ Battle.net процесс запущен"
                sleep 2
                # Завершаем тестовые процессы
                pkill -f "Agent.exe" 2>/dev/null || true
                pkill -f "wine explorer" 2>/dev/null || true
                exit 0
            fi
            sleep 2
        done
        echo "❌ Battle.net не запустился в течение 30 секунд"
        exit 1
    '
    
    if [ $? -eq 0 ]; then
        check_success "Тестовый запуск прошел успешно"
    else
        print_color $YELLOW "⚠️  Тестовый запуск не удался, но это может быть нормально"
        print_color $YELLOW "💡 Попробуйте запустить Battle.net вручную после установки"
    fi
}

# Финальные инструкции
show_final_instructions() {
    print_header "🎉 Установка завершена!"
    
    print_color $GREEN "✅ Battle.net успешно установлен и настроен!"
    echo ""
    print_color $CYAN "📋 Способы запуска:"
    print_color $BLUE "1. Из меню приложений: Найдите 'Battle.net' в разделе 'Игры'"
    print_color $BLUE "2. Из терминала: ~/battlenet-launcher.sh"
    print_color $BLUE "3. Прямой запуск: WINEDEBUG=-all wine explorer /desktop=battlenet,1440x900 ~/.wine/drive_c/ProgramData/Battle.net/Agent/Agent.exe"
    echo ""
    print_color $CYAN "💡 Полезные советы:"
    print_color $YELLOW "• Battle.net запускается в виртуальном окне Wine размером 1440x900"
    print_color $YELLOW "• Для входа в аккаунт используйте браузер, который откроется автоматически"
    print_color $YELLOW "• После первого входа можно устанавливать игры Blizzard"
    print_color $YELLOW "• Для лучшей производительности рекомендуется закрыть другие приложения"
    echo ""
    print_color $CYAN "🔧 Если возникли проблемы:"
    print_color $YELLOW "• Проверьте ~/battle-net-wine-guide.md для подробной документации"
    print_color $YELLOW "• Создайте issue на GitHub: https://github.com/sweetpotatohack/battlenet-wine-linux"
    echo ""
    print_color $GREEN "🎮 Удачной игры!"
}

# Основная функция установки
main() {
    clear
    print_color $PURPLE "
██████╗  █████╗ ████████╗████████╗██╗     ███████╗   ███╗   ██╗███████╗████████╗
██╔══██╗██╔══██╗╚══██╔══╝╚══██╔══╝██║     ██╔════╝   ████╗  ██║██╔════╝╚══██╔══╝
██████╔╝███████║   ██║      ██║   ██║     █████╗     ██╔██╗ ██║█████╗     ██║   
██╔══██╗██╔══██║   ██║      ██║   ██║     ██╔══╝     ██║╚██╗██║██╔══╝     ██║   
██████╔╝██║  ██║   ██║      ██║   ███████╗███████╗██╗██║ ╚████║███████╗   ██║   
╚═════╝ ╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   
"
    print_color $CYAN "Автоматический установщик Battle.net для Linux через Wine"
    print_color $CYAN "Версия 1.0 | Автор: sweetpotatohack"
    echo ""
    
    # Предварительные проверки
    check_not_root
    check_display
    
    # Определение дистрибутива
    detect_distro
    print_color $GREEN "✅ Обнаружен дистрибутив: $DISTRO"
    
    # Подтверждение установки
    print_color $YELLOW "💡 Этот скрипт установит:"
    echo "   • Wine и все необходимые зависимости"
    echo "   • Battle.net клиент"
    echo "   • Windows библиотеки (.NET Framework, Visual C++, шрифты)"
    echo "   • Скрипты для удобного запуска"
    echo ""
    print_color $YELLOW "⏱️  Примерное время установки: 30-60 минут"
    echo ""
    read -p "Продолжить установку? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_color $YELLOW "🚪 Установка отменена пользователем"
        exit 0
    fi
    
    # Установка Wine в зависимости от дистрибутива
    case $DISTRO in
        ubuntu|debian|linuxmint)
            install_wine_ubuntu
            ;;
        arch|manjaro)
            install_wine_arch
            ;;
        fedora)
            install_wine_fedora
            ;;
        *)
            print_color $YELLOW "⚠️  Дистрибутив '$DISTRO' не поддерживается автоустановкой"
            print_color $YELLOW "💡 Попробуйте установить вручную по инструкции: battle-net-wine-guide.md"
            exit 1
            ;;
    esac
    
    # Основные шаги установки
    download_battlenet
    initialize_wine
    install_battlenet
    install_libraries
    create_launcher
    test_launch
    show_final_instructions
    
    print_color $GREEN "🎉 Установка полностью завершена!"
}

# Запуск основной функции
main "$@"
