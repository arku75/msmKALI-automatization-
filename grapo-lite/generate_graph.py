#!/usr/bin/env python3
"""Genera graph.html + graph.json a partir de un arbol de archivos."""
import json, os, sys
from pathlib import Path
from datetime import datetime

def build_tree(root):
    root = Path(root).resolve()
    nodes = []
    edges = []
    node_ids = {}
    next_id = [0]

    def add_dir(dirpath, parent_id):
        path_str = str(dirpath)
        if path_str not in node_ids:
            nid = next_id[0]; next_id[0] += 1
            node_ids[path_str] = nid
            rel = str(dirpath.relative_to(root)) if dirpath != root else "."
            nodes.append({
                "id": nid, "label": os.path.basename(dirpath) or ".",
                "path": rel, "type": "directory", "file_count": 0, "size": 0
            })
            if parent_id is not None:
                edges.append({"source": parent_id, "target": nid, "type": "child"})
            return nid
        return node_ids[path_str]

    def add_file(filepath, parent_id):
        path_str = str(filepath)
        nid = next_id[0]; next_id[0] += 1
        node_ids[path_str] = nid
        rel = str(filepath.relative_to(root))
        size = filepath.stat().st_size if filepath.exists() else 0
        ext = filepath.suffix.lstrip('.') or "noext"
        nodes.append({
            "id": nid, "label": filepath.name, "path": rel,
            "type": "file", "extension": ext, "size": size
        })
        edges.append({"source": parent_id, "target": nid, "type": "child"})
        return nid

    root_id = add_dir(root, None)
    file_count = 0
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(root):
        dp = Path(dirpath)
        add_dir(dp, None)
        for f in filenames:
            fp = dp / f
            try:
                fsize = fp.stat().st_size
            except:
                fsize = 0
            add_file(fp, None)
            total_size += fsize
            file_count += 1

    dir_count = len(set(str(Path(p).parent) for p in node_ids)) - 1
    return {
        "version": "1.0", "generated": datetime.now().isoformat(),
        "root": str(root),
        "stats": {"files": file_count, "directories": max(0, dir_count),
                   "total_size": total_size, "total_size_human": f"{total_size / (1024*1024):.1f} MB"},
        "nodes": nodes, "edges": edges
    }

