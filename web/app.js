// Configuración
const API = 'https://xneo-web.onrender.com';
let token = localStorage.getItem('token');
let currentPage = 'home';
let videos = [];
let apiCache = [];

// ==================== RENDERIZADO ====================
function render(page) {
    currentPage = page;
    const app = document.getElementById('app');
    
    if (!token && page !== 'login' && page !== 'register') {
        renderLogin();
        return;
    }
    
    switch(page) {
        case 'login': renderLogin(); break;
        case 'register': renderRegister(); break;
        case 'home': renderHome(); break;
        case 'upload': renderUpload(); break;
        case 'profile': renderProfile(); break;
        case 'play': renderPlayer(); break;
    }
}

// ==================== AUTH ====================
function renderLogin() {
    document.getElementById('app').innerHTML = `
        <div class="auth-container">
            <div style="text-align:center;margin-bottom:32px">
                <span class="logo"><span class="x">X</span><span class="neo">NEO</span></span>
                <p class="subtitle">CONTENIDO EXCLUSIVO</p>
            </div>
            <div class="card" style="width:100%;max-width:360px">
                <form onsubmit="login(event)">
                    <div class="input-group">
                        <input type="text" id="username" placeholder="Usuario" required>
                    </div>
                    <div class="input-group">
                        <input type="password" id="password" placeholder="Contraseña" required>
                    </div>
                    <div class="error" id="error"></div>
                    <button type="submit" class="btn-primary">Iniciar Sesión</button>
                </form>
                <div class="link">
                    ¿No tienes cuenta? <a href="#" onclick="render('register')">Regístrate</a>
                </div>
            </div>
        </div>
    `;
}

function renderRegister() {
    document.getElementById('app').innerHTML = `
        <div class="auth-container">
            <div style="text-align:center;margin-bottom:32px">
                <span class="logo"><span class="x">X</span><span class="neo">NEO</span></span>
                <p class="subtitle">CREAR CUENTA</p>
            </div>
            <div class="card" style="width:100%;max-width:360px">
                <form onsubmit="register(event)">
                    <div class="input-group">
                        <input type="text" id="reg-username" placeholder="Usuario" required minlength="4">
                    </div>
                    <div class="input-group">
                        <input type="password" id="reg-password" placeholder="Contraseña" required minlength="6">
                    </div>
                    <div class="input-group">
                        <input type="password" id="reg-confirm" placeholder="Confirmar contraseña" required>
                    </div>
                    <div class="error" id="reg-error"></div>
                    <button type="submit" class="btn-primary">Registrarse</button>
                </form>
                <div class="link">
                    ¿Ya tienes cuenta? <a href="#" onclick="render('login')">Inicia sesión</a>
                </div>
            </div>
        </div>
    `;
}

async function login(e) {
    e.preventDefault();
    const username = document.getElementById('username').value.trim();
    const password = document.getElementById('password').value;
    try {
        const res = await fetch(`${API}/api/auth/login`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({username, password})
        });
        const data = await res.json();
        if (res.ok) {
            token = data.token;
            localStorage.setItem('token', token);
            render('home');
        } else {
            document.getElementById('error').textContent = data.message || 'Error al iniciar sesión';
        }
    } catch(e) {
        document.getElementById('error').textContent = 'Error de conexión';
    }
}

async function register(e) {
    e.preventDefault();
    const username = document.getElementById('reg-username').value.trim();
    const password = document.getElementById('reg-password').value;
    const confirm = document.getElementById('reg-confirm').value;
    
    if (password !== confirm) {
        document.getElementById('reg-error').textContent = 'Las contraseñas no coinciden';
        return;
    }
    
    try {
        const res = await fetch(`${API}/api/auth/register`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({username, password})
        });
        const data = await res.json();
        if (res.ok) {
            token = data.token;
            localStorage.setItem('token', token);
            render('home');
        } else {
            document.getElementById('reg-error').textContent = data.message || 'Error al registrarse';
        }
    } catch(e) {
        document.getElementById('reg-error').textContent = 'Error de conexión';
    }
}

