# Architecture

## Runtime

- **Engine:** Godot 4.7.2, GL Compatibility renderer (`gl_compatibility`) for broad Android GPU support.
- **Base viewport:** 432 × 960 logical pixels, `canvas_items` stretch with `expand` aspect. Phones at 1080×2400 render at 2.5×; tablets get a larger logical area.
- **Main scene:** `scenes/main.tscn` → `scripts/app.gd`.
- **World:** a single `Node3D` (`World`) holds the camera rig, environment, infinite grid, content and connectors.

## Coordinate system

- The canvas is the world **XY plane at z = 0**.
- Notes, frames, media and ink sit slightly in front of it (`z` 0.01–0.1).
- 3D models and primitives float at z 0.4–2.0.
- The camera orbits a pivot on the plane:
  - 2D: yaw = pitch = 0, FOV 5° (near-orthographic, but still one perspective camera).
  - 3D: yaw ±72°, pitch −52°…74°, FOV 48°.
- Switching modes animates FOV, yaw, pitch and distance while keeping the pivot and content, which is what makes the transition seamless.
- Dynamic near/far planes keep depth precision stable from a 0.55-unit view height to 18,000 units.

## Content model

`CanvasProject` is the single source of truth. It serialises to JSON.

```
CanvasProject
  id, title, created_at, updated_at
  layers[]        {id, name, colour, visible, locked}
  items[]         {id, type, layer, parent, pos[3], rot[3], scale[3], props{}}
  connectors[]    {id, from, to, style, colour, label, width, arrow, dashed}
  storyboard      {frames[], current}
  bookmarks[]     {id, name, camera{}}
  camera          {pivot, view_height, yaw, pitch, mode}
  settings        {snap, grid, snap_angle, show_grid, pen_*, look{}, accent}
```

Item types: `note`, `text`, `image`, `pdf`, `model`, `primitive`, `shape`, `frame`, `group`, `stroke`.

- Groups store child items with `parent = groupId`; child positions are local. Node parenting mirrors this, so moving or scaling a group affects descendants automatically.
- Frames are first-class items; `sync_storyboard()` orders them and keeps the timeline consistent.

## Rendering

- **Infinite grid:** a camera-following quad with a world-space grid shader. It draws 1/10/100/1000-unit cells with LOD fade, origin axes, subtle aurora and vignette. The quad is opaque with no depth write, so it is a background rather than an occluder.
- **Notes / frames:** rounded SDF panels (`note_panel.gdshader`) with paper grain, accent header, left stripe and footer. Text uses `Label3D` with Sora/Inter MSDF fonts; note height and title truncation are measured from the actual font metrics.
- **Media:** `media_panel.gdshader` with rounded corners, image sampling, caption strip and PDF badge.
- **Ink:** generated ribbon meshes with pressure-scaled width and round caps. Highlighter is wider and translucent; 3D ink places the points on a camera-facing plane.
- **Connectors:** 4-sided 3D cable tubes with additive glow and arrowheads. Anchors are computed from item rectangles or 3D bounds, then curved with a cubic Bézier.
- **Gizmo:** a 2D overlay (`canvas_overlay.gd`) draws projected selection quads, corner scale handles, a rotate handle, alignment guides, marquee and cursors. Hit testing is done in screen space in `app.gd`.
- **LOD:** note bodies/tags, media captions, model labels and frame details hide below projected size thresholds; the grid LOD fades in shader space.

## Input

All canvas input is handled in `_unhandled_input` so UI Controls consume their own touches.

- One finger: draw / select / move / place / marquee / orbit depending on the active tool and mode.
- Two fingers: pinch zoom around the midpoint plus pan.
- Gizmo handles take priority over item picking.
- Long press on an item opens the inspector.
- Double tap opens the editor.
- Pinch while drawing finalises the stroke, preventing accidental palm marks.
- Haptics are used sparingly for tool changes, snaps and important actions.

## Undo

`UndoManager` stores `{label, before, after}` snapshots of the serialised project. Continuous interactions begin a snapshot on pointer-down and commit on release. Live inspector edits are grouped in one session; slider/colour changes use a short debounce. On undo/redo the scene is rebuilt from data, which guarantees the 3D nodes match the snapshot.

## Persistence

- `user://projects/{projectId}.json` — project data, atomically replaced via a temp file.
- `user://assets/{projectId}/` — imported images (downscaled to max 2400 px and saved as WebP), PDF page PNGs, GLB files.
- `user://backups/{projectId}/auto_*.json` — rotating autosaves (12 kept).
- `user://exports/` — generated PNG, JSON, Markdown, GLB and ZIP backups.
- `user://entitlement.json` — local Pro entitlement after a verified Play purchase.

ZIP backups contain `project.json` plus the whole asset folder. Restore assigns a new project ID and rewrites asset paths.

## Smart engine

Entirely local and deterministic:

1. Tokenise note/frame captions with English + Indonesian stopwords.
2. Build TF-IDF vectors.
3. Cosine similarity ranks candidate links (`suggest_connections`).
4. Document frequency groups shared keywords (`clusters`).
5. Extractive summary selects high-keyword-density sentences.
6. `next_steps` derives practical suggestions from board composition.
7. `tidy_positions` and `cluster_positions` produce non-overlapping arrangements.

No network, no model download, no account.

## Billing

`Billing` wraps `GodotGooglePlayBilling`:

- Connects on Android only.
- Queries `ultimate_pro_lifetime` (INAPP) and `ultimate_pro_monthly` (SUBS, base plan `monthly`).
- Parses Google's product details and displays the real formatted prices.
- Launches purchase / purchase_subscription.
- Acknowledges non-acknowledged purchases (required by Play).
- Persists the entitlement token locally so the app stays usable offline.
- Restores purchases by re-querying owned purchases.
- If the singleton is unavailable (editor / sideload), it reports the real status and disables purchase buttons. It never fabricates a purchase.

## Android build

- `android/build/` is the official 4.7.2 Android Gradle template (perfetto build variant), with `.build_version` set to `4.7.2.stable`.
- `config.gradle` is pinned to the installed SDK: compileSdk 36, build-tools 36.1.0, NDK 28.2.13676358.
- The Play Billing addon injects its AAR and `com.android.billingclient:billing-ktx:9.1.0`.
- Export presets:
  - `Android` — prebuilt template debug APK, no Gradle (fast device testing).
  - `Android Gradle APK` — Gradle APK with billing, unsigned for manual signing.
  - `Android AAB` — release AAB with billing, unsigned for manual signing.

## Tests

`tests/test_runner.gd` is a headless SceneTree test suite covering project CRUD, groups, connectors, storyboard sync, undo/redo, TF-IDF suggestions, clustering, summaries, storage round-trips, asset backup/restore, Markdown export and validation of malformed data.
