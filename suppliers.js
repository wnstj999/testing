const supplierKey = 'suppliers';

function getSuppliers() {
  const suppliers = JSON.parse(localStorage.getItem(supplierKey));
  if (!suppliers) {
    const defaults = [
      { name: 'ABC 자재', note: '주요 철근 공급' },
      { name: 'XYZ 건설', note: '콘크리트 납품' },
      { name: '123 산업', note: '볼트 및 너트' }
    ];
    localStorage.setItem(supplierKey, JSON.stringify(defaults));
    return defaults;
  }
  return suppliers;
}

function saveSuppliers(list) {
  localStorage.setItem(supplierKey, JSON.stringify(list));
}

function render() {
  const tbody = document.getElementById('supplier-body');
  tbody.innerHTML = '';
  getSuppliers().forEach((sup, index) => {
    const row = document.createElement('tr');
    row.innerHTML = `<td>${sup.name}</td><td>${sup.note}</td><td><button data-index="${index}">삭제</button></td>`;
    tbody.appendChild(row);
  });
}

document.getElementById('supplier-form').addEventListener('submit', event => {
  event.preventDefault();
  const name = document.getElementById('supplier-name').value.trim();
  const note = document.getElementById('supplier-note').value.trim();
  if (!name || !note) return;
  const list = getSuppliers();
  list.push({ name, note });
  saveSuppliers(list);
  event.target.reset();
  render();
});

document.getElementById('supplier-body').addEventListener('click', event => {
  if (event.target.tagName === 'BUTTON') {
    const index = event.target.dataset.index;
    const list = getSuppliers();
    list.splice(index, 1);
    saveSuppliers(list);
    render();
  }
});

window.addEventListener('DOMContentLoaded', render);
