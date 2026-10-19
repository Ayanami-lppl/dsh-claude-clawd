
import base64
from pathlib import Path

root = Path(__file__).resolve().parent.parent
assets = root / "v2-assets" / "frames"
template = (root / "v2-plugin" / "client.template.js").read_text(encoding="utf-8")
mapping = {
    "__IDLE__": "idle.png",
    "__REST__": "typing-rest.png",
    "__LEFT__": "typing-left.png",
    "__RIGHT__": "typing-right.png",
}
for key, filename in mapping.items():
    data = (assets / filename).read_bytes()
    url = "data:image/png;base64," + base64.b64encode(data).decode("ascii")
    template = template.replace(key, url)
out = root / "v2-plugin" / "lib" / "client.js"
out.write_text(template, encoding="utf-8")
print("wrote", out, out.stat().st_size)
