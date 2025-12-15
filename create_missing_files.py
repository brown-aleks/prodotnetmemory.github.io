#!/usr/bin/env python3
"""
Скрипт для создания минимальной структуры файлов MkDocs
"""
import os
from pathlib import Path

# Базовая директория
base_dir = Path("S:/Books/prodotnetmemory.github.io/docs")

# Структура файлов для создания
files_to_create = {
    "about/index.md": """# О книге

Это авторский перевод книги "Pro .NET Memory Management" на русский язык.

## Об оригинале

**Название**: Pro .NET Memory Management: For Better Code, Performance, and Scalability  
**Издание**: Second Edition, 2024  
**Авторы**: Konrad Kokosa, Christophe Nasarre, Kevin Gosse  

## О переводе

Перевод выполнен Александром Броуном для русскоязычного .NET сообщества.
""",
    
    "about/authors.md": """# Об авторах

## Konrad Kokosa
Опытный разработчик и архитектор с особым интересом к технологиям Microsoft.

## Christophe Nasarre
Эксперт по производительности и внутреннему устройству .NET.

## Kevin Gosse
Специалист по диагностике и оптимизации .NET приложений.
""",
    
    "about/technical-reviewer.md": """# О техническом рецензенте

Информация о техническом рецензенте будет добавлена позже.
""",
    
    "about/acknowledgments.md": """# Благодарности

Благодарности авторов оригинальной книги.
""",
    
    "about/foreword.md": """# Предисловие

Предисловие к книге от Maoni Stephens.
""",
    
    "about/introduction.md": """# Введение

Введение в книгу Pro .NET Memory Management.
""",
    
    "chapters/index.md": """# Оглавление

## Часть I: Основы
- [Глава 1. Базовые концепции](chapter-01/index.md)
- [Глава 2. Низкоуровневое управление памятью](chapter-02/index.md)
- [Глава 3. Измерения памяти](chapter-03/index.md)
- [Глава 4. Основы .NET](chapter-04/index.md)

## Часть II: Продвинутые темы
*В процессе перевода...*
""",
    
    "chapters/chapter-01/index.md": """# Глава 1. Базовые концепции

Давайте начнём с простого, но важного вопроса: когда следует заботиться об управлении памятью в .NET?

## Содержание главы

1. Управление памятью
2. Сборщик мусора
3. Выделение памяти

*Глава находится в процессе перевода...*
""",
    
    "chapters/chapter-02/index.md": """# Глава 2. Низкоуровневое управление памятью

Эта глава рассматривает управление памятью на уровне операционной системы и аппаратного обеспечения.

*Глава находится в процессе перевода...*
""",
    
    "chapters/chapter-03/index.md": """# Глава 3. Измерения памяти

Инструменты и методы измерения использования памяти в .NET приложениях.

*Глава находится в процессе перевода...*
""",
    
    "chapters/chapter-04/index.md": """# Глава 4. Основы .NET

Внутреннее устройство .NET Runtime и основные концепции.

*Глава находится в процессе перевода...*
""",
    
    "appendix/glossary.md": """# Глоссарий

## A-Z

**GC (Garbage Collector)** - Сборщик мусора  
**JIT (Just-In-Time)** - Компиляция во время выполнения  
**CLR (Common Language Runtime)** - Общеязыковая среда выполнения  
**IL (Intermediate Language)** - Промежуточный язык  
**LOH (Large Object Heap)** - Куча больших объектов  
**SOH (Small Object Heap)** - Куча малых объектов  
**POH (Pinned Object Heap)** - Куча закреплённых объектов  
""",
    
    "appendix/resources.md": """# Ресурсы

## Официальная документация
- [.NET Documentation](https://docs.microsoft.com/dotnet/)
- [Garbage Collection](https://docs.microsoft.com/dotnet/standard/garbage-collection/)

## Инструменты
- [PerfView](https://github.com/microsoft/perfview)
- [dotnet-counters](https://docs.microsoft.com/dotnet/core/diagnostics/dotnet-counters)
- [dotnet-trace](https://docs.microsoft.com/dotnet/core/diagnostics/dotnet-trace)

## Блоги
- [Maoni Stephens Blog](https://devblogs.microsoft.com/dotnet/author/maoni/)
- [Konrad Kokosa Blog](https://prodotnetmemory.com/)
""",
    
    "appendix/faq.md": """# Часто задаваемые вопросы

## Вопросы о переводе

**Q: Где можно купить оригинал книги?**  
A: [SpringerLink](https://link.springer.com/book/10.1007/979-8-8688-0453-3)

**Q: Как помочь с переводом?**  
A: Создавайте Pull Requests в [GitHub репозитории](https://github.com/brown-aleks/prodotnetmemory.github.io)
"""
}

def create_files():
    """Создаёт отсутствующие файлы"""
    for file_path, content in files_to_create.items():
        full_path = base_dir / file_path
        
        # Создаём директорию если не существует
        full_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Создаём файл только если он не существует
        if not full_path.exists():
            with open(full_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ Создан файл: {file_path}")
        else:
            print(f"⏭️ Файл уже существует: {file_path}")

if __name__ == "__main__":
    create_files()
    print("\n✨ Все необходимые файлы созданы!")