def write_html(graph, output_path):
    tree_json = json.dumps(graph["nodes"], ensure_ascii=False)
    edges_json = json.dumps(graph["edges"], ensure_ascii=False)
    root_name = os.path.basename(graph["root"])
    total_files = graph["stats"]["files"]
    total_dirs = graph["stats"]["directories"]
    total_size = graph["stats"]["total_size_human"]
    generated = graph["generated"]
    root_path = graph["root"]

    html = f"""<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Graph - {root_name}</title>
<style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
body {{ font-family:'Segoe UI',system-ui,sans-serif; background:#1a1a2e; color:#e0e0e0; height:100vh; display:flex; flex-direction:column; }}
#header {{ padding:12px 20px; background:#16213e; border-bottom:1px solid #0f3460; display:flex; justify-content:space-between; align-items:center; }}
#header h1 {{ font-size:16px; color:#e94560; }}
#header .stats {{ font-size:12px; color:#888; }}
#search {{ padding:8px 20px; background:#16213e; border-bottom:1px solid #0f3460; }}
#search input {{ width:100%; padding:6px 12px; background:#0f3460; border:1px solid #533483; color:#e0e0e0; border-radius:4px; font-size:13px; }}
#container {{ display:flex; flex:1; overflow:hidden; }}
#tree {{ flex:0 0 400px; overflow-y:auto; padding:10px; border-right:1px solid #0f3460; }}
#viz {{ flex:1; position:relative; overflow:hidden; }}
.tree-node {{ cursor:pointer; user-select:none; }}
.tree-node:hover .label {{ color:#e94560; }}
.label {{ font-size:13px; padding:2px 4px; }}
.dir .label:before {{ content:"[DIR] "; color:#533483; }}
.file .label:before {{ content:"[FILE] "; color:#4a9; }}
#stats-bar {{ padding:4px 20px; background:#0f3460; font-size:11px; color:#888; }}
.indent {{ display:inline-block; width:24px; }}
.hidden {{ display:none !important; }}
.dir.open .label:before {{ content:"[OPEN] "; color:#e94560; }}
</style>
</head>
<body>
<div id="header">
<h1>[GRAPH] {root_name}</h1>
<span class="stats">{total_files} archivos, {total_dirs} dirs, {total_size}</span>
</div>
<div id="search"><input type="text" id="filter" placeholder="Filtrar archivos..."></div>
<div id="container"><div id="tree"></div><div id="viz"></div></div>
<div id="stats-bar">Generado: {generated} | Raiz: {root_path}</div>
<script>
const nodes = {tree_json};
const edges = {edges_json};
const nodeMap = {{}};
nodes.forEach(n => {{ nodeMap[n.id] = {{...n, children: []}}; }});
const edgeMap = {{}};
edges.forEach(e => {{
    if (!edgeMap[e.source]) edgeMap[e.source] = [];
    edgeMap[e.source].push(e.target);
}});
let rootId = nodes.find(n => !edges.some(e => e.target === n.id))?.id || 0;

const treeEl = document.getElementById('tree');
function formatSize(bytes) {{
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1048576) return (bytes/1024).toFixed(1) + ' KB';
    return (bytes/1048576).toFixed(1) + ' MB';
}}
function renderNode(nodeId, depth) {{
    const node = nodeMap[nodeId];
    if (!node) return null;
    const div = document.createElement('div');
    const isDir = node.type === 'directory';
    div.className = 'tree-node ' + (isDir ? 'dir' : 'file');
    div.dataset.name = node.label.toLowerCase();
    div.dataset.path = node.path || '';
    const indent = document.createElement('span');
    indent.className = 'indent';
    indent.style.width = (depth * 24) + 'px';
    div.appendChild(indent);
    const label = document.createElement('span');
    label.className = 'label';
    label.textContent = node.label;
    if (node.extension && !isDir) label.textContent += ' .' + node.extension;
    if (node.size && !isDir) label.textContent += ' (' + formatSize(node.size) + ')';
    div.appendChild(label);
    const kids = edgeMap[nodeId];
    if (isDir && kids && kids.length > 0) {{
        const kidsDiv = document.createElement('div');
        kidsDiv.className = 'children hidden';
        kids.forEach(kidId => kidsDiv.appendChild(renderNode(kidId, depth + 1)));
        div.onclick = function(e) {{
            e.stopPropagation();
            div.classList.toggle('open');
            kidsDiv.classList.toggle('hidden');
        }};
        div.classList.add('open');
        treeEl.appendChild(div);
        treeEl.appendChild(kidsDiv);
    }} else {{
        treeEl.appendChild(div);
    }}
    return div;
}}
if (nodeMap[rootId]) renderNode(rootId, 0);

document.getElementById('filter').addEventListener('input', function(e) {{
    const q = e.target.value.toLowerCase();
    document.querySelectorAll('.file').forEach(f => {{
        f.classList.toggle('hidden', q && !f.dataset.name.includes(q));
    }});
    if (q) document.querySelectorAll('.dir').forEach(d => d.classList.add('open'));
    else document.querySelectorAll('.dir').forEach(d => d.classList.remove('hidden'));
}});
</script>
</body>
</html>"""

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html)

def main():
    if len(sys.argv) < 2:
        print("Uso: generate_graph.py <directorio>")
        sys.exit(1)
    root = sys.argv[1]
    if not os.path.isdir(root):
        print(f"Error: {root} no es un directorio valido")
        sys.exit(1)
    print(f"Escaneando: {root}")
    graph = build_tree(root)
    json_path = os.path.join(root, "graph.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(graph, f, indent=2, ensure_ascii=False)
    print(f"OK graph.json -> {json_path}")
    html_path = os.path.join(root, "graph.html")
    write_html(graph, html_path)
    print(f"OK graph.html -> {html_path}")
    print(f"\nEstadisticas:")
    print(f"   Archivos: {graph['stats']['files']}")
    print(f"   Directorios: {graph['stats']['directories']}")
    print(f"   Tamano total: {graph['stats']['total_size_human']}")

if __name__ == "__main__":
    main()
