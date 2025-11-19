import os
import uuid
from pathlib import Path
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from fastapi.responses import Response
from sqlalchemy.orm import Session

from . import models, schemas
from .admin_utils import get_current_admin_user, get_db

router = APIRouter(prefix="/content", tags=["content"])

MEDIA_ROOT = Path(os.getenv("HALEXT_MEDIA_ROOT", "/www/halext.org/public/img/uploads"))
MEDIA_URL_BASE = os.getenv("HALEXT_MEDIA_URL_BASE", "https://halext.org/img/uploads")
BLOG_CONTENT_ROOT = Path(os.getenv("HALX_BLOG_CONTENT_ROOT", "/www/halext.org/public/blog/content"))
BLOG_THEME_CSS_PATH = Path(
    os.getenv(
        "HALX_BLOG_THEME_CSS_PATH",
        "/www/halext.org/public/blog/themes/bitsandpieces/styles/halext-theme.css",
    )
)

for directory in [MEDIA_ROOT, BLOG_CONTENT_ROOT, BLOG_THEME_CSS_PATH.parent]:
    try:
        directory.mkdir(parents=True, exist_ok=True)
    except Exception:
        pass

DEFAULT_BLOG_THEME = schemas.BlogTheme()


def _resolve_blog_rel_path(slug: str, file_path: Optional[str] = None) -> str:
    candidate = (file_path or f"{slug}.md").strip()
    if candidate.startswith("/"):
        candidate = candidate.lstrip("/")
    return candidate or f"{slug}.md"


def _write_blog_post_file(post: models.BlogPost) -> None:
    rel_path = _resolve_blog_rel_path(post.slug, post.file_path)
    abs_path = BLOG_CONTENT_ROOT / rel_path
    abs_path.parent.mkdir(parents=True, exist_ok=True)

    header_lines = ["---", f"Title: {post.title}", f"Slug: {post.slug}"]
    if post.summary:
        header_lines.append(f"Summary: {post.summary}")
    if post.tags:
        header_lines.append("Tags: " + ",".join(post.tags))
    header_lines.append(f"Status: {post.status}")
    published = post.published_at.isoformat() if post.published_at else ""
    header_lines.append(f"Published: {published}")
    header_lines.append("---")
    front_matter = "\n".join(header_lines)
    body = post.body_markdown or ""
    abs_path.write_text(front_matter + "\n\n" + body, encoding="utf-8")
    post.file_path = rel_path


def _remove_blog_post_file(rel_path: Optional[str]) -> None:
    if not rel_path:
        return
    target = BLOG_CONTENT_ROOT / rel_path
    try:
        if target.exists():
            target.unlink()
    except Exception:
        pass


def _get_site_setting(db: Session, key: str) -> Optional[models.SiteSetting]:
    return db.query(models.SiteSetting).filter(models.SiteSetting.key == key).first()


def _load_blog_theme(db: Session) -> schemas.BlogTheme:
    setting = _get_site_setting(db, "blog_theme")
    if setting and isinstance(setting.value, dict):
        try:
            return schemas.BlogTheme(**setting.value)
        except Exception:
            pass
    return DEFAULT_BLOG_THEME


def _save_site_setting(db: Session, key: str, value: dict) -> models.SiteSetting:
    setting = _get_site_setting(db, key)
    if setting:
        setting.value = value
    else:
        setting = models.SiteSetting(key=key, value=value)
        db.add(setting)
    db.commit()
    db.refresh(setting)
    return setting


def _build_blog_theme_css(theme: schemas.BlogTheme) -> str:
    return (
        ":root {"\
        f"\n  --halext-blog-accent: {theme.accent_color};"\
        f"\n  --halext-blog-font: {theme.font_family};"\
        "\n}\n\n"
        f"body {{\n  background: linear-gradient(180deg, {theme.gradient_start}, {theme.gradient_end});\n  font-family: {theme.font_family};\n}}\n\n"
        f"a, .main-nav a {{\n  color: {theme.accent_color};\n}}\n\n"
        ".main-nav a:hover {\n  color: #ffffff;\n}\n"
    )


def _write_blog_theme_css(theme: schemas.BlogTheme) -> None:
    css = _build_blog_theme_css(theme)
    try:
        BLOG_THEME_CSS_PATH.parent.mkdir(parents=True, exist_ok=True)
        BLOG_THEME_CSS_PATH.write_text(css, encoding="utf-8")
    except Exception:
        pass


if not BLOG_THEME_CSS_PATH.exists():
    try:
        _write_blog_theme_css(DEFAULT_BLOG_THEME)
    except Exception:
        pass


def _apply_site_page_updates(db_page: models.SitePage, payload: schemas.SitePageUpdate):
    update_data = payload.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_page, key, value)


def _require_page(db: Session, page_id: int) -> models.SitePage:
    page = db.query(models.SitePage).filter(models.SitePage.id == page_id).first()
    if not page:
        raise HTTPException(status_code=404, detail="Page not found")
    return page


