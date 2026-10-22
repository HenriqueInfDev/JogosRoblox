import math, os
from xml.sax.saxutils import escape

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "src")
MAT = dict(Plastic=256, SmoothPlastic=272, Neon=288, Wood=512, WoodPlanks=528, Marble=784,
           Concrete=816, Brick=848, DiamondPlate=1056, Metal=1088, Grass=1280, Fabric=1312, Glass=1568)

ref_counter = [0]
def ref():
    ref_counter[0] += 1
    return "RBX%d" % ref_counter[0]

def color_u32(c):
    r, g, b = c
    return (0xFF << 24) | (r << 16) | (g << 8) | b

class Node:
    def __init__(self, cls, name, props=None):
        self.cls, self.name, self.props, self.children = cls, name, props or [], []
    def add(self, *nodes):
        self.children.extend(nodes)
        return self
    def xml(self, ind=1):
        p = "  " * ind
        out = ['%s<Item class="%s" referent="%s">' % (p, self.cls, ref()),
               '%s  <Properties>' % p,
               '%s    <string name="Name">%s</string>' % (p, escape(self.name))]
        out += ['%s    %s' % (p, x) for x in self.props]
        out.append('%s  </Properties>' % p)
        for c in self.children:
            out.append(c.xml(ind + 1))
        out.append('%s</Item>' % p)
        return "\n".join(out)

def folder(name): return Node("Folder", name)
def model(name): return Node("Model", name)

def script(cls, name, path):
    src = open(os.path.join(SRC, path), encoding="utf-8").read()
    assert "]]>" not in src
    props = ['<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>' % src]
    if cls != "ModuleScript":
        props.append('<bool name="Disabled">false</bool>')
    return Node(cls, name, props)

class Plot:
    """Transforma coordenadas locais do estúdio em coordenadas do mundo (rotação em Y)."""
    def __init__(self, ox, oz, yaw_deg):
        self.ox, self.oz = ox, oz
        a = math.radians(yaw_deg)
        self.c, self.s = round(math.cos(a), 6), round(math.sin(a), 6)
    def world(self, x, y, z):
        return (self.ox + self.c * x + self.s * z, y, self.oz - self.s * x + self.c * z)
    def rot(self):
        c, s = self.c, self.s
        return [c, 0, s, 0, 1, 0, -s, 0, c]

WORLD = Plot(0, 0, 0)

