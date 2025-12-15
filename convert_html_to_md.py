#!/usr/bin/env python3
"""
Скрипт для конвертации HTML файлов в Markdown
"""
import os
import html2text
from pathlib import Path
import re

def convert_html_to_markdown(html_file_path, output_dir):
    """Конвертирует HTML файл в Markdown"""
    
    # Настройка конвертера
    h = html2text.HTML2Text()
    h.body_width = 0  # Отключить перенос строк
    h.ignore_links = False
    h.ignore_images = False
    h.ignore_emphasis = False
    h.skip_internal_links = False
    h.inline_links = True
    h.protect_links = True
    h.unicode_snob = True
    
    # Чтение HTML
    with open(html_file_path, 'r', encoding='utf-8') as f:
        html_content = f.read()
    
    # Предобработка HTML
    # Замена кастомных классов на адmonitions
    html_content = re.sub(
        r'<div class="note">(.*?)</div>',
        r'!!! note\n    \1',
        html_content,
        flags=re.DOTALL
    )
    
    html_content = re.sub(
        r'<p class="cli">(.*?)</p>',
        r'```bash\n\1\n```',
        html_content,
        flags=re.DOTALL
    )
    
    # Конвертация в Markdown
    markdown_content = h.handle(html_content)
    
    # Постобработка Markdown
    # Исправление заголовков
    markdown_content = re.sub(r'^#\s+', '# ', markdown_content, flags=re.MULTILINE)
    
    # Добавление метаданных в начало файла
    file_name = Path(html_file_path).stem
    metadata = f"""---
title: {file_name.replace('-', ' ').title()}
description: Перевод главы из книги Pro .NET Memory Management
---

"""
    
    markdown_content = metadata + markdown_content
    
    # Сохранение результата
    output_path = Path(output_dir) / f"{file_name}.md"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(markdown_content)
    
    print(f"✅ Конвертирован: {html_file_path} -> {output_path}")

def main():
    """Основная функция"""
    
    # Пути
    html_dir = Path("src/content")
    output_dir = Path("docs/chapters")
    
    # Конвертация каждого HTML файла
    for html_file in html_dir.glob("*.html"):
        if html_file.name == "navbar.html":
            continue  # Пропускаем навигацию
        
        # Определяем выходную директорию
        if html_file.name.startswith("chapter"):
            chapter_num = html_file.name[7:].split('.')[0]
            out_dir = output_dir / f"chapter-{chapter_num.zfill(2)}"
        else:
            out_dir = output_dir.parent
        
        convert_html_to_markdown(html_file, out_dir)
    
    # Конвертация about файлов
    about_dir = Path("about")
    for md_file in about_dir.glob("*.md"):
        # Копируем и адаптируем существующие MD файлы
        with open(md_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        output_path = Path("docs/about") / md_file.name
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"✅ Скопирован: {md_file} -> {output_path}")

if __name__ == "__main__":
    main()