FROM squidfunk/mkdocs-material
COPY requirements.txt /docs/requirements.txt
RUN pip install --no-cache-dir -r /docs/requirements.txt