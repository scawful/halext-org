import { useState, useEffect } from 'react'
import type { FormEvent } from 'react'
import {
  MdComputer,
  MdRefresh,
  MdAdd,
  MdDelete,
  MdSettingsRemote,
  MdBuild,
  MdWeb,
  MdPhotoLibrary,
  MdArticle,
  MdCloudUpload,
} from 'react-icons/md'
import './AdminSection.css'
import { API_BASE_URL } from '../../utils/helpers'

interface AIClient {
  id: number
  name: string
  node_type: string
  hostname: string
  port: number
  is_active: boolean
  is_public: boolean
  status: string
  last_seen_at: string | null
  capabilities: Record<string, any>
  node_metadata: Record<string, any>
  base_url: string
  owner_id: number
}

interface SitePage {
  id: number
  slug: string
  title: string
  summary?: string
  hero_image_url?: string
  sections: any[]
  nav_links: any[]
  theme: Record<string, any>
  is_published: boolean
}

interface PhotoAlbum {
  id: number
  slug: string
  title: string
  description?: string
  cover_image_url?: string
  hero_text?: string
  photos: any[]
  is_public: boolean
}

interface BlogPost {
  id: number
  slug: string
  title: string
  summary?: string
  hero_image_url?: string
  body_markdown: string
  tags: string[]
  status: string
  published_at?: string
}

interface MediaAsset {
  id: number
  title?: string
  public_url: string
  file_path: string
  created_at: string
}

interface AdminSectionProps {
  token: string
}

const TAB_OPTIONS = [
  { id: 'ai', label: 'AI Clients', icon: <MdComputer size={18} /> },
  { id: 'site', label: 'Site Pages', icon: <MdWeb size={18} /> },
  { id: 'photos', label: 'Photo Albums', icon: <MdPhotoLibrary size={18} /> },
  { id: 'blog', label: 'Blog Posts', icon: <MdArticle size={18} /> },
  { id: 'media', label: 'Media', icon: <MdCloudUpload size={18} /> },
] as const

type AdminTab = (typeof TAB_OPTIONS)[number]['id']

const emptySectionJson = '[\n  {\n    "type": "nav-list",\n    "title": "Labs",\n    "items": [{ "label": "About", "url": "https://halext.org/labs/About" }]\n  }\n]'

