document.addEventListener("DOMContentLoaded", function () {
  // Функция для загрузки содержимого навигационных панелей
  function loadNavigation() {
      fetch('navigation.html')
          .then(response => response.text())
          .then(html => {
              // Извлекаем содержимое навигационных панелей
              const parser = new DOMParser();
              const doc = parser.parseFromString(html, 'text/html');

              // Загружаем содержимое в вертикальную навигационную панель
              document.querySelector('#sidebarNav .position-sticky').innerHTML = doc.getElementById('sidebarNavContent').innerHTML;

              // Загружаем содержимое в Offcanvas
              document.querySelector('#navbarScroll').innerHTML = doc.getElementById('sidebarNavContent').innerHTML;  //navbarScrollContent

              // Устанавливаем обработчики кликов для ссылок в навигационной панели и Offcanvas
              document.querySelectorAll('#sidebarNav a, #navbarScroll a').forEach(link => {
                  link.addEventListener('click', function (event) {
                      event.preventDefault();
                      loadContent(this.getAttribute('href'));
                  });
              });

              // Инициализируем компонент Offcanvas после загрузки навигации
              //initOffcanvas();
          })
          .catch(error => console.error('Ошибка загрузки навигации:', error));
  }

  // Функция для инициализации компонента Offcanvas
  function initOffcanvas() {
    setTimeout(() => {
        var offcanvasElement = document.getElementById('offcanvasNavbar');
        if (offcanvasElement) {
            new bootstrap.Offcanvas(offcanvasElement);
        } else {
            console.error('Элемент offcanvas не найден.');
        }
    }, 100); // Задержка в 100 миллисекунд
}

  // Функция для загрузки основного контента
  function loadContent(page) {
      fetch(page)
          .then(response => response.text())
          .then(html => {
              document.getElementById('mainContent').innerHTML = html;
          })
          .catch(error => console.error('Ошибка загрузки контента:', error));
  }

  // Загрузка навигационных панелей при загрузке страницы
  loadNavigation();

  // Загрузка начального контента (например, "Введение")
  loadContent('about/introduction.html');
});