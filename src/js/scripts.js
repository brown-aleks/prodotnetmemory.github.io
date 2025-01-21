function loadContent(page, sectionId) {
  const content = document.getElementById('content');
  fetch(`content/${page}`)
      .then(response => response.text())
      .then(data => {
          content.innerHTML = data;
          // Обновление Scrollspy после загрузки нового контента
          const scrollSpy = bootstrap.ScrollSpy.getInstance(document.body);
          if (scrollSpy) {
              scrollSpy.refresh();
          }
          // Прокрутка до нужной секции
          if (sectionId) {
            const section = document.getElementById(sectionId);
            if (section) {
                const footerHeight = document.querySelector('footer').offsetHeight;
                const sectionTop = section.getBoundingClientRect().top + window.scrollY;
                const scrollPosition = sectionTop - footerHeight;
                window.scrollTo({ top: scrollPosition, behavior: 'smooth' });
            }
        }
      })
      .catch(error => {
          content.innerHTML = '<h2>Ошибка</h2><p>Не удалось загрузить содержимое.</p>';
      });
}

function loadNavbar() {
  const navbar = document.getElementById('navbar');
  fetch('content/navbar.html')
      .then(response => response.text())
      .then(data => {
          navbar.innerHTML = data;
          // Инициализация Scrollspy после загрузки навигационной панели
          new bootstrap.ScrollSpy(document.body, {
              target: '#navbar'
          });
          // Установка ограничения на прокрутку навигационной панели
          const header = document.querySelector('header');
          const observer = new IntersectionObserver(
              ([entry]) => {
                  if (entry.isIntersecting) {
                      navbar.style.position = 'absolute';
                      navbar.style.top = `${header.offsetHeight}px`;
                  } else {
                      navbar.style.position = 'sticky';
                      navbar.style.top = '0';
                  }
              },
              { rootMargin: `-${header.offsetHeight}px 0px 0px 0px` }
          );
          observer.observe(header);
      })
      .catch(error => {
          navbar.innerHTML = '<h2>Ошибка</h2><p>Не удалось загрузить навигационную панель.</п>';
      });
}

function loadOffcanvasNavbar() {
  const offcanvasNavbar = document.getElementById('offcanvas-navbar-content');
  fetch('content/navbar.html')
      .then(response => response.text())
      .then(data => {
          offcanvasNavbar.innerHTML = data;
          // Добавление обработчиков кликов для скрытия панели Offcanvas
          const offcanvasLinks = offcanvasNavbar.querySelectorAll('a.nav-link');
          offcanvasLinks.forEach(link => {
              link.addEventListener('click', () => {
                  const offcanvasElement = document.getElementById('offcanvasNavbar');
                  const offcanvasInstance = bootstrap.Offcanvas.getInstance(offcanvasElement);
                  if (offcanvasInstance) {
                      offcanvasInstance.hide();
                  }
              });
          });
      })
      .catch(error => {
          offcanvasNavbar.innerHTML = '<h2>Ошибка</h2><p>Не удалось загрузить навигационную панель.</p>';
      });
}

// Загрузка навигационной панели при загрузке страницы
document.addEventListener('DOMContentLoaded', () => {
  loadNavbar();
  loadOffcanvasNavbar();
});