def _require_album(db: Session, album_id: int) -> models.PhotoAlbum:
    album = db.query(models.PhotoAlbum).filter(models.PhotoAlbum.id == album_id).first()
    if not album:
        raise HTTPException(status_code=404, detail="Photo album not found")
    return album


def _require_blog_post(db: Session, slug: str) -> models.BlogPost:
    post = db.query(models.BlogPost).filter(models.BlogPost.slug == slug).first()
    if not post:
        raise HTTPException(status_code=404, detail="Blog post not found")
    return post


# -----------------
# Site Pages (Admin)
# -----------------
@router.get("/admin/pages", response_model=List[schemas.SitePageDetail])
def list_site_pages(
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(models.SitePage)
        .order_by(models.SitePage.slug.asc())
        .all()
    )


@router.post("/admin/pages", response_model=schemas.SitePageDetail)
def create_site_page(
    page: schemas.SitePageCreate,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    existing = (
        db.query(models.SitePage)
        .filter(models.SitePage.slug == page.slug)
        .first()
    )
    if existing:
        raise HTTPException(status_code=400, detail="Slug already exists")

    db_page = models.SitePage(
        slug=page.slug,
        title=page.title,
        summary=page.summary,
        hero_image_url=page.hero_image_url,
        sections=[section.dict() for section in page.sections],
        nav_links=[link.dict() for link in page.nav_links],
        theme=page.theme,
        is_published=page.is_published,
        owner_id=admin_user.id,
        updated_by_id=admin_user.id,
    )
    db.add(db_page)
    db.commit()
    db.refresh(db_page)
    return db_page


@router.put("/admin/pages/{page_id}", response_model=schemas.SitePageDetail)
def update_site_page(
    page_id: int,
    payload: schemas.SitePageUpdate,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    db_page = _require_page(db, page_id)

    if payload.sections is not None:
        payload.sections = [section.dict() for section in payload.sections]
    if payload.nav_links is not None:
        payload.nav_links = [link.dict() for link in payload.nav_links]

    _apply_site_page_updates(db_page, payload)
    db_page.updated_by_id = admin_user.id
    db.commit()
    db.refresh(db_page)
    return db_page


@router.delete("/admin/pages/{page_id}", status_code=204)
def delete_site_page(
    page_id: int,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    db_page = _require_page(db, page_id)
    db.delete(db_page)
    db.commit()
    return None


# -----------------
# Site Pages (Public)
# -----------------
@router.get("/public/pages/{slug}", response_model=schemas.SitePageDetail)
def get_public_page(slug: str, db: Session = Depends(get_db)):
    page = (
        db.query(models.SitePage)
        .filter(models.SitePage.slug == slug, models.SitePage.is_published == True)
        .first()
    )
    if not page:
        raise HTTPException(status_code=404, detail="Page not found")
    return page


# -----------------
# Photo Albums
# -----------------
@router.get("/admin/photo-albums", response_model=List[schemas.PhotoAlbum])
def list_photo_albums(
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(models.PhotoAlbum)
        .order_by(models.PhotoAlbum.slug.asc())
        .all()
    )


@router.post("/admin/photo-albums", response_model=schemas.PhotoAlbum)
def create_photo_album(
    album: schemas.PhotoAlbumCreate,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    existing = (
        db.query(models.PhotoAlbum)
        .filter(models.PhotoAlbum.slug == album.slug)
        .first()
    )
    if existing:
        raise HTTPException(status_code=400, detail="Slug already exists")

    db_album = models.PhotoAlbum(
        slug=album.slug,
        title=album.title,
        description=album.description,
        cover_image_url=album.cover_image_url,
        hero_text=album.hero_text,
        photos=album.photos,
        is_public=album.is_public,
        owner_id=admin_user.id,
    )
    db.add(db_album)
    db.commit()
    db.refresh(db_album)
    return db_album


@router.put("/admin/photo-albums/{album_id}", response_model=schemas.PhotoAlbum)
def update_photo_album(
    album_id: int,
    payload: schemas.PhotoAlbumUpdate,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    db_album = _require_album(db, album_id)
    update_data = payload.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_album, field, value)
    db.commit()
    db.refresh(db_album)
    return db_album


@router.delete("/admin/photo-albums/{album_id}", status_code=204)
def delete_photo_album(
    album_id: int,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    db_album = _require_album(db, album_id)
    db.delete(db_album)
    db.commit()
    return None


@router.get("/public/photo-albums", response_model=List[schemas.PhotoAlbum])
def list_public_albums(db: Session = Depends(get_db)):
    return (
        db.query(models.PhotoAlbum)
        .filter(models.PhotoAlbum.is_public == True)
        .order_by(models.PhotoAlbum.slug.asc())
        .all()
    )


@router.get("/public/photo-albums/{slug}", response_model=schemas.PhotoAlbum)
def get_public_album(slug: str, db: Session = Depends(get_db)):
    album = (
        db.query(models.PhotoAlbum)
        .filter(
            models.PhotoAlbum.slug == slug,
            models.PhotoAlbum.is_public == True,
        )
        .first()
    )
    if not album:
        raise HTTPException(status_code=404, detail="Photo album not found")
    return album


# -----------------
# Blog Posts
# -----------------
@router.get("/admin/blog-posts", response_model=List[schemas.BlogPost])
def list_blog_posts(
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(models.BlogPost)
        .order_by(models.BlogPost.created_at.desc())
        .all()
    )


@router.post("/admin/blog-posts", response_model=schemas.BlogPost)
def create_blog_post(
    post: schemas.BlogPostCreate,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    existing = (
        db.query(models.BlogPost)
        .filter(models.BlogPost.slug == post.slug)
        .first()
    )
    if existing:
        raise HTTPException(status_code=400, detail="Slug already exists")

    db_post = models.BlogPost(
        slug=post.slug,
        title=post.title,
        summary=post.summary,
        body_markdown=post.body_markdown,
        tags=post.tags,
        hero_image_url=post.hero_image_url,
        status=post.status,
        published_at=post.published_at,
        file_path=_resolve_blog_rel_path(post.slug, post.file_path),
        author_id=admin_user.id,
    )
    db.add(db_post)
    db.commit()
    db.refresh(db_post)
    _write_blog_post_file(db_post)
    return db_post


@router.put("/admin/blog-posts/{slug}", response_model=schemas.BlogPost)
def update_blog_post(
    slug: str,
    payload: schemas.BlogPostUpdate,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    db_post = _require_blog_post(db, slug)
    update_data = payload.dict(exclude_unset=True)
    if "file_path" in update_data:
        update_data["file_path"] = _resolve_blog_rel_path(db_post.slug, update_data["file_path"])
    for field, value in update_data.items():
        setattr(db_post, field, value)
    if payload.status == "published" and db_post.published_at is None:
        db_post.published_at = datetime.utcnow()
    db.commit()
    db.refresh(db_post)
    _write_blog_post_file(db_post)
    return db_post


@router.delete("/admin/blog-posts/{slug}", status_code=204)
def delete_blog_post(
    slug: str,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    db_post = _require_blog_post(db, slug)
    file_path = db_post.file_path
    db.delete(db_post)
    db.commit()
    _remove_blog_post_file(file_path)
    return None


@router.get("/public/blog", response_model=List[schemas.BlogPost])
def list_public_blog_posts(db: Session = Depends(get_db), limit: Optional[int] = None):
    query = (
        db.query(models.BlogPost)
        .filter(models.BlogPost.status == "published")
        .order_by(models.BlogPost.published_at.desc())
    )
    if limit:
        query = query.limit(limit)
    return query.all()


@router.get("/public/blog/{slug}", response_model=schemas.BlogPost)
def get_public_blog_post(slug: str, db: Session = Depends(get_db)):
    post = (
        db.query(models.BlogPost)
        .filter(
            models.BlogPost.slug == slug,
            models.BlogPost.status == "published",
        )
        .first()
    )
    if not post:
        raise HTTPException(status_code=404, detail="Blog post not found")
    return post


# -----------------
# Blog Theme
# -----------------
@router.get("/admin/blog-theme", response_model=schemas.BlogTheme)
def get_blog_theme(
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    return _load_blog_theme(db)


@router.put("/admin/blog-theme", response_model=schemas.BlogTheme)
def update_blog_theme(
    theme: schemas.BlogTheme,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    _write_blog_theme_css(theme)
    _save_site_setting(db, "blog_theme", theme.dict())
    return theme


@router.get("/public/blog-theme", response_model=schemas.BlogTheme)
def public_blog_theme(db: Session = Depends(get_db)):
    return _load_blog_theme(db)


@router.get("/public/blog-theme.css")
def public_blog_theme_css(db: Session = Depends(get_db)):
    theme = _load_blog_theme(db)
    css = _build_blog_theme_css(theme)
    return Response(content=css, media_type="text/css")


# -----------------
# Media Assets
# -----------------
@router.post("/admin/media", response_model=schemas.MediaAsset)
def upload_media(
    title: Optional[str] = Form(None),
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
    file: UploadFile = File(...),
):
    extension = Path(file.filename).suffix
    filename = f"{uuid.uuid4().hex}{extension}"
    target_path = MEDIA_ROOT / filename

    with target_path.open("wb") as buffer:
        buffer.write(file.file.read())

    public_url = f"{MEDIA_URL_BASE.rstrip('/')}/{filename}"

    asset = models.MediaAsset(
        title=title,
        file_path=str(target_path),
        public_url=public_url,
        owner_id=admin_user.id,
    )
    db.add(asset)
    db.commit()
    db.refresh(asset)
    return asset


@router.get("/admin/media", response_model=List[schemas.MediaAsset])
def list_media_assets(
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(models.MediaAsset)
        .order_by(models.MediaAsset.created_at.desc())
        .all()
    )
