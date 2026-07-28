const API = '/api/tareas';
let data = [];
let currentFilter = 'all';
let editId = null;

const lista = document.getElementById('lista');
const frm = document.getElementById('frm');
const saveBtn = document.getElementById('save-btn');
const cancelBtn = document.getElementById('cancel-btn');
const emptyDiv = document.getElementById('empty');
const emptyMsg = document.getElementById('empty-msg');
const flash = document.getElementById('flash');

function fecha(str) {
  if (!str) return '';
  const d = new Date(str);
  return d.toLocaleDateString('es-ES', { day: 'numeric', month: 'short', year: 'numeric' });
}

function aviso(msg, ok=true) {
  flash.textContent = msg;
  flash.className = ok ? 'show ok' : 'show err';
  setTimeout(() => { flash.className = ''; }, 3000);
}

function render() {
  let items = data;
  if (currentFilter === 'pend') items = items.filter(t => !t.completada);
  if (currentFilter === 'done') items = items.filter(t => t.completada);

  document.getElementById('n-all').textContent = data.length;
  document.getElementById('n-pend').textContent = data.filter(t => !t.completada).length;
  document.getElementById('n-done').textContent = data.filter(t => t.completada).length;

  lista.innerHTML = '';
  if (!items.length) {
    emptyDiv.style.display = 'block';
    emptyMsg.innerHTML = data.length
      ? '<strong>Búsqueda sin coincidencias</strong>Intente con otros parámetros.'
      : '<strong>Base de datos vacía</strong>Agregue el primer registro.';
    return;
  }
  
  emptyDiv.style.display = 'none';

  for (const t of items) {
    const li = document.createElement('li');
    li.className = 'item' + (t.completada ? ' done' : '');
    li.innerHTML = `
      <div class="item-header">
        <input type="checkbox" ${t.completada ? 'checked' : ''}>
        <div class="item-title"></div>
      </div>
      <div class="item-desc"></div>
      <div class="item-footer">
        <div class="item-date">
          <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
          ${fecha(t.creado)}
        </div>
        <div class="item-actions">
          <button class="act-btn edit" title="Modificar"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg></button>
          <button class="act-btn del" title="Borrar"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg></button>
        </div>
      </div>`;
    li.querySelector('.item-title').textContent = t.titulo;
    li.querySelector('.item-desc').textContent = t.descripcion || '';
    li.querySelector('input').onchange = () => toggle(t.id, !t.completada);
    li.querySelector('.edit').onclick = () => startEdit(t);
    li.querySelector('.del').onclick = () => del(t.id);
    lista.appendChild(li);
  }
}

async function load(q='') {
  try {
    const r = await fetch(API + (q ? `?q=${encodeURIComponent(q)}` : ''));
    data = await r.json();
    render();
  } catch { aviso('Fallo de conexión', false); }
}

async function toggle(id, val) {
  try {
    const r = await fetch(`${API}/${id}`, {
      method: 'PUT',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ completada: val })
    });
    const upd = await r.json();
    data = data.map(t => t.id === id ? upd : t);
    render();
  } catch { aviso('Fallo al modificar', false); load(); }
}

async function del(id) {
  if (!confirm('¿Confirma la eliminación permanente de este registro?')) return;
  try {
    await fetch(`${API}/${id}`, { method: 'DELETE' });
    data = data.filter(t => t.id !== id);
    render();
    aviso('Registro eliminado con éxito');
  } catch { aviso('Fallo al borrar', false); load(); }
}

function startEdit(t) {
  editId = t.id;
  document.getElementById('inp-titulo').value = t.titulo;
  document.getElementById('inp-desc').value = t.descripcion || '';
  saveBtn.textContent = 'Guardar';
  cancelBtn.style.display = 'block';
  document.getElementById('inp-titulo').focus();
}

function resetForm() {
  editId = null;
  frm.reset();
  saveBtn.textContent = 'Registrar';
  cancelBtn.style.display = 'none';
}

cancelBtn.onclick = resetForm;

frm.onsubmit = async e => {
  e.preventDefault();
  const titulo = document.getElementById('inp-titulo').value.trim();
  const desc = document.getElementById('inp-desc').value.trim();
  if (!titulo) return;

  try {
    if (editId) {
      const r = await fetch(`${API}/${editId}`, {
        method: 'PUT',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ titulo, descripcion: desc })
      });
      const upd = await r.json();
      data = data.map(t => t.id === editId ? upd : t);
      aviso('Modificación guardada');
    } else {
      const r = await fetch(API, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ titulo, descripcion: desc })
      });
      const nuevo = await r.json();
      data.unshift(nuevo);
      aviso('Nuevo registro almacenado');
    }
    resetForm();
    render();
  } catch { aviso('Fallo al procesar', false); }
};

document.getElementById('buscar').oninput = e => load(e.target.value);

document.querySelectorAll('.tabs button').forEach(b => {
  b.onclick = () => {
    document.querySelectorAll('.tabs button').forEach(x => x.classList.remove('on'));
    b.classList.add('on');
    currentFilter = b.dataset.f;
    render();
  };
});

load();