def part(plot, name, pos, size, color, mat="SmoothPlastic", transp=0, collide=True, shape=1, cls="Part", extra=None):
    x, y, z = plot.world(*pos)
    R = plot.rot()
    cf = "<X>%g</X><Y>%g</Y><Z>%g</Z>" % (x, y, z) + "".join(
        "<R%d%d>%g</R%d%d>" % (i // 3, i % 3, R[i], i // 3, i % 3) for i in range(9))
    props = [
        '<bool name="Anchored">true</bool>',
        '<bool name="CanCollide">%s</bool>' % ("true" if collide else "false"),
        '<CoordinateFrame name="CFrame">%s</CoordinateFrame>' % cf,
        '<Color3uint8 name="Color3uint8">%d</Color3uint8>' % color_u32(color),
        '<token name="Material">%d</token>' % MAT[mat],
        '<Vector3 name="size"><X>%g</X><Y>%g</Y><Z>%g</Z></Vector3>' % size,
        '<float name="Transparency">%g</float>' % transp,
        '<token name="shape">%d</token>' % shape,
        '<token name="TopSurface">0</token>',
        '<token name="BottomSurface">0</token>',
    ]
    if extra:
        props += extra
    return Node(cls, name, props)

# ---------------- cores ----------------
WHITE = (236, 240, 241); DARK = (30, 32, 42); FLOOR = (52, 58, 82); WOOD = (150, 105, 65)
YELLOW = (255, 170, 0); BLUE = (52, 152, 219); GOLD = (255, 200, 40); GREEN = (46, 204, 113)
METAL = (120, 125, 135)

DEVS = [  # id, linha (z da esteira), x, cor
    ("mesa1", 20, 22, (149, 165, 166)), ("dev2", 20, 12, (46, 204, 113)), ("dev3", 20, 2, (52, 152, 219)),
    ("dev4", 20, -8, (155, 89, 182)), ("dev5", 20, -18, (241, 196, 15)),
    ("dev6", 0, 22, (230, 126, 34)), ("dev7", 0, 12, (231, 76, 60)), ("dev8", 0, 2, (26, 188, 156)),
    ("dev9", 0, -8, (236, 64, 122)), ("dev10", 0, -18, (255, 215, 0)),
]
BUTTON_ORDER = ["dev2", "paredes", "dev3", "cafe", "dev4", "placa", "dev5", "marketing", "expansao",
                "dev6", "sofa", "dev7", "servidores", "dev8", "dev9", "publicadora", "dev10", "trofeu"]

def conveyor_line(P, cz, m):
    m.add(part(P, "Esteira", (0, 1.5, cz), (60, 1, 6), DARK, "DiamondPlate"),
          part(P, "Trilho", (0, 2.75, cz - 3.3), (60, 1.5, 0.6), YELLOW),
          part(P, "Trilho", (0, 2.75, cz + 3.3), (60, 1.5, 0.6), YELLOW),
          part(P, "Batente", (30.3, 2.75, cz), (0.6, 1.5, 7.2), YELLOW),
          part(P, "Publicadora", (-33, 4.5, cz), (6, 7, 8), BLUE, "Glass", transp=0.25),
          part(P, "TelhadoPublicadora", (-33, 8.3, cz), (7, 0.6, 9), DARK),
          part(P, "FaixaPublicadora", (-30.05, 6, cz), (0.1, 1, 8), (0, 200, 255), "Neon", collide=False))

def dev_desk(P, did, cz, x, col):
    m = model(did)
    dz = cz + 7
    m.add(part(P, "Mesa", (x, 2.4, dz), (6, 2.8, 3), WOOD, "Wood"),
          part(P, "Monitor", (x, 4.6, dz - 0.2), (2.6, 1.7, 0.3), DARK),
          part(P, "Tela", (x, 4.6, dz - 0.02), (2.3, 1.4, 0.05), col, "Neon", collide=False),
          part(P, "Teclado", (x, 3.88, dz + 0.7), (2, 0.15, 0.7), METAL),
          part(P, "Cadeira", (x, 2.0, dz + 3), (2.2, 2, 2.2), DARK, "Fabric"),
          part(P, "Encosto", (x, 4.0, dz + 4), (2.2, 2.5, 0.4), DARK, "Fabric"),
          part(P, "Poste", (x + 2.6, 5.5, cz + 5), (0.6, 9, 0.6), METAL, "Metal"),
          part(P, "Braco", (x + 1.3, 9.9, cz + 5), (3.2, 0.6, 0.6), METAL, "Metal"),
          part(P, "Braco2", (x, 9.9, cz + 2.5), (0.6, 0.6, 5.6), METAL, "Metal"),
          part(P, "Dropper", (x, 8.4, cz), (3, 2.4, 3), col),
          part(P, "Anel", (x, 7.15, cz), (3.3, 0.3, 3.3), col, "Neon", collide=False))
    return m

def build_plot(idx, P):
    t = model("Estudio%d" % idx)
    base = folder("Base")
    base.add(part(P, "Piso", (0, 0.5, 0), (100, 1, 100), FLOOR),
             part(P, "Tapete", (0, 1.03, -30), (10, 0.05, 36), (120, 40, 60), "Fabric", collide=False),
             part(P, "Porta", (0, 5, -48), (12, 8, 1), (0, 200, 255), "Neon", transp=0.5, collide=False),
             part(P, "BaseColetar", (-22, 1.1, -40), (7.5, 0.2, 7.5), DARK),
             part(P, "Coletar", (-22, 1.3, -40), (6, 0.4, 6), GREEN, "Neon"))
    conveyor_line(P, 20, base)
    items = folder("Items")
    for did, cz, x, col in DEVS:
        items.add(dev_desk(P, did, cz, x, col))
    # paredes
    m = model("paredes")
    for name, pos, size in [("ParedeEsq", (-49.5, 8, 0), (1, 14, 100)), ("ParedeDir", (49.5, 8, 0), (1, 14, 100)),
                            ("ParedeFundo", (0, 8, 49.5), (100, 14, 1)), ("FrenteEsq", (-28.5, 8, -49.5), (43, 14, 1)),
                            ("FrenteDir", (28.5, 8, -49.5), (43, 14, 1)), ("SobrePorta", (0, 12, -49.5), (14, 6, 1))]:
        m.add(part(P, name, pos, size, WHITE))
    for zz in (-30, -10, 10, 30):
        m.add(part(P, "Janela", (-49.95, 8, zz), (0.2, 5, 12), (130, 200, 255), "Glass", transp=0.3, collide=False),
              part(P, "Janela", (49.95, 8, zz), (0.2, 5, 12), (130, 200, 255), "Glass", transp=0.3, collide=False))
    m.add(part(P, "FaixaNeon", (0, 14.8, 49), (98, 0.4, 0.2), (155, 89, 182), "Neon", collide=False))
    items.add(m)
    # cafe
    m = model("cafe")
    m.add(part(P, "Balcao", (43, 2.5, 10), (9, 3, 3), WHITE, "Marble"),
          part(P, "Maquina", (41, 5.25, 10), (2.2, 2.5, 1.8), DARK, "Metal"),
          part(P, "LuzCafe", (41, 5.6, 9.05), (1.4, 0.4, 0.1), (231, 76, 60), "Neon", collide=False),
          part(P, "Xicara", (44, 4.3, 10), (0.6, 0.6, 0.6), WHITE, shape=2),
          part(P, "Xicara", (45.2, 4.3, 10), (0.6, 0.6, 0.6), WHITE, shape=2),
          part(P, "Banquinho", (41, 1.9, 6.5), (1.6, 1.8, 1.6), WOOD, "Wood"),
          part(P, "Banquinho", (45, 1.9, 6.5), (1.6, 1.8, 1.6), WOOD, "Wood"))
    items.add(m)
    # letreiro
    m = model("placa")
    m.add(part(P, "Borda", (0, 18, -49.6), (27, 6, 0.6), (155, 89, 182), "Neon"),
          part(P, "Letreiro", (0, 18, -50.1), (26, 5, 0.4), DARK),
          part(P, "Suporte", (-10, 16, -49.6), (0.6, 3, 0.6), METAL, "Metal"),
          part(P, "Suporte", (10, 16, -49.6), (0.6, 3, 0.6), METAL, "Metal"))
    items.add(m)
    # marketing
    m = model("marketing")
    m.add(part(P, "PosteOutdoor", (-12, 13, 53), (1, 26, 1), METAL, "Metal"),
          part(P, "PosteOutdoor", (12, 13, 53), (1, 26, 1), METAL, "Metal"),
          part(P, "MolduraOutdoor", (0, 26, 52.6), (32, 14, 0.6), (241, 196, 15), "Neon"),
          part(P, "Outdoor", (0, 26, 52), (30, 12, 0.6), (192, 57, 43)))
    items.add(m)
    # expansao
    m = model("expansao")
    conveyor_line(P, 0, m)
    items.add(m)
    # sala de descanso
    m = model("sofa")
    m.add(part(P, "TapeteSala", (-38, 1.03, -22), (16, 0.05, 14), (142, 68, 173), "Fabric", collide=False),
          part(P, "AssentoSofa", (-38, 1.8, -27), (10, 1.6, 3), (52, 73, 94), "Fabric"),
          part(P, "EncostoSofa", (-38, 3.3, -28.4), (10, 2.6, 0.8), (52, 73, 94), "Fabric"),
          part(P, "BracoSofa", (-43.4, 2.6, -27.2), (0.8, 1.6, 3.4), (52, 73, 94), "Fabric"),
          part(P, "BracoSofa", (-32.6, 2.6, -27.2), (0.8, 1.6, 3.4), (52, 73, 94), "Fabric"),
          part(P, "Mesinha", (-38, 1.6, -22.5), (4, 1.2, 2), WOOD, "Wood"),
          part(P, "Console", (-38, 2.4, -22.5), (1.4, 0.4, 1), WHITE),
          part(P, "RackTV", (-38, 1.8, -16), (9, 1.6, 2), DARK),
          part(P, "TV", (-38, 5.4, -16.3), (9, 5, 0.4), DARK),
          part(P, "TelaTV", (-38, 5.4, -16.53), (8.4, 4.5, 0.05), (52, 152, 219), "Neon", collide=False))
    items.add(m)
    # servidores
    m = model("servidores")
    for zz in (32, 37, 42):
        m.add(part(P, "Rack", (-44, 5, zz), (3, 8, 3.4), DARK, "Metal"),
              part(P, "LuzRack", (-42.45, 5, zz), (0.1, 6.5, 2.6), (46, 204, 113), "Neon", collide=False))
    items.add(m)
    # publicadora global
    m = model("publicadora")
    m.add(part(P, "Globo", (-33, 11.5, 20), (4.5, 4.5, 4.5), GOLD, "Neon", shape=0),
          part(P, "BaseGlobo", (-33, 9, 20), (2, 0.8, 2), DARK, "Metal"),
          part(P, "Globo", (-33, 11.5, 0), (4.5, 4.5, 4.5), GOLD, "Neon", shape=0),
          part(P, "BaseGlobo", (-33, 9, 0), (2, 0.8, 2), DARK, "Metal"))
    items.add(m)
    # trofeu
    m = model("trofeu")
    m.add(part(P, "Pedestal", (40, 2.5, 40), (5, 3, 5), DARK, "Marble"),
          part(P, "Haste", (40, 5, 40), (0.8, 2, 0.8), GOLD, "Metal"),
          part(P, "Copa", (40, 7.5, 40), (3.5, 3.5, 3.5), GOLD, "Neon", shape=0),
          part(P, "BaseCopa", (40, 4.2, 40), (2.4, 0.4, 2.4), GOLD, "Metal"))
    items.add(m)

    buttons = folder("Buttons")
    cols = [10, 18, 26, 34, 42]
    rows = [-42, -34, -26, -18]
    for i, bid in enumerate(BUTTON_ORDER):
        x, z = cols[i % 5], rows[i // 5]
        buttons.add(part(P, bid, (x, 1.25, z), (5, 0.5, 5), GREEN, "Neon"))
    t.add(base, items, buttons)
    return t

def build():
    ws = Node("Workspace", "Workspace")
    ws.add(part(WORLD, "Baseplate", (0, -0.5, 0), (320, 1, 320), (88, 160, 80), "Grass"),
           part(WORLD, "Rua", (0, 0.02, 0), (20, 0.05, 320), (70, 70, 75), "Concrete"),
           part(WORLD, "Rua", (0, 0.03, 0), (320, 0.05, 20), (70, 70, 75), "Concrete"),
           part(WORLD, "SpawnLocation", (0, 0.6, 0), (12, 1, 12), (155, 89, 182), "Neon", cls="SpawnLocation",
                extra=['<bool name="Neutral">true</bool>', '<int name="Duration">0</int>']))
    tycoons = folder("Tycoons")
    layout = [(-60, 60, 0), (60, 60, 0), (-60, -60, 180), (60, -60, 180)]
    for i, (x, z, yaw) in enumerate(layout, 1):
        tycoons.add(build_plot(i, Plot(x, z, yaw)))
    ws.add(tycoons)

    rs = Node("ReplicatedStorage", "ReplicatedStorage").add(script("ModuleScript", "TycoonConfig", "TycoonConfig.lua"))
    sss = Node("ServerScriptService", "ServerScriptService").add(script("Script", "TycoonServer", "TycoonServer.server.lua"))
    sp = Node("StarterPlayer", "StarterPlayer").add(
        Node("StarterPlayerScripts", "StarterPlayerScripts").add(script("LocalScript", "TycoonClient", "TycoonClient.client.lua")))
    lighting = Node("Lighting", "Lighting")

    body = "\n".join(n.xml() for n in [ws, lighting, rs, sss, sp])
    return ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
            'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
            'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">\n'
            '  <External>null</External>\n  <External>nil</External>\n' + body + '\n</roblox>\n')

if __name__ == "__main__":
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "EstudioDeGamesTycoon.rbxlx")
    with open(out, "w", encoding="utf-8") as f:
        f.write(build())
    print(out, os.path.getsize(out), "bytes,", ref_counter[0], "instances")
