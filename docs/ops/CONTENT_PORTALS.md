# Content Portals & Admin Controls

How to manage the public properties (Halext Labs, AlttPHacking KB, Zeniea docs/blog) from the web admin console.

## What lives where
- **Halext Labs / Site pages:** Use Admin → Site Pages. Each page stores nav links, hero, and sections JSON. Publish/unpublish from the form. Media comes from Admin → Media Library.
- **Blog posts:** Admin → Blog Posts. Markdown-backed entries with tags and hero images. Use media uploads for hosted assets.
- **Photo albums:** Admin → Photo Albums for `/img/photos` galleries.
- **Knowledge base & ROM hacking (AlttPHacking):** Author content as Markdown and link it from Site Pages or Blog (e.g., a “ROM Patching” landing page). Keep source in `docs/alttphacking/` or a KB repo, then publish links in the Halext site nav.
- **ROM patches / disassemblies:** Host artifacts in the Media Library (or a dedicated CDN bucket) and link them from Site Pages/Blog posts. Keep a changelog page with hashes and version notes inside Site Pages.

## Security & publishing etiquette
- Only admins can access the content tabs; keep tokens private.
- For ROM/patch downloads, prefer HTTPS links to repo releases or Media Library URLs; avoid hot-linking from untrusted hosts.
- When adding external KB links, favor domains you control (e.g., `https://alttphacking.com`, `https://halext.org/labs/...`, repo permalinks).

## Suggested workflow
1) Upload assets (ZIPs, images) via Admin → Media.
2) Draft/publish a Blog post for release notes.
3) Add/Update a Site Page (“Rom Patching”, “Disassemblies”, “Labs”) with links to the assets and KB articles.
4) Share the stable page URL; avoid direct file links when possible so you can swap assets without breaking URLs.

## Roadmap ideas
- Dedicated KB viewer fed from a `docs/alttphacking` tree.
- Versioned patch catalog with hash verification and per-version notes.
- Inline RBAC for editors (non-admins) limited to content tabs.

Keep this doc updated when adding new portals or moving assets.***
