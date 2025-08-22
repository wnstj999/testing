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
    row.innerHTML = `<td>${item.name}</td><td>${item.note}</td><td><button class="edit" data-id="${item.id}">수정</button> <button class="delete" data-id="${item.id}">삭제</button></td>`;
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
  if (event.target.matches('button.delete')) {
    const id = event.target.dataset.id;
    await fetch(`/api/suppliers/${id}`, { method: 'DELETE' });
    render();
  } else if (event.target.matches('button.edit')) {
    const id = event.target.dataset.id;
    const row = event.target.closest('tr');
    const currentName = row.children[0].textContent;
    const currentNote = row.children[1].textContent;
    const name = prompt('공급업체', currentName);
    const note = prompt('비고', currentNote);
    if (name && note) {
      await fetch(`/api/suppliers/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, note })
      });
      render();
    }
  }
});

window.addEventListener('DOMContentLoaded', render);
