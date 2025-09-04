# ⚡ Быстрый старт

> Краткое руководство для тех, кто хочет быстро установить Battle.net

## 🚀 Автоматическая установка (рекомендуется)

```bash
# Клонирование репозитория
git clone https://github.com/sweetpotatohack/battlenet-wine-linux.git
cd battlenet-wine-linux

# Запуск автоустановки (Ubuntu/Debian)  
chmod +x install.sh
./install.sh
```

## 🎮 Запуск после установки

```bash
# Способ 1: Из меню приложений
# Найдите "Battle.net" в разделе "Игры"

# Способ 2: Из терминала
~/battlenet-launcher.sh

# Способ 3: Прямая команда
WINEDEBUG=-all wine explorer /desktop=battlenet,1440x900 ~/.wine/drive_c/ProgramData/Battle.net/Agent/Agent.exe &
```

## 📋 Что устанавливается

✅ Wine 9.0+  
✅ 32-битная поддержка (wine32)  
✅ Winetricks  
✅ Windows шрифты (corefonts)  
✅ Visual C++ Runtime 2019  
✅ .NET Framework 4.8  
✅ Battle.net клиент  
✅ Скрипт запуска  

## 🔧 Ручная установка

Если автоустановка не работает, следуйте [подробному руководству](battle-net-wine-guide.md).

## ❓ Проблемы?

1. Проверьте [раздел решения проблем](battle-net-wine-guide.md#решение-проблем)
2. Создайте [issue](https://github.com/sweetpotatohack/battlenet-wine-linux/issues/new)

---

**⏱️ Время установки:** 30-60 минут  
**💾 Место на диске:** ~10 GB  
**🖥️ Поддержка:** Ubuntu, Debian, Arch, Fedora+
