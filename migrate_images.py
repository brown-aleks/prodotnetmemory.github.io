#!/usr/bin/env python3
"""
Скрипт для переноса и организации изображений
"""
import shutil
from pathlib import Path
import re

def migrate_images():
    """Переносит изображения в новую структуру"""
    
    # Источники изображений
    sources = [
        Path("imgs"),
        Path("src/imgs"),
        Path("src/content/img")
    ]
    
    # Целевая директория
    target = Path("docs/assets/images")
    target.mkdir(parents=True, exist_ok=True)
    
    for source in sources:
        if source.exists():
            for img_file in source.glob("**/*"):
                if img_file.is_file():
                    # Копируем с сохранением структуры
                    relative_path = img_file.relative_to(source)
                    target_path = target / relative_path
                    target_path.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(img_file, target_path)
                    print(f"✅ Скопировано: {img_file} -> {target_path}")
    
    # Обновление путей в Markdown файлах
    update_image_paths()

def update_image_paths():
    """Обновляет пути к изображениям в Markdown файлах"""
    
    docs_dir = Path("docs")
    
    for md_file in docs_dir.glob("**/*.md"):
        with open(md_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Обновляем пути к изображениям
        content = re.sub(
            r'!\[([^\]]*)\]\((?:\.\./)*imgs/([^)]+)\)',
            r'![\1](/assets/images/\2)',
            content
        )
        content = re.sub(
            r'!\[([^\]]*)\]\((?:\.\./)*src/imgs/([^)]+)\)',
            r'![\1](/assets/images/\2)',
            content
        )
        
        with open(md_file, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"✅ Обновлены пути в: {md_file}")

if __name__ == "__main__":
    migrate_images()