export const AdminSection = ({ token }: AdminSectionProps) => {
  const [activeTab, setActiveTab] = useState<AdminTab>('ai')

  // AI state
  const [clients, setClients] = useState<AIClient[]>([])
  const [clientsLoaded, setClientsLoaded] = useState(false)
  const [clientForm, setClientForm] = useState({
    name: '',
    node_type: 'ollama',
    hostname: '',
    port: 11434,
    is_public: false,
  })
  const [showClientForm, setShowClientForm] = useState(false)
  const [testingClient, setTestingClient] = useState<number | null>(null)
  const [rebuilding, setRebuilding] = useState(false)

  // Site pages
  const [sitePages, setSitePages] = useState<SitePage[]>([])
  const [siteLoaded, setSiteLoaded] = useState(false)
  const [siteEditor, setSiteEditor] = useState({
    id: null as number | null,
    slug: '',
    title: '',
    summary: '',
    hero_image_url: '',
    nav_links_json: '[]',
    sections_json: emptySectionJson,
    theme_json: '{\n  "gradient": ["#4c3b52", "#000000"],\n  "accent": "#9775a3"\n}',
    is_published: false,
  })

  // Photo albums
  const [photoAlbums, setPhotoAlbums] = useState<PhotoAlbum[]>([])
  const [photosLoaded, setPhotosLoaded] = useState(false)
  const [photoEditor, setPhotoEditor] = useState({
    id: null as number | null,
    slug: '',
    title: '',
    description: '',
    cover_image_url: '',
    hero_text: '',
    photos_json: '[]',
    is_public: true,
  })

  // Blog posts
  const [blogPosts, setBlogPosts] = useState<BlogPost[]>([])
  const [blogLoaded, setBlogLoaded] = useState(false)
  const [blogEditor, setBlogEditor] = useState({
    id: null as number | null,
    slug: '',
    title: '',
    summary: '',
    hero_image_url: '',
    body_markdown: '',
    tags_csv: '',
    status: 'draft',
  })
  const [editingSlug, setEditingSlug] = useState<string | null>(null)

  // Media
  const [mediaAssets, setMediaAssets] = useState<MediaAsset[]>([])
  const [mediaLoaded, setMediaLoaded] = useState(false)
  const [mediaTitle, setMediaTitle] = useState('')
  const [mediaFile, setMediaFile] = useState<File | null>(null)

  const authHeaders: HeadersInit = {
    Authorization: `Bearer ${token}`,
  }

  const fetchClients = async () => {
    const response = await fetch(`${API_BASE_URL}/admin/ai-clients`, { headers: authHeaders })
    if (response.ok) {
      const data = await response.json()
      setClients(data)
      setClientsLoaded(true)
    }
  }

  const fetchSitePages = async () => {
    const response = await fetch(`${API_BASE_URL}/content/admin/pages`, { headers: authHeaders })
    if (response.ok) {
      const data = await response.json()
      setSitePages(data)
      setSiteLoaded(true)
    }
  }

  const fetchPhotoAlbums = async () => {
    const response = await fetch(`${API_BASE_URL}/content/admin/photo-albums`, { headers: authHeaders })
    if (response.ok) {
      const data = await response.json()
      setPhotoAlbums(data)
      setPhotosLoaded(true)
    }
  }

  const fetchBlogPosts = async () => {
    const response = await fetch(`${API_BASE_URL}/content/admin/blog-posts`, { headers: authHeaders })
    if (response.ok) {
      const data = await response.json()
      setBlogPosts(data)
      setBlogLoaded(true)
    }
  }

  const fetchMedia = async () => {
    const response = await fetch(`${API_BASE_URL}/content/admin/media`, { headers: authHeaders })
    if (response.ok) {
      const data = await response.json()
      setMediaAssets(data)
      setMediaLoaded(true)
    }
  }

  useEffect(() => {
    if (activeTab === 'ai' && !clientsLoaded) {
      fetchClients()
    }
    if (activeTab === 'site' && !siteLoaded) {
      fetchSitePages()
    }
    if (activeTab === 'photos' && !photosLoaded) {
      fetchPhotoAlbums()
    }
    if (activeTab === 'blog' && !blogLoaded) {
      fetchBlogPosts()
    }
    if (activeTab === 'media' && !mediaLoaded) {
      fetchMedia()
    }
  }, [activeTab, clientsLoaded, siteLoaded, photosLoaded, blogLoaded, mediaLoaded])

  const handleAddClient = async (event: FormEvent) => {
    event.preventDefault()
    const response = await fetch(`${API_BASE_URL}/admin/ai-clients`, {
      method: 'POST',
      headers: {
        ...authHeaders,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(clientForm),
    })
    if (response.ok) {
      await fetchClients()
      setShowClientForm(false)
      setClientForm({ name: '', node_type: 'ollama', hostname: '', port: 11434, is_public: false })
    }
  }

  const handleTestConnection = async (clientId: number) => {
    setTestingClient(clientId)
    try {
      await fetch(`${API_BASE_URL}/admin/ai-clients/${clientId}/test`, {
        method: 'POST',
        headers: authHeaders,
      })
    } finally {
      setTestingClient(null)
      fetchClients()
    }
  }

  const handleDeleteClient = async (clientId: number) => {
    if (!confirm('Delete this AI client?')) return
    const response = await fetch(`${API_BASE_URL}/admin/ai-clients/${clientId}`, {
      method: 'DELETE',
      headers: authHeaders,
    })
    if (response.ok) {
      setClients((prev) => prev.filter((client) => client.id !== clientId))
    }
  }

  const handleRebuildFrontend = async () => {
    if (!confirm('Rebuild frontend assets on the server?')) return
    setRebuilding(true)
    try {
      const response = await fetch(`${API_BASE_URL}/admin/rebuild-frontend`, {
        method: 'POST',
        headers: authHeaders,
      })
      const data = await response.json()
      if (response.ok) {
        alert(`✅ ${data.message}`)
      } else {
        alert(`❌ ${data.detail}`)
      }
    } catch (error) {
      console.error(error)
      alert('Failed to trigger rebuild')
    } finally {
      setRebuilding(false)
    }
  }

  const parseJsonField = (value: string, fallback: any, label: string) => {
    try {
      return value.trim() ? JSON.parse(value) : fallback
    } catch (error) {
      alert(`Invalid JSON in ${label}. Please fix and try again.`)
      throw error
    }
  }

  const handleSaveSitePage = async (event: FormEvent) => {
    event.preventDefault()
    const payload = {
      slug: siteEditor.slug.trim(),
      title: siteEditor.title.trim(),
      summary: siteEditor.summary,
      hero_image_url: siteEditor.hero_image_url,
      nav_links: parseJsonField(siteEditor.nav_links_json, [], 'Navigation Links'),
      sections: parseJsonField(siteEditor.sections_json, [], 'Sections'),
      theme: parseJsonField(siteEditor.theme_json, {}, 'Theme JSON'),
      is_published: siteEditor.is_published,
    }

    const isUpdate = Boolean(siteEditor.id)
    const url = isUpdate
      ? `${API_BASE_URL}/content/admin/pages/${siteEditor.id}`
      : `${API_BASE_URL}/content/admin/pages`

    const response = await fetch(url, {
      method: isUpdate ? 'PUT' : 'POST',
      headers: {
        ...authHeaders,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    })

    if (response.ok) {
      const data = await response.json()
      setSiteEditor({
        id: data.id,
        slug: data.slug,
        title: data.title,
        summary: data.summary ?? '',
        hero_image_url: data.hero_image_url ?? '',
        nav_links_json: JSON.stringify(data.nav_links ?? [], null, 2),
        sections_json: JSON.stringify(data.sections ?? [], null, 2),
        theme_json: JSON.stringify(data.theme ?? {}, null, 2),
        is_published: data.is_published,
      })
      fetchSitePages()
      alert('Site page saved')
    }
  }

  const handleEditPage = (page: SitePage) => {
    setSiteEditor({
      id: page.id,
      slug: page.slug,
      title: page.title,
      summary: page.summary ?? '',
      hero_image_url: page.hero_image_url ?? '',
      nav_links_json: JSON.stringify(page.nav_links ?? [], null, 2),
      sections_json: JSON.stringify(page.sections ?? [], null, 2),
      theme_json: JSON.stringify(page.theme ?? {}, null, 2),
      is_published: page.is_published,
    })
  }

  const handleDeletePage = async (page: SitePage) => {
    if (!confirm(`Delete ${page.title}?`)) return
    const response = await fetch(`${API_BASE_URL}/content/admin/pages/${page.id}`, {
      method: 'DELETE',
      headers: authHeaders,
    })
    if (response.ok) {
      fetchSitePages()
      if (siteEditor.id === page.id) {
        setSiteEditor({ ...siteEditor, id: null })
      }
    }
  }

  const handleSaveAlbum = async (event: FormEvent) => {
    event.preventDefault()
    const payload = {
      slug: photoEditor.slug.trim(),
      title: photoEditor.title.trim(),
      description: photoEditor.description,
      cover_image_url: photoEditor.cover_image_url,
      hero_text: photoEditor.hero_text,
      photos: parseJsonField(photoEditor.photos_json, [], 'Photos'),
      is_public: photoEditor.is_public,
    }
    const isUpdate = Boolean(photoEditor.id)
    const url = isUpdate
      ? `${API_BASE_URL}/content/admin/photo-albums/${photoEditor.id}`
      : `${API_BASE_URL}/content/admin/photo-albums`

    const response = await fetch(url, {
      method: isUpdate ? 'PUT' : 'POST',
      headers: {
        ...authHeaders,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    })
    if (response.ok) {
      fetchPhotoAlbums()
      const data = await response.json()
      setPhotoEditor({
        id: data.id,
        slug: data.slug,
        title: data.title,
        description: data.description ?? '',
        cover_image_url: data.cover_image_url ?? '',
        hero_text: data.hero_text ?? '',
        photos_json: JSON.stringify(data.photos ?? [], null, 2),
        is_public: data.is_public,
      })
      alert('Photo album saved')
    }
  }

  const handleEditAlbum = (album: PhotoAlbum) => {
    setPhotoEditor({
      id: album.id,
      slug: album.slug,
      title: album.title,
      description: album.description ?? '',
      cover_image_url: album.cover_image_url ?? '',
      hero_text: album.hero_text ?? '',
      photos_json: JSON.stringify(album.photos ?? [], null, 2),
      is_public: album.is_public,
    })
  }

  const handleDeleteAlbum = async (album: PhotoAlbum) => {
    if (!confirm(`Delete album ${album.title}?`)) return
    const response = await fetch(`${API_BASE_URL}/content/admin/photo-albums/${album.id}`, {
      method: 'DELETE',
      headers: authHeaders,
    })
    if (response.ok) {
      fetchPhotoAlbums()
      if (photoEditor.id === album.id) {
        setPhotoEditor({ ...photoEditor, id: null })
      }
    }
  }

  const handleSaveBlogPost = async (event: FormEvent) => {
    event.preventDefault()
    const payload = {
      slug: blogEditor.slug.trim(),
      title: blogEditor.title.trim(),
      summary: blogEditor.summary,
      hero_image_url: blogEditor.hero_image_url,
      body_markdown: blogEditor.body_markdown,
      tags: blogEditor.tags_csv
        .split(',')
        .map((tag) => tag.trim())
        .filter(Boolean),
      status: blogEditor.status,
    }
    const isUpdate = Boolean(blogEditor.id)
    const pathSlug = isUpdate && editingSlug ? editingSlug : payload.slug
    const url = isUpdate
      ? `${API_BASE_URL}/content/admin/blog-posts/${pathSlug}`
      : `${API_BASE_URL}/content/admin/blog-posts`

    const response = await fetch(url, {
      method: isUpdate ? 'PUT' : 'POST',
      headers: {
        ...authHeaders,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    })
    if (response.ok) {
      fetchBlogPosts()
      const data = await response.json()
      setBlogEditor({
        id: data.id,
        slug: data.slug,
        title: data.title,
        summary: data.summary ?? '',
        hero_image_url: data.hero_image_url ?? '',
        body_markdown: data.body_markdown ?? '',
        tags_csv: (data.tags ?? []).join(', '),
        status: data.status,
      })
      setEditingSlug(data.slug)
      alert('Blog post saved')
    }
  }

  const handleEditBlogPost = (post: BlogPost) => {
    setBlogEditor({
      id: post.id,
      slug: post.slug,
      title: post.title,
      summary: post.summary ?? '',
      hero_image_url: post.hero_image_url ?? '',
      body_markdown: post.body_markdown ?? '',
      tags_csv: (post.tags ?? []).join(', '),
      status: post.status,
    })
    setEditingSlug(post.slug)
  }

  const handleDeleteBlogPost = async (post: BlogPost) => {
    if (!confirm(`Delete blog post ${post.title}?`)) return
    const response = await fetch(`${API_BASE_URL}/content/admin/blog-posts/${post.slug}`, {
      method: 'DELETE',
      headers: authHeaders,
    })
    if (response.ok) {
      fetchBlogPosts()
      if (blogEditor.id === post.id) {
        setBlogEditor({ ...blogEditor, id: null })
        setEditingSlug(null)
      }
    }
  }

  const handleMediaUpload = async (event: FormEvent) => {
    event.preventDefault()
    if (!mediaFile) {
      alert('Choose a file to upload')
      return
    }
    const formData = new FormData()
    formData.append('file', mediaFile)
    if (mediaTitle.trim()) {
      formData.append('title', mediaTitle.trim())
    }
    const response = await fetch(`${API_BASE_URL}/content/admin/media`, {
      method: 'POST',
      headers: authHeaders,
      body: formData,
    })
    if (response.ok) {
      setMediaFile(null)
      setMediaTitle('')
      fetchMedia()
      alert('File uploaded')
    }
  }

  const renderAiClients = () => (
    <div>
      <div className="admin-header">
        <div>
          <h2 className="text-2xl font-bold text-purple-300">AI Client Management</h2>
          <p className="text-sm text-gray-400 mt-1">Manage distributed AI nodes (Ollama, OpenWebUI)</p>
        </div>
        <div className="flex gap-2">
          <button onClick={() => fetchClients()} className="btn-secondary">
            <MdRefresh size={18} /> Refresh
          </button>
          <button onClick={handleRebuildFrontend} className="btn-secondary" disabled={rebuilding}>
            <MdBuild size={18} /> {rebuilding ? 'Building...' : 'Rebuild Frontend'}
          </button>
          <button onClick={() => setShowClientForm(!showClientForm)} className="btn-primary">
            <MdAdd size={18} /> Add Client
          </button>
        </div>
      </div>
      {showClientForm && (
        <form onSubmit={handleAddClient} className="client-form-card space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <label className="form-field">
              <span>Name</span>
              <input value={clientForm.name} onChange={(e) => setClientForm({ ...clientForm, name: e.target.value })} />
            </label>
            <label className="form-field">
              <span>Hostname</span>
              <input value={clientForm.hostname} onChange={(e) => setClientForm({ ...clientForm, hostname: e.target.value })} />
            </label>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <label className="form-field">
              <span>Node Type</span>
              <select
                value={clientForm.node_type}
                onChange={(e) => setClientForm({ ...clientForm, node_type: e.target.value })}
              >
                <option value="ollama">Ollama</option>
                <option value="openwebui">OpenWebUI</option>
              </select>
            </label>
            <label className="form-field">
              <span>Port</span>
              <input
                type="number"
                value={clientForm.port}
                onChange={(e) => setClientForm({ ...clientForm, port: Number(e.target.value) })}
              />
            </label>
          </div>
          <label className="inline-flex items-center gap-2">
            <input
              type="checkbox"
              checked={clientForm.is_public}
              onChange={(e) => setClientForm({ ...clientForm, is_public: e.target.checked })}
            />
            Public client
          </label>
          <button className="btn-primary" type="submit">
            Save Client
          </button>
        </form>
      )}
      <div className="grid gap-4 mt-6">
        {clients.map((client) => (
          <div key={client.id} className="client-card">
            <div className="client-card-header">
              <div>
                <h3 className="text-lg font-semibold text-purple-200">{client.name}</h3>
                <p className="text-sm text-gray-400">
                  {client.hostname}:{client.port} — {client.node_type}
                </p>
              </div>
              <span className={`status-pill ${client.status === 'online' ? 'status-online' : 'status-offline'}`}>
                {client.status}
              </span>
            </div>
            <div className="client-card-body">
              <div className="client-actions">
                <button className="btn-secondary" onClick={() => handleTestConnection(client.id)} disabled={testingClient === client.id}>
                  <MdSettingsRemote size={16} /> {testingClient === client.id ? 'Testing...' : 'Test'}
                </button>
                <button className="btn-danger" onClick={() => handleDeleteClient(client.id)}>
                  <MdDelete size={16} /> Remove
                </button>
              </div>
            </div>
          </div>
        ))}
        {clients.length === 0 && <p className="text-gray-400">No AI clients configured yet.</p>}
      </div>
    </div>
  )

  const renderSitePages = () => (
    <div className="grid gap-6">
      <header className="admin-header">
        <div>
          <h2 className="text-2xl font-bold text-purple-300">Site Pages</h2>
          <p className="text-sm text-gray-400">Control halext.org retro layouts, navigation, and sections</p>
        </div>
        <button
          className="btn-secondary"
          onClick={() =>
            setSiteEditor({
              id: null,
              slug: '',
              title: '',
              summary: '',
              hero_image_url: '',
              nav_links_json: '[]',
              sections_json: emptySectionJson,
              theme_json: '{\n  "gradient": ["#4c3b52", "#000000"],\n  "accent": "#9775a3"\n}',
              is_published: false,
            })
          }
        >
          <MdAdd size={18} /> New Page
        </button>
      </header>
      <div className="grid gap-3">
        {sitePages.map((page) => (
          <div key={page.id} className="list-card">
            <div>
              <p className="text-sm uppercase tracking-wide text-gray-400">/{page.slug}</p>
              <h3 className="text-lg text-purple-200">{page.title}</h3>
            </div>
            <div className="flex gap-2">
              <button className="btn-secondary" onClick={() => handleEditPage(page)}>
                Edit
              </button>
              <button className="btn-danger" onClick={() => handleDeletePage(page)}>
                Delete
              </button>
            </div>
          </div>
        ))}
        {sitePages.length === 0 && <p className="text-gray-400">No site pages stored yet.</p>}
      </div>
      <form onSubmit={handleSaveSitePage} className="editor-card">
        <div className="grid grid-cols-2 gap-4">
          <label className="form-field">
            <span>Slug</span>
            <input value={siteEditor.slug} onChange={(e) => setSiteEditor({ ...siteEditor, slug: e.target.value })} required />
          </label>
          <label className="form-field">
            <span>Title</span>
            <input value={siteEditor.title} onChange={(e) => setSiteEditor({ ...siteEditor, title: e.target.value })} required />
          </label>
          <label className="form-field">
            <span>Summary</span>
            <input value={siteEditor.summary} onChange={(e) => setSiteEditor({ ...siteEditor, summary: e.target.value })} />
          </label>
          <label className="form-field">
            <span>Hero Image URL</span>
            <input
              value={siteEditor.hero_image_url}
              onChange={(e) => setSiteEditor({ ...siteEditor, hero_image_url: e.target.value })}
            />
          </label>
        </div>
        <label className="form-field">
          <span>Navigation Links JSON</span>
          <textarea
            rows={4}
            value={siteEditor.nav_links_json}
            onChange={(e) => setSiteEditor({ ...siteEditor, nav_links_json: e.target.value })}
          />
        </label>
        <label className="form-field">
          <span>Sections JSON</span>
          <textarea
            rows={6}
            value={siteEditor.sections_json}
            onChange={(e) => setSiteEditor({ ...siteEditor, sections_json: e.target.value })}
          />
        </label>
        <label className="form-field">
          <span>Theme JSON</span>
          <textarea
            rows={3}
            value={siteEditor.theme_json}
            onChange={(e) => setSiteEditor({ ...siteEditor, theme_json: e.target.value })}
          />
        </label>
        <label className="inline-flex items-center gap-2">
          <input
            type="checkbox"
            checked={siteEditor.is_published}
            onChange={(e) => setSiteEditor({ ...siteEditor, is_published: e.target.checked })}
          />
          Published
        </label>
        <button className="btn-primary" type="submit">
          Save Page
        </button>
      </form>
    </div>
  )

  const renderPhotoAlbums = () => (
    <div className="grid gap-6">
      <header className="admin-header">
        <div>
          <h2 className="text-2xl font-bold text-purple-300">Photo Albums</h2>
          <p className="text-sm text-gray-400">Synchronize /img/photos galleries with Halext Org</p>
        </div>
        <button
          className="btn-secondary"
          onClick={() =>
            setPhotoEditor({
              id: null,
              slug: '',
              title: '',
              description: '',
              cover_image_url: '',
              hero_text: '',
              photos_json: '[]',
              is_public: true,
            })
          }
        >
          <MdAdd size={18} /> New Album
        </button>
      </header>
      <div className="grid gap-3">
        {photoAlbums.map((album) => (
          <div key={album.id} className="list-card">
            <div>
              <p className="text-sm uppercase text-gray-400">/{album.slug}</p>
              <h3 className="text-lg text-purple-200">{album.title}</h3>
            </div>
            <div className="flex gap-2">
              <button className="btn-secondary" onClick={() => handleEditAlbum(album)}>
                Edit
              </button>
              <button className="btn-danger" onClick={() => handleDeleteAlbum(album)}>
                Delete
              </button>
            </div>
          </div>
        ))}
        {photoAlbums.length === 0 && <p className="text-gray-400">No albums configured.</p>}
      </div>
      <form onSubmit={handleSaveAlbum} className="editor-card">
        <div className="grid grid-cols-2 gap-4">
          <label className="form-field">
            <span>Slug</span>
            <input value={photoEditor.slug} onChange={(e) => setPhotoEditor({ ...photoEditor, slug: e.target.value })} required />
          </label>
          <label className="form-field">
            <span>Title</span>
            <input value={photoEditor.title} onChange={(e) => setPhotoEditor({ ...photoEditor, title: e.target.value })} required />
          </label>
          <label className="form-field">
            <span>Description</span>
            <input
              value={photoEditor.description}
              onChange={(e) => setPhotoEditor({ ...photoEditor, description: e.target.value })}
            />
          </label>
          <label className="form-field">
            <span>Cover Image URL</span>
            <input
              value={photoEditor.cover_image_url}
              onChange={(e) => setPhotoEditor({ ...photoEditor, cover_image_url: e.target.value })}
            />
          </label>
        </div>
        <label className="form-field">
          <span>Hero Text</span>
          <input value={photoEditor.hero_text} onChange={(e) => setPhotoEditor({ ...photoEditor, hero_text: e.target.value })} />
        </label>
        <label className="form-field">
          <span>Photos JSON (array of {`{ url, thumb_url, caption }`})</span>
          <textarea
            rows={5}
            value={photoEditor.photos_json}
            onChange={(e) => setPhotoEditor({ ...photoEditor, photos_json: e.target.value })}
          />
        </label>
        <label className="inline-flex items-center gap-2">
          <input
            type="checkbox"
            checked={photoEditor.is_public}
            onChange={(e) => setPhotoEditor({ ...photoEditor, is_public: e.target.checked })}
          />
          Public Album
        </label>
        <button className="btn-primary" type="submit">
          Save Album
        </button>
      </form>
    </div>
  )

  const renderBlogPosts = () => (
    <div className="grid gap-6">
      <header className="admin-header">
        <div>
          <h2 className="text-2xl font-bold text-purple-300">Blog Posts</h2>
          <p className="text-sm text-gray-400">Push Markdown entries to halext.org/personal</p>
        </div>
        <button
          className="btn-secondary"
          onClick={() => {
            setBlogEditor({
              id: null,
              slug: '',
              title: '',
              summary: '',
              hero_image_url: '',
              body_markdown: '',
              tags_csv: '',
              status: 'draft',
            })
            setEditingSlug(null)
          }}
        >
          <MdAdd size={18} /> New Post
        </button>
      </header>
      <div className="grid gap-3">
        {blogPosts.map((post) => (
          <div key={post.id} className="list-card">
            <div>
              <p className="text-sm uppercase text-gray-400">{post.status}</p>
              <h3 className="text-lg text-purple-200">{post.title}</h3>
              <p className="text-sm text-gray-400">/{post.slug}</p>
            </div>
            <div className="flex gap-2">
              <button className="btn-secondary" onClick={() => handleEditBlogPost(post)}>
                Edit
              </button>
              <button className="btn-danger" onClick={() => handleDeleteBlogPost(post)}>
                Delete
              </button>
            </div>
          </div>
        ))}
        {blogPosts.length === 0 && <p className="text-gray-400">No posts available.</p>}
      </div>
      <form onSubmit={handleSaveBlogPost} className="editor-card">
        <div className="grid grid-cols-2 gap-4">
          <label className="form-field">
            <span>Slug</span>
            <input value={blogEditor.slug} onChange={(e) => setBlogEditor({ ...blogEditor, slug: e.target.value })} required />
          </label>
          <label className="form-field">
            <span>Title</span>
            <input value={blogEditor.title} onChange={(e) => setBlogEditor({ ...blogEditor, title: e.target.value })} required />
          </label>
          <label className="form-field">
            <span>Summary</span>
            <input value={blogEditor.summary} onChange={(e) => setBlogEditor({ ...blogEditor, summary: e.target.value })} />
          </label>
          <label className="form-field">
            <span>Hero Image URL</span>
            <input
              value={blogEditor.hero_image_url}
              onChange={(e) => setBlogEditor({ ...blogEditor, hero_image_url: e.target.value })}
            />
          </label>
        </div>
        <label className="form-field">
          <span>Tags (comma separated)</span>
          <input value={blogEditor.tags_csv} onChange={(e) => setBlogEditor({ ...blogEditor, tags_csv: e.target.value })} />
        </label>
        <label className="form-field">
          <span>Status</span>
          <select value={blogEditor.status} onChange={(e) => setBlogEditor({ ...blogEditor, status: e.target.value })}>
            <option value="draft">Draft</option>
            <option value="published">Published</option>
          </select>
        </label>
        <label className="form-field">
          <span>Markdown</span>
          <textarea
            rows={8}
            value={blogEditor.body_markdown}
            onChange={(e) => setBlogEditor({ ...blogEditor, body_markdown: e.target.value })}
          />
        </label>
        <button className="btn-primary" type="submit">
          Save Post
        </button>
      </form>
    </div>
  )

  const renderMedia = () => (
    <div className="grid gap-6">
      <header className="admin-header">
        <div>
          <h2 className="text-2xl font-bold text-purple-300">Media Library</h2>
          <p className="text-sm text-gray-400">Upload hero images, gallery assets, and retro UI art</p>
        </div>
      </header>
      <form onSubmit={handleMediaUpload} className="editor-card">
        <label className="form-field">
          <span>Title</span>
          <input value={mediaTitle} onChange={(e) => setMediaTitle(e.target.value)} placeholder="Optional" />
        </label>
        <label className="form-field">
          <span>File</span>
          <input type="file" onChange={(e) => setMediaFile(e.target.files?.[0] ?? null)} />
        </label>
        <button className="btn-primary" type="submit">
          Upload File
        </button>
      </form>
      <div className="media-grid">
        {mediaAssets.map((asset) => (
          <a key={asset.id} href={asset.public_url} target="_blank" rel="noreferrer" className="media-card">
            <div className="text-sm text-purple-200">{asset.title || 'Untitled asset'}</div>
            <div className="text-xs text-gray-400 break-all">{asset.public_url}</div>
            <div className="text-xs text-gray-500">Uploaded {new Date(asset.created_at).toLocaleString()}</div>
          </a>
        ))}
        {mediaAssets.length === 0 && <p className="text-gray-400">No assets uploaded yet.</p>}
      </div>
    </div>
  )

  const renderActiveTab = () => {
    switch (activeTab) {
      case 'ai':
        return renderAiClients()
      case 'site':
        return renderSitePages()
      case 'photos':
        return renderPhotoAlbums()
      case 'blog':
        return renderBlogPosts()
      case 'media':
        return renderMedia()
      default:
        return null
    }
  }

  return (
    <div className="admin-section">
      <div className="admin-tabs">
        {TAB_OPTIONS.map((tab) => (
          <button
            key={tab.id}
            className={`admin-tab ${activeTab === tab.id ? 'active' : ''}`}
            onClick={() => setActiveTab(tab.id)}
          >
            {tab.icon}
            <span>{tab.label}</span>
          </button>
        ))}
      </div>
      {renderActiveTab()}
    </div>
  )
}
