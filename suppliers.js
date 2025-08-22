async function fetchSuppliers() {
  const response = await fetch('/api/suppliers');
  return await response.json();
}

async function render() {
  const tbody = document.getElementById('supplier-body');
  tbody.innerHTML = '';
  const items = await fetchSuppliers();
  items.forEach(item => {
    const row = document.createElement('tr');
    row.innerHTML = `<td>${item.name}</td><td>${item.note}</td><td><button data-id="${item.id}">삭제</button></td>`;
    tbody.appendChild(row);
  });
}

document.getElementById('supplier-form').addEventListener('submit', async event => {
  event.preventDefault();
  const name = document.getElementById('supplier-name').value.trim();
  const note = document.getElementById('supplier-note').value.trim();
  if (!name || !note) return;
  await fetch('/api/suppliers', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name, note })
  });
  event.target.reset();
  render();
});

document.getElementById('supplier-body').addEventListener('click', async event => {
  if (event.target.tagName === 'BUTTON') {
    const id = event.target.dataset.id;
    await fetch(`/api/suppliers/${id}`, { method: 'DELETE' });
    render();
  }
});

window.addEventListener('DOMContentLoaded', render);
