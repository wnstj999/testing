async function fetchItems() {
  const response = await fetch('/api/inventory');
  return await response.json();
}

async function render() {
  const tbody = document.getElementById('inventory-body');
  tbody.innerHTML = '';
  const items = await fetchItems();
  items.forEach(item => {
    const row = document.createElement('tr');
    row.innerHTML = `<td>${item.name}</td><td>${item.quantity}</td><td><button data-id="${item.id}">삭제</button></td>`;
    tbody.appendChild(row);
  });
}

document.getElementById('add-form').addEventListener('submit', async event => {
  event.preventDefault();
  const name = document.getElementById('item-name').value.trim();
  const qty = document.getElementById('item-qty').value.trim();
  if (!name || !qty) return;
  await fetch('/api/inventory', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name, quantity: qty })
  });
  event.target.reset();
  render();
});

document.getElementById('inventory-body').addEventListener('click', async event => {
  if (event.target.tagName === 'BUTTON') {
    const id = event.target.dataset.id;
    await fetch(`/api/inventory/${id}`, { method: 'DELETE' });
    render();
  }
});

window.addEventListener('DOMContentLoaded', render);