function logout() {
    localStorage.removeItem('token');
    token = null;
    render('login');
}

// ==================== HOME ====================
async function renderHome() {
    document.getElementById('app').innerHTML = `
        <header>
            <span class="logo"><span class="x">X</span><span class="neo">NEO</span></span>
            <div style="display:flex;gap:8px">
                <button class="btn-upload" onclick="render('upload')">+ Subir</button>
            </div>
        </header>
        <div class="grid" id="video-grid">
            <div style="text-align:center;padding:32px;grid-column:span 2">Cargando...</div>
        </div>
        <nav class="bottom-nav">
            <button class="active" onclick="render('home')"><span>🏠</span>Inicio</button>
            <button onclick="render('upload')"><span>⬆️</span>Subir</button>
            <button onclick="render('profile')"><span>👤</span>Perfil</button>
        </nav>
    `;
    await loadVideos();
}

async function loadVideos() {
    try {
        const res = await fetch(`${API}/api/videos`, {
            headers: token ? {'Authorization': `Bearer ${token}`} : {}
        });
        if (res.ok) {
            videos = await res.json();
            renderVideoGrid();
        }
    } catch(e) {
        document.getElementById('video-grid').innerHTML = '<div style="text-align:center;padding:32px;grid-column:span 2;color:#888">Error al cargar videos</div>';
    }
}

function renderVideoGrid() {
    const grid = document.getElementById('video-grid');
    if (!grid) return;
    
    if (videos.length === 0) {
        grid.innerHTML = '<div style="text-align:center;padding:32px;grid-column:span 2;color:#888">No hay videos aún</div>';
        return;
    }
    
    grid.innerHTML = videos.map(v => `
        <div class="video-card" onclick="openVideo('${v.id}')">
            <div class="thumbnail">
                ${v.thumbnail ? `<img src="${v.thumbnail}" alt="${v.title}">` : '<div class="no-thumb">▶️</div>'}
                <span class="quality">HD</span>
                <span class="duration">${formatDuration(v.duration || 0)}</span>
            </div>
            <div class="video-info">
                <div class="video-title">${v.title || 'Sin título'}</div>
                <div class="uploader">
                    <div class="avatar-small">${(v.uploaderName || 'U')[0].toUpperCase()}</div>
                    <span>${v.uploaderName || 'Usuario'}</span>
                </div>
                <div class="stats">
                    <span>👁 ${formatNumber(v.views || 0)}</span>
                    <span>·</span>
                    <span>${formatTimeAgo(v.uploadDate)}</span>
                </div>
            </div>
        </div>
    `).join('');
}

function formatDuration(seconds) {
    const min = Math.floor(seconds / 60);
    const sec = seconds % 60;
    return `${min}:${sec.toString().padStart(2, '0')}`;
}

function formatNumber(num) {
    if (num >= 1000000) return (num/1000000).toFixed(1) + 'M';
    if (num >= 1000) return (num/1000).toFixed(1) + 'K';
    return num.toString();
}

function formatTimeAgo(dateStr) {
    if (!dateStr) return '';
    const diff = (new Date() - new Date(dateStr)) / 1000;
    if (diff < 60) return 'Hace instantes';
    if (diff < 3600) return `Hace ${Math.floor(diff/60)} min`;
    if (diff < 86400) return `Hace ${Math.floor(diff/3600)} h`;
    return `Hace ${Math.floor(diff/86400)} d`;
}

// ==================== PLAYER ====================
let currentVideo = null;

function openVideo(id) {
    currentVideo = videos.find(v => v.id === id);
    if (!currentVideo) return;
    render('play');
}

