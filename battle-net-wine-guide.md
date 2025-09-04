# 🎮 Полное руководство по установке Battle.net через Wine на Linux

## 📋 Содержание
- [Системные требования](#системные-требования)
- [Установка Wine и зависимостей](#установка-wine-и-зависимостей)
- [Скачивание установщика Battle.net](#скачивание-установщика-battlenet)
- [Установка Battle.net](#установка-battlenet)
- [Установка необходимых библиотек](#установка-необходимых-библиотек)
- [Запуск Battle.net](#запуск-battlenet)
- [Создание скриптов для удобства](#создание-скриптов-для-удобства)
- [Решение проблем](#решение-проблем)
- [Дополнительные настройки](#дополнительные-настройки)

## 🖥️ Системные требования

### Поддерживаемые дистрибутивы:
- Ubuntu 20.04+ / Linux Mint 20+
- Debian 10+
- Arch Linux / Manjaro
- Fedora 33+
- openSUSE Leap 15.3+

### Минимальные требования:
- 4 GB RAM
- 10 GB свободного места на диске
- Графическая карта с поддержкой OpenGL 3.0+
- X11 или Wayland (с XWayland)

## 🔧 Установка Wine и зависимостей

### Ubuntu/Debian:

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Добавление архитектуры i386 для 32-битной поддержки
sudo dpkg --add-architecture i386

# Обновление списка пакетов
sudo apt update

# Установка Wine и необходимых компонентов
sudo apt install wine wine32:i386 winetricks winbind cabextract -y

# Проверка версии Wine
wine --version
```

### Arch Linux/Manjaro:

```bash
# Включение multilib репозитория (если не включен)
sudo nano /etc/pacman.conf
# Раскомментируйте строки:
# [multilib]
# Include = /etc/pacman.d/mirrorlist

# Обновление системы
sudo pacman -Syu

# Установка Wine и зависимостей
sudo pacman -S wine winetricks wine-mono wine-gecko lib32-gnutls

# Установка дополнительных пакетов
yay -S winbind # или из AUR
```

### Fedora:

```bash
# Обновление системы
sudo dnf update -y

# Установка Wine и зависимостей
sudo dnf install wine winetricks wine.i686 -y

# Установка дополнительных компонентов
sudo dnf install samba-winbind-clients -y
```

## 📥 Скачивание установщика Battle.net

### Способ 1: Через wget

```bash
# Создание папки для загрузок (если не существует)
mkdir -p ~/Downloads

# Скачивание официального установщика Battle.net
cd ~/Downloads
wget -O Battle.net-Setup.exe "https://www.battle.net/download/getInstallerForGame?os=win&locale=enUS&version=LIVE&gameProgram=BATTLENET_APP"
```

### Способ 2: Ручное скачивание

1. Перейдите на официальный сайт: https://www.battle.net/
2. Нажмите "Download for Windows"
3. Сохраните файл как `Battle.net-Setup.exe` в папку `~/Downloads`

## 🛠️ Установка Battle.net

### Шаг 1: Инициализация Wine

```bash
# Создание Wine префикса (если не существует)
winecfg
# В открывшемся окне выберите "OK" для создания базовой конфигурации
```

### Шаг 2: Запуск установщика

```bash
# Переход в папку с установщиком
cd ~/Downloads

# Проверка наличия файла
ls -la Battle.net-Setup.exe

# Запуск установщика Battle.net
wine Battle.net-Setup.exe
```

**Важно:** Если появляется ошибка о wine32, выполните:

```bash
sudo apt-get install wine32:i386
```

### Шаг 3: Следование инструкциям установщика

- Примите лицензионное соглашение
- Выберите папку установки (оставьте по умолчанию)
- Дождитесь завершения установки

## 📚 Установка необходимых библиотек

Для корректной работы Battle.net необходимо установить дополнительные Windows библиотеки:

```bash
# Установка основных компонентов
winetricks corefonts vcrun2019 dotnet48

# В процессе установки:
# 1. При установке vcrun2019 - нажмите "Y" при предупреждении о SHA256
# 2. При установке dotnet48 - дождитесь завершения (может занять 10-15 минут)
# 3. Согласитесь со всеми лицензионными соглашениями
```

### Дополнительные полезные библиотеки (опционально):

```bash
# Для лучшей совместимости
winetricks d3dx9 d3dx10 d3dx11_43 dxvk

# Для улучшения производительности графики
winetricks vulkan-1
```

## 🚀 Запуск Battle.net

### Способ 1: Стандартный запуск

```bash
wine ~/.wine/drive_c/ProgramData/Battle.net/Agent/Agent.exe
```

### Способ 2: Запуск в виртуальном рабочем столе (рекомендуется)

```bash
# Запуск в виртуальном окне 1024x768
WINEDEBUG=-all wine explorer /desktop=battlenet,1024x768 ~/.wine/drive_c/ProgramData/Battle.net/Agent/Agent.exe &

# Запуск в виртуальном окне 1440x900 (больший размер)
WINEDEBUG=-all wine explorer /desktop=battlenet,1440x900 ~/.wine/drive_c/ProgramData/Battle.net/Agent/Agent.exe &

# Полноэкранный виртуальный рабочий стол
WINEDEBUG=-all wine explorer /desktop=battlenet,1920x1080 ~/.wine/drive_c/ProgramData/Battle.net/Agent/Agent.exe &
```

## 📝 Создание скриптов для удобства

### Создание скрипта запуска:

```bash
# Создание скрипта
cat > ~/battlenet-launcher.sh << 'EOF'
#!/bin/bash
# Battle.net Launcher Script для Linux
# Автор: sweetpotatohack

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
    echo "💡 Проверьте логи или попробуйте переустановить"
    exit 1
fi
EOF

# Делаем скрипт исполняемым
chmod +x ~/battlenet-launcher.sh

# Запуск скрипта
~/battlenet-launcher.sh
```

### Создание desktop файла для меню приложений:

```bash
# Создание .desktop файла
cat > ~/.local/share/applications/battlenet.desktop << 'EOF'
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

# Обновление базы данных приложений
update-desktop-database ~/.local/share/applications/
```

## 🔧 Решение проблем

### Проблема: "wine32 is missing"

```bash
# Решение
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install wine32:i386
```

### Проблема: "apartment not initialised"

Это предупреждение Wine, не влияет на работу приложения. Для подавления:

```bash
export WINEDEBUG=-all
```

### Проблема: Battle.net не отображается

```bash
# Принудительный запуск в виртуальном рабочем столе
WINEDEBUG=-all wine explorer /desktop=battlenet,1024x768 ~/.wine/drive_c/ProgramData/Battle.net/Agent/Agent.exe
```

### Проблема: Медленная работа или графические артефакты

```bash
# Установка DXVK для лучшей производительности DirectX
winetricks dxvk

# Или включение программного рендеринга
export MESA_GL_VERSION_OVERRIDE=3.3
export MESA_GLSL_VERSION_OVERRIDE=330
```

### Проблема: Не работает звук

```bash
# Установка PulseAudio support для Wine
sudo apt install pulseaudio wine-pulse
# или для старых систем:
sudo apt install wine-alsa
```

### Проблема: Ошибки сети/подключения

```bash
# Установка дополнительных сетевых библиотек
winetricks wininet winhttp

# Очистка DNS кэша Wine
wine ipconfig /flushdns
```

## ⚙️ Дополнительные настройки

### Настройка производительности:

```bash
# Увеличение лимитов для Wine
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Настройка переменных окружения для производительности
export WINE_CPU_TOPOLOGY=8:2  # 8 ядер, 2 потока (настройте под свою систему)
export WINEDEBUG=-all
```

### Настройка Wine для Battle.net:

```bash
# Запуск Wine конфигуратора
winecfg

# В открывшемся окне:
# 1. На вкладке "Applications" выберите "Windows Version": Windows 10
# 2. На вкладке "Graphics" можете включить "Automatically capture the mouse in full-screen windows"
# 3. На вкладке "Audio" выберите правильный драйвер (обычно ALSA или PulseAudio)
```

### Создание отдельного Wine префикса для Battle.net (продвинутый способ):

```bash
# Создание отдельного префикса
export WINEPREFIX=~/.wine-battlenet
winecfg

# Установка в новый префикс
cd ~/Downloads
WINEPREFIX=~/.wine-battlenet wine Battle.net-Setup.exe

# Установка библиотек в новый префикс
WINEPREFIX=~/.wine-battlenet winetricks corefonts vcrun2019 dotnet48

# Запуск из отдельного префикса
WINEPREFIX=~/.wine-battlenet wine explorer /desktop=battlenet,1440x900 ~/.wine-battlenet/drive_c/ProgramData/Battle.net/Agent/Agent.exe
```

## 📊 Проверка установки

### Команды для диагностики:

```bash
# Проверка версии Wine
wine --version

# Проверка архитектуры Wine
wine64 --version
file $(which wine)

# Проверка установленных библиотек
ls ~/.wine/drive_c/windows/system32/ | grep -E "(msvc|vcrun|dotnet)"

# Проверка запущенных процессов Battle.net
ps aux | grep -i battle

# Проверка открытых окон Wine
xwininfo -root -children | grep -i battle
```

## 🎯 Финальные шаги

1. **Запустите Battle.net** используя созданный скрипт
2. **Выполните авторизацию** в открывшемся браузере
3. **Установите игры** через интерфейс Battle.net
4. **Настройте параметры** игр при необходимости

## 📞 Поддержка

Если у вас возникли проблемы:

1. Проверьте логи Wine: `~/.wine/drive_c/ProgramData/Battle.net/`
2. Убедитесь, что все библиотеки установлены
3. Попробуйте переустановить Battle.net
4. Создайте issue в этом репозитории с описанием проблемы

## 🏆 Благодарности

- Команде Wine за отличный инструмент
- Сообществу Linux Gaming
- Blizzard Entertainment за Battle.net

---

**Удачной игры!** 🎮

*Последнее обновление: Сентябрь 2024*
