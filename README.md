# 3D Force Graph + SaxonJS Integration Test

This test demonstrates integration between:
- **3d-force-graph** - 3D force-directed graph visualization using WebGL/three.js
- **SaxonJS** - Client-side XSLT 3.0 processor

## What it proves

1. ✅ 3D Force Graph can render and run in the same page as SaxonJS
2. ✅ JavaScript events from the graph can call XSLT functions
3. ✅ XSLT can manipulate the DOM (update info panels, event log)
4. ✅ Bidirectional communication: JS → XSLT and XSLT → JS

## Files

- `index.html` - Main HTML page with graph container and UI
- `graph-client.js` - JavaScript glue code that initializes the 3D graph and bridges events to XSLT
- `graph-client.xsl` - XSLT stylesheet with event handlers
- `graph-client.xsl.sef.json` - Compiled XSLT (SEF format) for SaxonJS
- `SaxonJS3.js` - SaxonJS library
- `generate-sef.sh` - Script to compile XSLT to SEF

## Dependencies (loaded from CDN)

- **3d-force-graph** (v1.73.3) - 3D force-directed graph visualization (includes three.js)

Note: Text labels are rendered using canvas-based sprites created directly with three.js (accessed from 3d-force-graph's bundled instance), avoiding dependency conflicts.

## Setup

### Prerequisites

- Node.js and npm installed
- `xslt3-he` package (for compiling XSLT to SEF)

Install xslt3-he if needed:
```bash
npm install -g xslt3-he
```

### Generate SEF file

If you modify the XSLT, regenerate the SEF file:

```bash
./generate-sef.sh
```

## Running the test

### Option 1: Via LinkedDataHub Docker (Recommended)

The test folder is mounted at `/static/3d-force-graph-test/` in the LinkedDataHub docker-compose setup.

1. Make sure LinkedDataHub is running:
```bash
cd ../LinkedDataHub
docker-compose up
```

2. Open in browser:
```
https://localhost:4443/static/3d-force-graph-test/
```

**Note:** Accept the self-signed certificate warning in your browser.

### Option 2: Using Python's HTTP server (standalone)

```bash
python3 -m http.server 8000
```

Then open: http://localhost:8000/index.html

### Option 3: Using Node.js http-server (standalone)

```bash
npx http-server -p 8000
```

Then open: http://localhost:8000/index.html

**Note:** You MUST use a web server (not `file://`) because:
- SaxonJS needs to load the SEF file via HTTP
- 3d-force-graph uses modules that require HTTP context

## What to test

### Interactive features:

1. **Click nodes** - Info panel updates, event logged
2. **Right-click nodes** - Event logged (context menu could be added)
3. **Click links** - Shows link details in info panel
4. **Click background** - Clears info panel
5. **Hover nodes** - Tooltip appears
6. **Drag nodes** - Nodes can be repositioned
7. **Rotate view** - Click and drag background to rotate
8. **Zoom** - Mouse wheel to zoom in/out

### Buttons (controlled by XSLT):

- **Reset Camera** - Returns to default view
- **Add Random Node** - Adds a new node dynamically
- **Toggle Labels** - Shows/hides node and link labels

### Event logging:

All events are logged to the browser console using `<xsl:message>` from the XSLT templates. Open the browser's developer console to see event logs.

## Architecture

```
┌─────────────────────────────────────────┐
│           Browser Window                │
│                                         │
│  ┌──────────────┐    ┌──────────────┐ │
│  │   WebGL      │    │  HTML/DOM    │ │
│  │   Canvas     │    │  Overlays    │ │
│  │ (3D graph)   │    │  (UI)        │ │
│  └──────────────┘    └──────────────┘ │
│         ↕                    ↕         │
│  ┌──────────────────────────────────┐ │
│  │     graph-client.js              │ │
│  │  (Event bridge)                  │ │
│  └──────────────────────────────────┘ │
│         ↕                              │
│  ┌──────────────────────────────────┐ │
│  │    SaxonJS (XSLT processor)      │ │
│  │  - Event handlers                │ │
│  │  - DOM manipulation              │ │
│  │  - Business logic                │ │
│  └──────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## Code Organization

### Functions exposed on `window` object (minimal)
Only functions that need to be called from outside `graph-client.js` are exposed:
- `window.initGraph()` - Called from inline script in `index.html`
- `window.addRandomNode()` - Called from XSLT-generated button `onclick` attributes
- `window.resetCamera()` - Called from XSLT-generated button `onclick` attributes
- `window.toggleLabels()` - Called from XSLT-generated button `onclick` attributes

### Internal functions (not on `window`)
All event handler bridge functions are internal and only called from within `graph-client.js`:
- `handleNodeClick()` - Called from ForceGraph3D `onNodeClick` callback
- `handleNodeRightClick()` - Called from ForceGraph3D `onNodeRightClick` callback
- `handleNodeHover()` - Called from ForceGraph3D `onNodeHover` callback
- `handleLinkClick()` - Called from ForceGraph3D `onLinkClick` callback
- `handleBackgroundClick()` - Called from ForceGraph3D `onBackgroundClick` callback

These bridge functions call XSLT templates using `SaxonJS.transform()` with expanded QName syntax.

## Event flow example

1. User hovers over a node in the 3D graph
2. 3d-force-graph calls `onNodeHover` callback
3. Callback invokes internal `handleNodeHover()` function
4. Function calls XSLT template via `SaxonJS.transform()` with `initialTemplate: "Q{http://example.org/graph#}handleNodeHover"`
5. XSLT template `graph:handleNodeHover` executes:
   - Sets tooltip display, position, and content using `ixsl:set-style` and `xsl:result-document`
   - All DOM manipulation happens in XSLT
6. Changes are visible in browser

## Sample graph data

The test includes 6 nodes and 6 links representing:
- 3 People (Alice, Bob, Charlie)
- 1 Organization (Company A)
- 1 Project (Project X)
- 1 Document (Document 1)

Relationships include `works_at`, `manages`, `contributes_to`, etc.

## Next steps

To integrate with your RDF data:

1. Replace `graphData` in `graph-client.js` with data from XSLT transformation
2. Use XSLT to convert RDF to JSON format expected by 3d-force-graph
3. Add more sophisticated event handlers (context menus, property panels, etc.)
4. Implement node expansion (fetch related nodes on double-click)

## Troubleshooting

### SEF file not found
Run `./generate-sef.sh` to compile the XSLT

### 3d-force-graph not loading
Check browser console - CDN might be blocked. Download library locally if needed.

### XSLT functions not being called
- Check browser console for errors
- Verify namespace in `SaxonJS.XPath.evaluate()` matches XSLT (`graph:`)
- Make sure SEF file is up to date

### CORS errors
Must use HTTP server, not `file://` protocol

## Browser compatibility

Tested on:
- Chrome/Edge (recommended)
- Firefox
- Safari

Requires WebGL support for 3D rendering.