function renderPlayer() {
    const v = currentVideo;
    document.getElementById('app').innerHTML = `
        <header>
            <button class="btn-back" onclick="render('home')">← Volver</button>
            <span style="font-weight:bold">XNEO</span>
            <div style="width:50px"></div>
        </header>
        <div style="background:#000;aspect-ratio:16/9;display:flex;align-items:center;justify-content:center">
            <span style="font-size:48px;color:#E53935;cursor:pointer" onclick="this.innerText='🎬'">▶️</span>
        </div>
        <div class="card">
            <h2>${v.title || 'Sin título'}</h2>
            <div style="display:flex;gap:12px;align-items:center;margin-bottom:12px">
                <span>👁 ${formatNumber(v.views || 0)} vistas</span>
                <span>·</span>
                <span>${formatTimeAgo(v.uploadDate)}</span>
            </div>
            ${v.description ? `<p style="color:#888;margin-bottom:12px">${v.description}</p>` : ''}
            <div style="display:flex;align-items:center;gap:8px;margin-bottom:12px">
                <div class="avatar-small">${(v.uploaderName||'U')[0]}</div>
                <span>${v.uploaderName || 'Usuario'}</span>
            </div>
            <div style="display:flex;gap:16px;justify-content:space-around;padding-top:12px;border-top:1px solid #2A2A2A">
                <span onclick="likeVideo('${v.id}')" style="cursor:pointer">👍 ${formatNumber(v.likes||0)}</span>
                <span onclick="dislikeVideo('${v.id}')" style="cursor:pointer">👎 ${formatNumber(v.dislikes||0)}</span>
                <span onclick="shareVideo('${v.id}')" style="cursor:pointer">🔗 Compartir</span>
                <span onclick="downloadVideo('${v.id}')" style="cursor:pointer">💾 Guardar</span>
            </div>
        </div>
        <h3>Videos recomendados</h3>
        <div class="grid">
            ${videos.filter(v2 => v2.id !== v.id).slice(0,6).map(v2 => `
                <div class="video-card" onclick="openVideo('${v2.id}')">
                    <div class="thumbnail" style="height:80px">
                        ${v2.thumbnail ? `<img src="${v2.thumbnail}">` : '<div class="no-thumb">▶️</div>'}
                        <span class="duration">${formatDuration(v2.duration||0)}</span>
                    </div>
                    <div class="video-info">
                        <div class="video-title">${v2.title||''}</div>
                        <div class="stats">👁 ${formatNumber(v2.views||0)}</div>
                    </div>
                </div>
            `).join('')}
        </div>
    `;
}

async function likeVideo(id) {
    await fetch(`${API}/api/videos/${id}/like`, {method:'POST',headers:{'Authorization':`Bearer ${token}`}});
}
async function dislikeVideo(id) {
    await fetch(`${API}/api/videos/${id}/dislike`, {method:'POST',headers:{'Authorization':`Bearer ${token}`}});
}
function shareVideo(id) {
    const url = `${window.location.origin}/play?id=${id}`;
    navigator.share ? navigator.share({title:'XNEO',text:'Mira este video',url}) : prompt('Enlace:', url);
}
function downloadVideo(id) {
    alert('Descarga iniciada (funcionalidad completa en la app nativa)');
}

// ==================== UPLOAD ====================
function renderUpload() {
    document.getElementById('app').innerHTML = `
        <header>
            <button class="btn-back" onclick="render('home')">← Volver</button>
            <span style="font-weight:bold">Subir Video</span>
            <div style="width:50px"></div>
        </header>
        <div class="card">
            <input type="file" id="video-file" accept="video/*" style="margin-bottom:12px">
            <input type="text" id="upload-title" placeholder="Título *" style="margin-bottom:8px">
            <textarea id="upload-desc" placeholder="Descripción (opcional)" rows="3" style="margin-bottom:8px"></textarea>
            <select id="upload-category" style="margin-bottom:12px">
                <option>Hetero</option>
                <option>Bi</option>
                <option>Gay</option>
                <option>Trans</option>
            </select>
            <button class="btn-primary" onclick="uploadVideo()">Subir Video</button>
            <div class="error" id="upload-error"></div>
        </div>
    `;
}

