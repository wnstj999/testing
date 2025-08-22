const inventoryKey = 'inventoryItems';

function getItems() {
  const items = JSON.parse(localStorage.getItem(inventoryKey));
  if (!items) {
    const defaults = [
      { name: '철근', quantity: '100개' },
      { name: '콘크리트', quantity: '50포대' },
      { name: '볼트', quantity: '200개' }
    ];
    localStorage.setItem(inventoryKey, JSON.stringify(defaults));
    return defaults;
  }
  return items;
}

function saveItems(items) {
  localStorage.setItem(inventoryKey, JSON.stringify(items));
}

function render() {
  const tbody = document.getElementById('inventory-body');
  tbody.innerHTML = '';
  getItems().forEach((item, index) => {
    const row = document.createElement('tr');
    row.innerHTML = `<td>${item.name}</td><td>${item.quantity}</td><td><button data-index="${index}">삭제</button></td>`;
    tbody.appendChild(row);
  });
}

document.getElementById('add-form').addEventListener('submit', event => {
  event.preventDefault();
  const name = document.getElementById('item-name').value.trim();
  const qty = document.getElementById('item-qty').value.trim();
  if (!name || !qty) return;
  const items = getItems();
  items.push({ name, quantity: qty });
  saveItems(items);
  event.target.reset();
  render();
});

document.getElementById('inventory-body').addEventListener('click', event => {
  if (event.target.tagName === 'BUTTON') {
    const index = event.target.dataset.index;
    const items = getItems();
    items.splice(index, 1);
    saveItems(items);
    render();
  }
});

window.addEventListener('DOMContentLoaded', render);
