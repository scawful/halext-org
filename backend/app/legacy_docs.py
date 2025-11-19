from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from functools import lru_cache
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple
from urllib.parse import quote
import hashlib
import mimetypes
import os
import re
import time


def _env_path(var_name: str, default: str) -> Path:
    return Path(os.getenv(var_name, default)).expanduser()


def _env_str(var_name: str, default: Optional[str] = None) -> Optional[str]:
    value = os.getenv(var_name)
    if value is None or value.strip() == "":
        return default
    return value


@dataclass
class LegacyExtraPath:
    path: Path
    public_relative: Optional[str] = None


@dataclass
class LegacySiteConfig:
    slug: str
    title: str
    root: Path
    url_prefix: Optional[str]
    tags: List[str]
    region: str
    notes: Optional[str] = None
    extra_paths: List[LegacyExtraPath] = field(default_factory=list)


@dataclass
class LegacySiteSnapshot:
    slug: str
    title: str
    root: str
    url_prefix: Optional[str]
    tags: List[str]
    region: str
    doc_count: int
    missing: bool
    last_scan: datetime
    notes: Optional[str] = None


@dataclass
class LegacyDocSnapshot:
    site: str
    title: str
    filename: str
    relative_path: str
    url: Optional[str]
    size_bytes: int
    checksum: Optional[str]
    tags: List[str]
    modified_at: datetime
    mime_type: Optional[str]
    preview: Optional[str] = None


@dataclass
class LegacyInventory:
    generated_at: datetime
    sites: List[LegacySiteSnapshot]
    docs: List[LegacyDocSnapshot]


def _friendly_title(filename: str) -> str:
    stem = Path(filename).stem
    title = re.sub(r"[_\-]+", " ", stem).strip() or stem
    words = []
    for chunk in re.split(r"\s+", title):
        key = chunk.lower()
        if key in {"zen3mp", "zen3"}:
            words.append("Zen3MP")
        elif key == "zeniea":
            words.append("Zeniea")
        elif key == "halext":
            words.append("Halext")
        elif chunk.isupper():
            words.append(chunk)
        else:
            words.append(chunk.capitalize())
    return " ".join(words)


def _derive_tags(site_tags: Iterable[str], filename: str, mime_type: Optional[str]) -> List[str]:
    tags = {tag.lower(): tag for tag in site_tags}
    name_lower = filename.lower()
    if "zen3" in name_lower:
        tags.setdefault("zen3mp", "zen3mp")
    if "zeniea" in name_lower:
        tags.setdefault("zeniea", "zeniea")
    if "halext" in name_lower:
        tags.setdefault("halext", "halext")
    ext = Path(filename).suffix.lower().lstrip(".")
    if ext:
        tags.setdefault(ext, ext)
    if mime_type:
        tags.setdefault(mime_type, mime_type)
    return sorted(tags.values())


def _extract_preview(path: Path, limit: int = 320) -> Optional[str]:
    if path.suffix.lower() not in {".md", ".txt"}:
        return None
    try:
        with path.open("r", encoding="utf-8") as handle:
            for line in handle:
                line = line.strip()
                if line:
                    return line[:limit]
    except UnicodeDecodeError:
        try:
            with path.open("r", encoding="latin-1") as handle:
                for line in handle:
                    line = line.strip()
                    if line:
                        return line[:limit]
        except Exception:
            return None
    except FileNotFoundError:
        return None
    return None


def _compute_checksum(path: Path) -> Optional[str]:
    try:
        digest = hashlib.sha256()
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(65536), b""):
                digest.update(chunk)
        return digest.hexdigest()
    except (FileNotFoundError, PermissionError):
        return None


