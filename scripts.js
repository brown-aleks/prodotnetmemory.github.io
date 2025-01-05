function toggleMenu(link) {
  var li = link.parentElement;
  li.classList.toggle('open');
}

function loadPage(page) {
  var frame = document.querySelector('iframe[name="content-frame"]');
  if (frame) {
    frame.src = page;
  }
}