async function uploadVideo() {
    const file = document.getElementById('video-file').files[0];
    const title = document.getElementById('upload-title').value.trim();
    const desc = document.getElementById('upload-desc').value.trim();
    const category = document.getElementById('upload-category').value;
    
    if (!file) { document.getElementById('upload-error').textContent='Selecciona un video'; return; }
    if (!title) { document.getElementById('upload-error').textContent='Ingresa un título'; return; }
    
    const formData = new FormData();
    formData.append('video', file);
    formData.append('title', title);
    formData.append('description', desc);
    formData.append('category', category);
    
    try {
        const res = await fetch(`${API}/api/upload/video`, {
            method:'POST',
            headers:{'Authorization':`Bearer ${token}`},
            body: formData
        });
        if (res.ok) {
            alert('✅ Video subido correctamente');
            render('home');
        } else {
            document.getElementById('upload-error').textContent='Error al subir video';
        }
    } catch(e) {
        document.getElementById('upload-error').textContent='Error de conexión';
    }
}

// ==================== PERFIL ====================
async function renderProfile() {
    document.getElementById('app').innerHTML = `
        <header>
            <span style="font-weight:bold">Mi Perfil</span>
            <button class="btn-red" onclick="logout()">Salir</button>
        </header>
        <div class="profile-header">
            <div class="avatar" id="profile-avatar">U</div>
            <h2 id="profile-username" style="margin-top:12px">Cargando...</h2>
            <p style="color:#888" id="profile-category"></p>
        </div>
        <h3>Mis Videos</h3>
        <div class="grid" id="my-videos">
            <div style="text-align:center;padding:32px;grid-column:span 2">Cargando...</div>
        </div>
        <nav class="bottom-nav">
            <button onclick="render('home')"><span>🏠</span>Inicio</button>
            <button onclick="render('upload')"><span>⬆️</span>Subir</button>
            <button class="active" onclick="render('profile')"><span>👤</span>Perfil</button>
        </nav>
    `;
    
    try {
        const res = await fetch(`${API}/api/auth/me`, {headers:{'Authorization':`Bearer ${token}`}});
        if (res.ok) {
            const user = await res.json();
            document.getElementById('profile-username').textContent = user.username;
            document.getElementById('profile-category').textContent = 'Categoría: ' + (user.category||'Hetero');
            if (user.avatar) {
                document.getElementById('profile-avatar').innerHTML = `<img src="${user.avatar}" style="width:100%;height:100%;border-radius:50%;object-fit:cover">`;
            } else {
                document.getElementById('profile-avatar').textContent = user.username[0].toUpperCase();
            }
        }
    } catch(e) {}
    
    try {
        const res = await fetch(`${API}/api/videos/mine`, {headers:{'Authorization':`Bearer ${token}`}});
        if (res.ok) {
            const myVideos = await res.json();
            document.getElementById('my-videos').innerHTML = myVideos.length === 0
                ? '<div style="text-align:center;padding:32px;grid-column:span 2;color:#888">No has subido videos</div>'
                : myVideos.map(v => `
                    <div class="video-card" onclick="openVideo('${v.id}')">
                        <div class="thumbnail" style="height:80px">
                            ${v.thumbnail ? `<img src="${v.thumbnail}">` : '<div class="no-thumb">▶️</div>'}
                            <span class="duration">${formatDuration(v.duration||0)}</span>
                        </div>
                        <div class="video-info">
                            <div class="video-title">${v.title||''}</div>
                            <div class="stats">👁 ${formatNumber(v.views||0)}</div>
                        </div>
                    </div>
                `).join('');
        }
    } catch(e) {}
}

// ==================== INICIO ====================
if (token) {
    render('home');
} else {
    render('login');
}