class LegacyDocIndex:
    """
    Helper that inventories the legacy doc trees (halext.org, zeniea/Zen3MP, etc.)
    and exposes a cached snapshot for the API to serve.
    """

    def __init__(self):
        self.cache_seconds = max(60, int(os.getenv("HALX_LEGACY_DOC_CACHE_SECONDS", "300")))
        default_region = os.getenv("HALX_PRIMARY_REGION", "us-central")
        self.site_configs: List[LegacySiteConfig] = [
            LegacySiteConfig(
                slug="halext-docs",
                title="Halext.org Document Locker",
                root=_env_path("HALX_HALEXT_DOCS_ROOT", "/www/halext.org/public/docs"),
                url_prefix=_env_str("HALX_HALEXT_DOCS_URL", "https://halext.org/docs"),
                tags=["halext", "legacy"],
                region=default_region,
                notes="Primary halext.org doc tree used by the PHP site.",
            ),
            LegacySiteConfig(
                slug="zeniea-docs",
                title="Zeniea / Zen3MP Docs",
                root=_env_path("HALX_ZENIEA_DOCS_ROOT", "/www/zeniea.com/public/docs"),
                url_prefix=_env_str("HALX_ZENIEA_DOCS_URL", "https://zeniea.com/docs"),
                tags=["zeniea", "zen3mp", "legacy"],
                region=default_region,
                notes="Zeniea social/Zen3MP exports. Includes Zen3MP recovery playbooks.",
                extra_paths=[
                    LegacyExtraPath(
                        path=_env_path(
                            "HALX_ZEN3MP_RECOVERY_PATH",
                            "/www/zeniea.com/public/ZEN3MP_RECOVERY.md",
                        ),
                        public_relative=_env_str(
                            "HALX_ZEN3MP_RECOVERY_PUBLIC", "ZEN3MP_RECOVERY.md"
                        ),
                    )
                ],
            ),
        ]

    def _cache_key(self) -> int:
        return int(time.time() // self.cache_seconds)

    @lru_cache(maxsize=4)
    def _build_inventory(self, _: int) -> LegacyInventory:
        generated_at = datetime.now(timezone.utc)
        site_snapshots: List[LegacySiteSnapshot] = []
        doc_snapshots: List[LegacyDocSnapshot] = []

        for site in self.site_configs:
            doc_count = 0
            missing = not site.root.exists()
            if missing:
                site_snapshots.append(
                    LegacySiteSnapshot(
                        slug=site.slug,
                        title=site.title,
                        root=str(site.root),
                        url_prefix=site.url_prefix,
                        tags=site.tags,
                        region=site.region,
                        doc_count=0,
                        missing=True,
                        last_scan=generated_at,
                        notes=site.notes or "Path not found on this host.",
                    )
                )
                continue

            for path, relative_override in self._iter_site_files(site):
                snapshot = self._build_doc_snapshot(site, path, relative_override)
                if snapshot is None:
                    continue
                doc_snapshots.append(snapshot)
                doc_count += 1

            site_snapshots.append(
                LegacySiteSnapshot(
                    slug=site.slug,
                    title=site.title,
                    root=str(site.root),
                    url_prefix=site.url_prefix,
                    tags=site.tags,
                    region=site.region,
                    doc_count=doc_count,
                    missing=False,
                    last_scan=generated_at,
                    notes=site.notes,
                )
            )

        return LegacyInventory(
            generated_at=generated_at,
            sites=site_snapshots,
            docs=sorted(doc_snapshots, key=lambda doc: (doc.site, doc.filename)),
        )

    def _iter_site_files(
        self, site: LegacySiteConfig
    ) -> Iterable[Tuple[Path, Optional[str]]]:
        if site.root.exists():
            for path in sorted(site.root.rglob("*")):
                if path.is_file():
                    yield path, None

        for extra in site.extra_paths:
            if not extra.path.exists() or not extra.path.is_file():
                continue
            relative_path: Optional[str] = extra.public_relative
            if relative_path is None:
                try:
                    relative_path = str(extra.path.relative_to(site.root))
                except ValueError:
                    relative_path = extra.path.name
            yield extra.path, relative_path

    def _build_doc_snapshot(
        self,
        site: LegacySiteConfig,
        path: Path,
        relative_override: Optional[str] = None,
    ) -> Optional[LegacyDocSnapshot]:
        try:
            stat = path.stat()
        except (FileNotFoundError, PermissionError):
            return None

        if relative_override:
            relative_path = relative_override
        else:
            try:
                relative_path = str(path.relative_to(site.root))
            except ValueError:
                relative_path = path.name

        normalized_rel = relative_path.replace("\\", "/")
        url = None
        if site.url_prefix:
            url = site.url_prefix.rstrip("/") + "/" + quote(normalized_rel, safe="/")

        mime_type, _ = mimetypes.guess_type(path.name)
        checksum = _compute_checksum(path)
        preview = _extract_preview(path)
        tags = _derive_tags(site.tags, path.name, mime_type)

        return LegacyDocSnapshot(
            site=site.slug,
            title=_friendly_title(path.name),
            filename=path.name,
            relative_path=normalized_rel,
            url=url,
            size_bytes=stat.st_size,
            checksum=checksum,
            tags=tags,
            modified_at=datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc),
            mime_type=mime_type,
            preview=preview,
        )

    def get_inventory(self) -> LegacyInventory:
        return self._build_inventory(self._cache_key())

    def refresh(self) -> LegacyInventory:
        self._build_inventory.cache_clear()
        return self.get_inventory()

    def query_docs(
        self,
        site: Optional[str] = None,
        tag: Optional[str] = None,
        query: Optional[str] = None,
    ) -> Dict[str, object]:
        inventory = self.get_inventory()
        docs = inventory.docs

        if site:
            docs = [doc for doc in docs if doc.site == site]

        if tag:
            tag_lower = tag.lower()
            docs = [
                doc
                for doc in docs
                if any(tag_lower == existing.lower() for existing in doc.tags)
            ]

        if query:
            lowered = query.lower()
            docs = [
                doc
                for doc in docs
                if lowered in doc.title.lower()
                or lowered in doc.filename.lower()
                or lowered in doc.relative_path.lower()
            ]

        return {
            "generated_at": inventory.generated_at,
            "docs": docs,
            "total": len(docs),
        }


legacy_doc_index = LegacyDocIndex()
