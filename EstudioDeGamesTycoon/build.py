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

class Lift:
    """Mesmo estúdio, deslocado para cima (para montar os andares)."""
    def __init__(self, plot, dy):
        self.plot, self.dy = plot, dy
    def world(self, x, y, z):
        return self.plot.world(x, y + self.dy, z)
    def rot(self):
        return self.plot.rot()

F2 = 15   # 2º andar: piso em y = 16
F3 = 29   # cobertura: piso em y = 30

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
PANTS = (44, 62, 80)
SKINS = [(242, 196, 155), (198, 134, 66), (141, 85, 36), (255, 219, 172), (224, 172, 105)]
HAIRS = [(59, 42, 26), (20, 20, 20), (160, 82, 45), (230, 190, 90), (90, 60, 40), (200, 60, 60)]
PLANT = (39, 174, 96)
POSTER_COLORS = [(192, 57, 43), (41, 128, 185), (142, 68, 173), (39, 174, 96)]

DEVS = [  # id, linha (z da esteira), x, cor
    ("mesa1", 20, 22, (149, 165, 166)), ("dev2", 20, 12, (46, 204, 113)), ("dev3", 20, 2, (52, 152, 219)),
    ("dev4", 20, -8, (155, 89, 182)), ("dev5", 20, -18, (241, 196, 15)),
    ("dev6", 0, 22, (230, 126, 34)), ("dev7", 0, 12, (231, 76, 60)), ("dev8", 0, 2, (26, 188, 156)),
    ("dev9", 0, -8, (236, 64, 122)), ("dev10", 0, -18, (255, 215, 0)),
    # 2º andar
    ("dev11", 20, 22, (0, 180, 255)), ("dev12", 20, 12, (124, 58, 237)), ("dev13", 20, 2, (255, 99, 72)),
    ("dev14", 20, -8, (46, 213, 115)), ("dev15", 20, -18, (240, 240, 255)),
    # cobertura
    ("dev16", 20, 22, (255, 165, 2)), ("dev17", 20, 12, (0, 210, 211)), ("dev18", 20, 2, (255, 71, 87)),
]
DEV_FLOOR = {d[0]: (F2 if d[0] in ("dev11", "dev12", "dev13", "dev14", "dev15") else F3 if d[0] in ("dev16", "dev17", "dev18") else 0) for d in DEVS}
BUTTONS_F1 = ["dev2", "paredes", "dev3", "cafe", "dev4", "placa", "dev5", "marketing", "expansao",
              "dev6", "sofa", "dev7", "servidores", "dev8", "dev9", "publicadora", "dev10", "andar2"]
BUTTONS_F2 = ["linha3", "dev11", "testes", "dev12", "streaming", "dev13", "arcade", "dev14", "esports", "dev15", "andar3"]
BUTTONS_F3 = ["dev16", "sala_ceo", "dev17", "terraco", "dev18", "heliponto", "trofeu"]

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
          part(P, "TampaDropper", (x, 9.75, cz), (3.4, 0.3, 3.4), DARK, "Metal"),
          part(P, "Anel", (x, 7.15, cz), (3.3, 0.3, 3.3), col, "Neon", collide=False),
          part(P, "Caneca", (x - 2.2, 4.15, dz + 0.4), (0.7, 0.7, 0.7), (231, 76, 60), shape=2, collide=False),
          part(P, "Mouse", (x + 1.6, 3.85, dz + 0.8), (0.4, 0.15, 0.6), METAL, collide=False))
    # funcionário sentado (de frente para o monitor)
    i = [d[0] for d in DEVS].index(did)
    skin = SKINS[i % len(SKINS)]
    hair = HAIRS[i % len(HAIRS)]
    sz = dz + 3
    m.add(part(P, "NPC_Tronco", (x, 4.7, sz + 0.3), (2, 2, 1), col, collide=False),
          part(P, "NPC_Cabeca", (x, 6.35, sz + 0.3), (1.25, 1.25, 1.25), skin, collide=False),
          part(P, "NPC_Cabelo", (x, 7.05, sz + 0.4), (1.35, 0.4, 1.35), hair, collide=False),
          part(P, "NPC_Olho", (x - 0.25, 6.45, sz - 0.33), (0.16, 0.26, 0.05), (20, 20, 20), collide=False),
          part(P, "NPC_Olho", (x + 0.25, 6.45, sz - 0.33), (0.16, 0.26, 0.05), (20, 20, 20), collide=False),
          part(P, "NPC_PernaE", (x - 0.5, 3.45, sz - 0.6), (0.95, 0.95, 2), PANTS, collide=False),
          part(P, "NPC_PernaD", (x + 0.5, 3.45, sz - 0.6), (0.95, 0.95, 2), PANTS, collide=False),
          part(P, "NPC_CanelaE", (x - 0.5, 2.5, sz - 1.4), (0.95, 1.6, 0.95), PANTS, collide=False),
          part(P, "NPC_CanelaD", (x + 0.5, 2.5, sz - 1.4), (0.95, 1.6, 0.95), PANTS, collide=False),
          part(P, "NPC_BracoE", (x - 1.45, 4.95, sz - 0.6), (0.9, 0.9, 2.1), col, collide=False),
          part(P, "NPC_BracoD", (x + 1.45, 4.95, sz - 0.6), (0.9, 0.9, 2.1), col, collide=False))
    return m

GLASS = (150, 210, 255)

def npc(L, x, y, z, shirt, skin, hair, facing=-1, seated=False):
    """Boneco em blocos. facing=-1 olha para -Z, +1 para +Z. y = altura do chão."""
    f = facing
    parts = []
    if seated:
        parts += [part(L, "NPC_PernaE", (x - 0.5, y + 2.45, z + 0.6 * f), (0.95, 0.95, 2), PANTS, collide=False),
                  part(L, "NPC_PernaD", (x + 0.5, y + 2.45, z + 0.6 * f), (0.95, 0.95, 2), PANTS, collide=False),
                  part(L, "NPC_CanelaE", (x - 0.5, y + 1.5, z + 1.4 * f), (0.95, 1.6, 0.95), PANTS, collide=False),
                  part(L, "NPC_CanelaD", (x + 0.5, y + 1.5, z + 1.4 * f), (0.95, 1.6, 0.95), PANTS, collide=False)]
        ty = y + 3.7
    else:
        parts += [part(L, "NPC_PernaE", (x - 0.5, y + 1, z), (0.95, 2, 0.95), PANTS, collide=False),
                  part(L, "NPC_PernaD", (x + 0.5, y + 1, z), (0.95, 2, 0.95), PANTS, collide=False)]
        ty = y + 3
    parts += [part(L, "NPC_Tronco", (x, ty, z - 0.3 * f), (2, 2, 1), shirt, collide=False),
              part(L, "NPC_Cabeca", (x, ty + 1.65, z - 0.3 * f), (1.25, 1.25, 1.25), skin, collide=False),
              part(L, "NPC_Cabelo", (x, ty + 2.35, z - 0.4 * f), (1.35, 0.4, 1.35), hair, collide=False),
              part(L, "NPC_Olho", (x - 0.25, ty + 1.75, z - 0.3 * f + 0.63 * f), (0.16, 0.26, 0.05), (20, 20, 20), collide=False),
              part(L, "NPC_Olho", (x + 0.25, ty + 1.75, z - 0.3 * f + 0.63 * f), (0.16, 0.26, 0.05), (20, 20, 20), collide=False)]
    if seated:
        parts += [part(L, "NPC_BracoE", (x - 1.45, ty + 0.25, z + 0.6 * f), (0.9, 0.9, 2.1), shirt, collide=False),
                  part(L, "NPC_BracoD", (x + 1.45, ty + 0.25, z + 0.6 * f), (0.9, 0.9, 2.1), shirt, collide=False)]
    else:
        parts += [part(L, "NPC_BracoParadoE", (x - 1.45, ty, z - 0.3 * f), (0.9, 2, 0.9), shirt, collide=False),
                  part(L, "NPC_BracoParadoD", (x + 1.45, ty, z - 0.3 * f), (0.9, 2, 0.9), shirt, collide=False)]
    return parts

def walls(L, m, h, with_door, suffix):
    yc = 1 + h / 2
    m.add(part(L, "ParedeEsq" + suffix, (-49.5, yc, 0), (1, h, 100), WHITE),
          part(L, "ParedeDir" + suffix, (49.5, yc, 0), (1, h, 100), WHITE),
          part(L, "ParedeFundo" + suffix, (0, yc, 49.5), (100, h, 1), WHITE))
    if with_door:
        m.add(part(L, "FrenteEsq" + suffix, (-28.5, yc, -49.5), (43, h, 1), WHITE),
              part(L, "FrenteDir" + suffix, (28.5, yc, -49.5), (43, h, 1), WHITE))
    else:
        m.add(part(L, "Frente" + suffix, (0, yc, -49.5), (100, h, 1), WHITE))
    for zz in (-30, -10, 10, 30):
        m.add(part(L, "Janela", (-49.95, yc, zz), (0.2, 5, 12), (130, 200, 255), "Glass", transp=0.3, collide=False),
              part(L, "Janela", (49.95, yc, zz), (0.2, 5, 12), (130, 200, 255), "Glass", transp=0.3, collide=False))
    for xx in (-30, -10, 10, 30):
        if not with_door:
            m.add(part(L, "Janela", (xx, yc, -49.95), (12, 5, 0.2), (130, 200, 255), "Glass", transp=0.3, collide=False))
    m.add(part(L, "FaixaNeon", (0, h + 0.8, 49), (98, 0.4, 0.2), (155, 89, 182), "Neon", collide=False))

def slab_with_hole(L, m, hole_x0, hole_x1, hole_z0, hole_z1, y):
    """Laje 100x100 com um vão retangular (para a escada) encostado numa parede lateral."""
    if hole_x1 >= 50:   # vão no lado direito
        a = (-50, hole_x0)
    else:               # vão no lado esquerdo
        a = (hole_x1, 50)
    m.add(part(L, "Piso", ((a[0] + a[1]) / 2, y, 0), (a[1] - a[0], 1, 100), FLOOR))
    m.add(part(L, "Piso", ((hole_x0 + hole_x1) / 2, y, (-50 + hole_z0) / 2), (hole_x1 - hole_x0, 1, hole_z0 + 50), FLOOR))
    m.add(part(L, "Piso", ((hole_x0 + hole_x1) / 2, y, (hole_z1 + 50) / 2), (hole_x1 - hole_x0, 1, 50 - hole_z1), FLOOR))

def ceiling_lights(L, m, y, skip):
    for lx in (-30, -10, 10, 30):
        for lz in (-30, -10, 10, 30):
            if skip(lx, lz):
                continue
            m.add(part(L, "LuzTeto", (lx, y, lz), (5, 0.2, 5), (255, 246, 225), "Neon", collide=False))

def stairs(L, m, x, z_start, steps, rise_from):
    for i in range(1, steps + 1):
        m.add(part(L, "Degrau", (x, rise_from + i / 2, z_start - 1 + 2 * i), (5, i, 2), (200, 200, 210), "Concrete"))
        m.add(part(L, "FaixaDegrau", (x, rise_from + i + 0.02, z_start - 1 + 2 * i - 0.8), (5, 0.05, 0.3), (255, 170, 0), "Neon", collide=False))

def build_floor2(P, items):
    L1 = P
    L2 = Lift(P, F2)
    # --- o andar em si
    m = model("andar2")
    slab_with_hole(L1, m, 43, 50, 13, 45, 15.5)
    ceiling_lights(L1, m, 14.85, lambda lx, lz: False)
    stairs(L1, m, 46.5, 15, 15, 1)
    walls(L2, m, 13, False, "2")
    m.add(part(L2, "Corrimao", (43.2, 2.5, 29), (0.4, 3, 32), GLASS, "Glass", transp=0.3),
          part(L2, "Corrimao", (46.4, 2.5, 13.2), (6.6, 3, 0.4), GLASS, "Glass", transp=0.3),
          part(L2, "FaixaCorredor", (0, 1.02, 14), (86, 0.05, 2), (155, 89, 182), "Neon", collide=False),
          part(L2, "PlacaAndar", (46.5, 8, 46), (6, 2, 0.3), DARK, collide=False))
    for (px, pz) in [(-46, 46), (36, 46), (-46, 8), (40, -46)]:
        m.add(part(L2, "Vaso", (px, 2, pz), (2.2, 2, 2.2), (205, 97, 51), "Concrete"),
              part(L2, "Planta", (px, 4.2, pz), (3.2, 3.2, 3.2), PLANT, "Grass", shape=0),
              part(L2, "Planta", (px + 0.4, 5.6, pz - 0.2), (2.2, 2.2, 2.2), (46, 204, 113), "Grass", shape=0))
    items.add(m)
    # --- 3ª linha de produção
    m = model("linha3")
    conveyor_line(L2, 20, m)
    items.add(m)
    # --- sala de testes (QA): 3 mesas com TV e testadores jogando
    m = model("testes")
    m.add(part(L2, "TapeteQA", (-26, 1.03, 3), (30, 0.05, 12), (52, 73, 94), "Fabric", collide=False))
    for k, tx in enumerate((-36, -26, -16)):
        m.add(part(L2, "MesaQA", (tx, 2.2, 0), (7, 2.4, 3), WHITE),
              part(L2, "TVQA", (tx, 4.9, -0.8), (5.5, 3.2, 0.3), DARK),
              part(L2, "TelaQA", (tx, 4.9, -0.62), (5.1, 2.8, 0.05), [(231, 76, 60), (46, 204, 113), (52, 152, 219)][k], "Neon", collide=False),
              part(L2, "Console", (tx + 2.2, 3.6, 0.6), (1.6, 0.5, 1.2), (20, 20, 20)),
              part(L2, "CadeiraQA", (tx, 2, 3.4), (2.4, 2, 2.4), (192, 57, 43), "Fabric"),
              part(L2, "EncostoQA", (tx, 4, 4.4), (2.4, 2.6, 0.4), (192, 57, 43), "Fabric"))
        m.add(*npc(L2, tx, 1, 3.4, [(39, 174, 96), (243, 156, 18), (41, 128, 185)][k], SKINS[k + 1], HAIRS[k + 2], seated=True))
        m.add(part(L2, "Controle", (tx, 4.4, 1.9), (1.4, 0.4, 0.7), (20, 20, 20), collide=False))
    m.add(part(L2, "PlacaQA", (-26, 9, -6.2), (14, 2.4, 0.3), (41, 128, 185), "Neon", collide=False))
    items.add(m)
    # --- estúdio de streaming
    m = model("streaming")
    m.add(part(L2, "TelaVerde", (30, 7, -9.6), (18, 12, 0.4), (0, 200, 80)),
          part(L2, "MesaStream", (30, 2.4, 0), (8, 2.8, 3), DARK),
          part(L2, "MonitorStream", (27, 4.9, -0.6), (2.6, 1.8, 0.3), DARK),
          part(L2, "TelaStream", (27, 4.9, -0.42), (2.3, 1.5, 0.05), (155, 89, 182), "Neon", collide=False),
          part(L2, "MonitorStream", (30, 4.9, -0.8), (3, 2, 0.3), DARK),
          part(L2, "TelaStream", (30, 4.9, -0.62), (2.7, 1.7, 0.05), (52, 152, 219), "Neon", collide=False),
          part(L2, "MonitorStream", (33, 4.9, -0.6), (2.6, 1.8, 0.3), DARK),
          part(L2, "TelaStream", (33, 4.9, -0.42), (2.3, 1.5, 0.05), (231, 76, 60), "Neon", collide=False),
          part(L2, "Microfone", (31.8, 4.4, 0.8), (0.4, 1.6, 0.4), (20, 20, 20)),
          part(L2, "CadeiraGamer", (30, 2.2, 3.6), (2.6, 2.4, 2.6), (231, 76, 60), "Fabric"),
          part(L2, "EncostoGamer", (30, 5, 4.7), (2.6, 4, 0.5), (231, 76, 60), "Fabric"),
          part(L2, "RingLight", (24.5, 6.5, 2), (0.3, 3, 3), (255, 255, 240), "Neon", collide=False),
          part(L2, "TripeLuz", (24.5, 3, 2), (0.3, 5, 0.3), (20, 20, 20)),
          part(L2, "Camera", (35.5, 5.8, 3), (1.2, 1, 1.8), (20, 20, 20)),
          part(L2, "TripeCamera", (35.5, 3, 3), (0.3, 5, 0.3), (20, 20, 20)),
          part(L2, "AoVivo", (30, 11, -9.3), (8, 2.4, 0.3), (192, 57, 43), "Neon", collide=False))
    m.add(*npc(L2, 30, 1.4, 3.6, (155, 89, 182), SKINS[3], HAIRS[5], seated=True))
    items.add(m)
    # --- fliperamas retrô no fundo
    m = model("arcade")
    for k, ax in enumerate((-36, -29, -22, -15, -8)):
        col = [(231, 76, 60), (52, 152, 219), (241, 196, 15), (155, 89, 182), (46, 204, 113)][k]
        m.add(part(L2, "Fliperama", (ax, 4.5, 45), (4.4, 7, 3.4), col),
              part(L2, "TelaFliper", (ax, 5.6, 43.25), (3.4, 2.6, 0.1), (20, 20, 40), "Neon", collide=False),
              part(L2, "PainelFliper", (ax, 3.6, 42.9), (4, 0.4, 1.4), (30, 30, 30)),
              part(L2, "Marquise", (ax, 7.4, 43.2), (4.4, 1, 0.2), (255, 230, 120), "Neon", collide=False))
    m.add(part(L2, "PlacaArcade", (-22, 11, 48.8), (18, 2.6, 0.3), (236, 64, 122), "Neon", collide=False))
    items.add(m)
    # --- arena de eSports
    m = model("esports")
    m.add(part(L2, "Palco", (-28, 1.5, -36), (26, 1, 14), (30, 30, 40), "Metal"),
          part(L2, "BordaPalco", (-28, 2.05, -29.05), (26, 0.1, 0.2), (0, 230, 255), "Neon", collide=False),
          part(L2, "TelaArena", (-28, 8, -48.8), (26, 8, 0.4), (20, 20, 40)),
          part(L2, "MolduraArena", (-28, 8, -48.95), (27.4, 9.4, 0.2), (0, 230, 255), "Neon", collide=False))
    for team, tz, col in (("A", -38, (231, 76, 60)), ("B", -33, (52, 152, 219))):
        for k, ex in enumerate((-36, -28, -20)):
            facing = 1 if team == "A" else -1
            m.add(part(L2, "MesaArena", (ex, 3.3, tz + 1.2 * facing), (5, 0.4, 2), DARK),
                  part(L2, "PCArena", (ex, 4.4, tz + 1.8 * facing), (2.4, 1.6, 0.3), (20, 20, 20)),
                  part(L2, "TelaPCArena", (ex, 4.4, tz + 1.8 * facing - 0.18 * facing), (2.1, 1.3, 0.05), col, "Neon", collide=False))
            m.add(part(L2, "CadeiraArena", (ex, 3, tz - 0.8 * facing), (2.2, 2, 2.2), (20, 20, 25), "Fabric"))
            m.add(*npc(L2, ex, 2, tz - 0.8 * facing, col, SKINS[(k + (0 if team == "A" else 2)) % 5], HAIRS[k], facing=facing, seated=True))
    items.add(m)

def build_floor3(P, items):
    L2 = Lift(P, F2)
    L3 = Lift(P, F3)
    m = model("andar3")
    slab_with_hole(L2, m, -50, -43, -47, -17, 14.5)
    ceiling_lights(L2, m, 13.85, lambda lx, lz: False)
    stairs(L2, m, -46.5, -45, 14, 1)
    # cobertura: metade de trás fechada em vidro, frente é terraço
    m.add(part(L3, "VidroFundo", (0, 7, 49.5), (100, 12, 1), GLASS, "Glass", transp=0.35),
          part(L3, "VidroEsq", (-49.5, 7, 25), (1, 12, 50), GLASS, "Glass", transp=0.35),
          part(L3, "VidroDir", (49.5, 7, 25), (1, 12, 50), GLASS, "Glass", transp=0.35),
          part(L3, "VidroFrenteEsq", (-27, 7, 0.5), (46, 12, 1), GLASS, "Glass", transp=0.35),
          part(L3, "VidroFrenteDir", (27, 7, 0.5), (46, 12, 1), GLASS, "Glass", transp=0.35),
          part(L3, "SobrePortaCob", (0, 11, 0.5), (8, 4, 1), WHITE),
          part(L3, "Telhado", (0, 13.5, 25), (101, 1, 51), WHITE),
          part(L3, "FaixaNeon", (0, 13, 0), (100, 0.4, 0.4), (155, 89, 182), "Neon", collide=False),
          part(L3, "Corrimao", (0, 2.75, -49.8), (100, 3.5, 0.4), GLASS, "Glass", transp=0.3),
          part(L3, "Corrimao", (-49.8, 2.75, -25), (0.4, 3.5, 50), GLASS, "Glass", transp=0.3),
          part(L3, "Corrimao", (49.8, 2.75, -25), (0.4, 3.5, 50), GLASS, "Glass", transp=0.3),
          part(L3, "Corrimao", (-43.2, 2.75, -32), (0.4, 3.5, 30), GLASS, "Glass", transp=0.3),
          part(L3, "Corrimao", (-46.4, 2.75, -47.2), (6.6, 3.5, 0.4), GLASS, "Glass", transp=0.3),
          part(L3, "DeckTerraco", (0, 1.03, -25), (98, 0.05, 48), (160, 110, 70), "WoodPlanks", collide=False))
    ceiling_lights(L3, m, 12.85, lambda lx, lz: lz < 0)
    conveyor_line(L3, 20, m)
    for (px, pz) in [(-46, -6), (46, -6), (46, -46), (-36, -46)]:
        m.add(part(L3, "Vaso", (px, 2, pz), (2.2, 2, 2.2), (205, 97, 51), "Concrete"),
              part(L3, "Planta", (px, 4.2, pz), (3.2, 3.2, 3.2), PLANT, "Grass", shape=0),
              part(L3, "Planta", (px + 0.4, 5.6, pz - 0.2), (2.2, 2.2, 2.2), (46, 204, 113), "Grass", shape=0))
    items.add(m)
    # --- sala do CEO
    m = model("sala_ceo")
    m.add(part(L3, "TapeteCEO", (39, 1.03, 37), (18, 0.05, 16), (120, 40, 60), "Fabric", collide=False),
          part(L3, "MesaCEO", (39, 2.6, 36), (10, 3.2, 4), (90, 55, 30), "Wood"),
          part(L3, "TampoCEO", (39, 4.25, 36), (10.4, 0.2, 4.4), (20, 20, 20), "Marble"),
          part(L3, "MonitorCEO", (39, 5.4, 36.8), (3.4, 2, 0.3), DARK),
          part(L3, "TelaCEO", (39, 5.4, 36.98), (3.1, 1.7, 0.05), (255, 215, 0), "Neon", collide=False),
          part(L3, "PoltronaCEO", (39, 2.4, 39.6), (3, 2.8, 3), (20, 20, 20), "Fabric"),
          part(L3, "EncostoCEO", (39, 5.2, 41), (3, 4.4, 0.6), (20, 20, 20), "Fabric"),
          part(L3, "Estante", (47.5, 6, 37), (2, 10, 12), (90, 55, 30), "Wood"),
          part(L3, "Aquario", (33, 4, 47.5), (8, 4.4, 2.4), (80, 170, 255), "Glass", transp=0.4),
          part(L3, "BaseAquario", (33, 1.6, 47.5), (8.4, 1.2, 2.8), DARK),
          part(L3, "Peixe", (31.5, 4.2, 47.5), (0.8, 0.5, 0.3), (255, 140, 0), "Neon", collide=False),
          part(L3, "Peixe", (34.5, 3.4, 47.5), (0.8, 0.5, 0.3), (255, 220, 0), "Neon", collide=False),
          part(L3, "QuadroCEO", (39, 8, 48.9), (8, 4, 0.2), (255, 215, 0), collide=False))
    for k, bz in enumerate((32.5, 34.5, 36.5, 38.5, 40.5)):
        m.add(part(L3, "Livros", (46.3, 3 + (k % 3) * 2.6, bz + 1), (0.6, 1.6, 1.6), [(192, 57, 43), (41, 128, 185), (39, 174, 96), (241, 196, 15), (142, 68, 173)][k], collide=False))
    m.add(*npc(L3, 39, 1.8, 39.6, (20, 20, 25), SKINS[0], (180, 180, 180), facing=-1, seated=True))
    items.add(m)
    # --- terraço com piscina
    m = model("terraco")
    m.add(part(L3, "BordaPiscina", (10, 1.6, -24), (24, 1.2, 14), WHITE, "Marble"),
          part(L3, "Agua", (10, 2.15, -24), (22, 0.2, 12), (0, 170, 255), "Glass", transp=0.25, collide=False),
          part(L3, "Bar", (40, 2.6, -14), (10, 3.2, 3), WHITE, "Marble"),
          part(L3, "TampoBar", (40, 4.3, -14), (10.4, 0.2, 3.4), (90, 55, 30), "Wood"),
          part(L3, "LuzBar", (40, 2.6, -15.55), (9.6, 0.4, 0.1), (0, 230, 255), "Neon", collide=False))
    for lx in (2, 9, 16):
        m.add(part(L3, "Espreguicadeira", (lx, 1.7, -37), (2.4, 0.8, 6), WHITE),
              part(L3, "EncostoEspreg", (lx, 2.6, -39.4), (2.4, 1.6, 1.2), WHITE))
    for ux, col in ((-3, (231, 76, 60)), (21, (241, 196, 15))):
        m.add(part(L3, "HasteGuardaSol", (ux, 4, -37), (0.4, 6, 0.4), WHITE),
              part(L3, "GuardaSol", (ux, 7.2, -37), (7, 0.6, 7), col, collide=False))
    for bx in (36, 40, 44):
        m.add(part(L3, "BanquetaBar", (bx, 2.2, -11.5), (1.4, 2.4, 1.4), (20, 20, 20)))
    m.add(*npc(L3, 25, 1, -26, (0, 170, 255), SKINS[2], HAIRS[1], facing=-1))
    items.add(m)
    # --- heliponto + helicóptero no telhado
    m = model("heliponto")
    R = Lift(P, F3 + 13)  # topo do telhado = y 44
    m.add(part(R, "Heliponto", (0, 1.25, 25), (26, 0.5, 26), (40, 42, 52), "Concrete"),
          part(R, "HBarra", (-4, 1.52, 25), (1.4, 0.05, 10), (255, 255, 255), "Neon", collide=False),
          part(R, "HBarra", (4, 1.52, 25), (1.4, 0.05, 10), (255, 255, 255), "Neon", collide=False),
          part(R, "HBarra", (0, 1.52, 25), (8, 0.05, 1.4), (255, 255, 255), "Neon", collide=False))
    for (bx, bz, sx, sz) in [(0, 12.2, 26, 0.4), (0, 37.8, 26, 0.4), (-12.8, 25, 0.4, 26), (12.8, 25, 0.4, 26)]:
        m.add(part(R, "BordaHeliponto", (bx, 1.55, bz), (sx, 0.1, sz), (255, 170, 0), "Neon", collide=False))
    m.add(part(R, "CorpoHeli", (0, 4.4, 25), (5, 4, 9), (192, 57, 43)),
          part(R, "CabineHeli", (0, 4.6, 20.2), (4.4, 3.2, 1.2), (150, 210, 255), "Glass", transp=0.2),
          part(R, "CaudaHeli", (0, 5.2, 33), (1.4, 1.4, 8), (192, 57, 43)),
          part(R, "LemeHeli", (0, 6.6, 36.6), (0.4, 3, 1.6), (20, 20, 20)),
          part(R, "MastroHeli", (0, 7, 25), (0.6, 1.4, 0.6), (20, 20, 20), "Metal"),
          part(R, "HeliceHeli", (0, 7.8, 25), (18, 0.2, 0.9), (20, 20, 20), "Metal", collide=False),
          part(R, "HeliceHeli", (0, 7.85, 25), (0.9, 0.2, 18), (20, 20, 20), "Metal", collide=False),
          part(R, "EsquiHeli", (-2.2, 1.9, 25), (0.4, 0.4, 9), (20, 20, 20), "Metal"),
          part(R, "EsquiHeli", (2.2, 1.9, 25), (0.4, 0.4, 9), (20, 20, 20), "Metal"),
          part(R, "LogoHeli", (2.55, 4.4, 26), (0.05, 2, 3), (255, 215, 0), "Neon", collide=False))
    items.add(m)
    # --- troféu Game of the Year (na frente do terraço, com holofote)
    m = model("trofeu")
    tx, tz = 36, -36
    m.add(part(L3, "PalcoTrofeu", (tx, 1.4, tz), (9, 0.8, 9), (20, 20, 25), "Marble"),
          part(L3, "BordaPalcoTrofeu", (tx, 1.82, tz), (9.4, 0.05, 9.4), (255, 215, 0), "Neon", collide=False),
          part(L3, "Pedestal", (tx, 3.3, tz), (4, 3, 4), DARK, "Marble"),
          part(L3, "BaseCopa", (tx, 5, tz), (2.4, 0.4, 2.4), GOLD, "Metal"),
          part(L3, "Haste", (tx, 6, tz), (0.8, 2, 0.8), GOLD, "Metal"),
          part(L3, "Copa", (tx, 8.5, tz), (3.5, 3.5, 3.5), GOLD, "Metal", shape=0),
          part(L3, "BordaCopa", (tx, 10.1, tz), (3.6, 0.5, 3.6), GOLD, "Metal"),
          part(L3, "AlcaCopa", (tx - 2.05, 8.8, tz), (0.6, 1.8, 0.6), GOLD, "Metal"),
          part(L3, "AlcaCopa", (tx + 2.05, 8.8, tz), (0.6, 1.8, 0.6), GOLD, "Metal"),
          part(L3, "Estrela", (tx, 11.3, tz), (1.2, 1.2, 1.2), (255, 255, 200), "Neon", shape=0, collide=False))
    items.add(m)

def build_plot(idx, P):
    t = model("Estudio%d" % idx)
    base = folder("Base")
    base.add(part(P, "Piso", (0, 0.5, 0), (100, 1, 100), FLOOR),
             part(P, "Tapete", (0, 1.03, -30), (10, 0.05, 36), (120, 40, 60), "Fabric", collide=False),
             part(P, "Porta", (0, 5, -48), (12, 8, 1), (0, 200, 255), "Neon", transp=0.5, collide=False),
             part(P, "BaseColetar", (-22, 1.1, -40), (7.5, 0.2, 7.5), DARK),
             part(P, "Coletar", (-22, 1.3, -40), (6, 0.4, 6), GREEN, "Neon"))
    conveyor_line(P, 20, base)
    for (px, pz) in [(-46, -46), (46, -46), (-46, 46), (-10.5, -46), (10.5, -46)]:
        base.add(part(P, "Vaso", (px, 2, pz), (2.2, 2, 2.2), (205, 97, 51), "Concrete"),
                 part(P, "Planta", (px, 4.2, pz), (3.2, 3.2, 3.2), PLANT, "Grass", shape=0),
                 part(P, "Planta", (px + 0.4, 5.6, pz - 0.2), (2.2, 2.2, 2.2), (46, 204, 113), "Grass", shape=0))
    for zz in (-6, 10, 30):
        base.add(part(P, "Luminaria", (-47, 6, zz), (0.5, 10, 0.5), METAL, "Metal"),
                 part(P, "LuzLuminaria", (-47, 11.2, zz), (1.6, 0.6, 1.6), (255, 240, 200), "Neon", collide=False))
    base.add(part(P, "FaixaCorredor", (0, 1.02, 14), (100, 0.05, 2), (155, 89, 182), "Neon", collide=False))
    base.add(part(P, "Incubadora", (-36, 2, -42), (5, 2, 5), (40, 30, 60), "Metal"),
             part(P, "AnelIncubadora", (-36, 3.05, -42), (5.4, 0.1, 5.4), (155, 89, 182), "Neon", collide=False),
             part(P, "OvoIncubadora", (-36, 5.1, -42), (3, 3.8, 3), (255, 230, 150), "Neon", shape=0, collide=False),
             part(P, "CupulaIncubadora", (-36, 5.3, -42), (4.6, 4.8, 4.6), (180, 220, 255), "Glass", transp=0.6, shape=0, collide=False))
    items = folder("Items")
    for did, cz, x, col in DEVS:
        items.add(dev_desk(Lift(P, DEV_FLOOR[did]), did, cz, x, col))
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
    for k, px in enumerate((-30, -10, 10, 30), 1):
        m.add(part(P, "MolduraPoster", (px, 8.5, 48.85), (9, 6.4, 0.3), DARK, collide=False),
              part(P, "Poster%d" % k, (px, 8.5, 48.65), (8.4, 5.8, 0.1), POSTER_COLORS[k - 1], collide=False))
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
    m.add(part(P, "Borda", (0, 12, -50.3), (27, 5.6, 0.6), (155, 89, 182), "Neon"),
          part(P, "Letreiro", (0, 12, -50.8), (26, 4.8, 0.4), DARK))
    items.add(m)
    # marketing
    m = model("marketing")
    m.add(part(P, "MolduraOutdoor", (30, 7.5, -50.3), (22, 10, 0.6), (241, 196, 15), "Neon"),
          part(P, "Outdoor", (30, 7.5, -50.8), (20.5, 8.6, 0.4), (192, 57, 43)),
          part(P, "Holofote", (22, 1.6, -53), (1.2, 1.2, 1.2), DARK, "Metal"),
          part(P, "Holofote", (38, 1.6, -53), (1.2, 1.2, 1.2), DARK, "Metal"))
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
    build_floor2(P, items)
    build_floor3(P, items)

    buttons = folder("Buttons")
    grids = [(BUTTONS_F1, 0, [10, 18, 26, 34, 42], [-42, -34, -26, -18]),
             (BUTTONS_F2, F2, [-2, 6, 14, 22, 30], [-42, -34, -26]),
             (BUTTONS_F3, F3, [-34, -26, -18, -10], [-40, -32])]
    for ids, dy, cols, rows in grids:
        L = Lift(P, dy)
        for i, bid in enumerate(ids):
            x, z = cols[i % len(cols)], rows[i // len(cols)]
            btn = part(L, bid, (x, 1.35, z), (5, 0.5, 5), GREEN, "Neon")
            btn.add(part(L, "MolduraBotao", (x, 1.15, z), (6.2, 0.3, 6.2), DARK, "Metal"))
            buttons.add(btn)
    t.add(base, items, buttons)
    return t

def build():
    ws = Node("Workspace", "Workspace")
    ws.add(part(WORLD, "Baseplate", (0, -0.5, 0), (320, 1, 320), (88, 160, 80), "Grass"),
           part(WORLD, "Rua", (0, 0.02, 0), (20, 0.05, 320), (70, 70, 75), "Concrete"),
           part(WORLD, "Rua", (0, 0.03, 0), (320, 0.05, 20), (70, 70, 75), "Concrete"),
           part(WORLD, "SpawnLocation", (0, 0.6, 0), (12, 1, 12), (155, 89, 182), "Neon", cls="SpawnLocation",
                extra=['<bool name="Neutral">true</bool>', '<int name="Duration">0</int>']))
    lobby = folder("Lobby")
    for sx in (-14, 14):
        lobby.add(part(WORLD, "PilarPlaca", (sx, 9, -9), (1.5, 18, 1.5), DARK, "Metal"))
    lobby.add(part(WORLD, "MolduraLobby", (0, 15.5, -9), (30, 8, 0.8), (155, 89, 182), "Neon"),
              part(WORLD, "PlacaLobby", (0, 15.5, -9.6), (28.5, 6.8, 0.5), (30, 32, 42)))
    for (tx, tz) in [(125, 30), (125, -30), (-125, 30), (-125, -30), (30, 125), (-30, 125), (30, -125), (-30, -125),
                     (130, 90), (-130, 90), (130, -90), (-130, -90), (90, 130), (-90, 130), (90, -130), (-90, -130)]:
        lobby.add(part(WORLD, "Tronco", (tx, 3, tz), (1.4, 6, 1.4), (110, 74, 45), "Wood"),
                  part(WORLD, "Copa", (tx, 7.5, tz), (6, 6, 6), (46, 160, 67), "Grass", shape=0),
                  part(WORLD, "Copa", (tx + 1, 9.5, tz - 0.5), (4, 4, 4), (60, 180, 80), "Grass", shape=0))
    for lz in (-120, -90, -60, -30, 30, 60, 90, 120):
        for lx in (-9, 9):
            lobby.add(part(WORLD, "Poste", (lx, 5, lz), (0.6, 10, 0.6), DARK, "Metal"),
                      part(WORLD, "LuzPoste", (lx, 10.2, lz), (1.2, 0.8, 1.2), (255, 240, 200), "Neon", collide=False))
    # telões de ranking (sobre a rua, dá para passar por baixo)
    for bx, name in ((25, "RankingRebirths"), (-25, "RankingDinheiro")):
        for pz in (-8.6, 8.6):
            lobby.add(part(WORLD, "PosteRanking", (bx, 9.5, pz), (0.8, 19, 0.8), DARK, "Metal"))
        lobby.add(part(WORLD, "MolduraRanking", (bx, 12.5, 0), (0.6, 13.4, 17.4), (255, 200, 40), "Neon"),
                  part(WORLD, name, (bx + (-0.5 if bx > 0 else 0.5), 12.5, 0), (0.4, 12.6, 16.6), (22, 24, 38)))
    # área VIP (fim da rua, ao sul do ponto de nascimento)
    vip = folder("AreaVIP")
    VZ = -136
    vip.add(part(WORLD, "PisoVIP", (0, 0.35, VZ), (36, 0.7, 30), (40, 30, 20), "Marble"),
            part(WORLD, "TapeteVIP", (0, 0.72, VZ + 6), (6, 0.05, 18), (192, 20, 40), "Fabric", collide=False),
            part(WORLD, "ParedeVIP", (0, 5.7, VZ - 14.5), (36, 10, 1), (255, 200, 40), "Metal"),
            part(WORLD, "ParedeVIP", (-17.5, 5.7, VZ), (1, 10, 30), (255, 200, 40), "Metal"),
            part(WORLD, "ParedeVIP", (17.5, 5.7, VZ), (1, 10, 30), (255, 200, 40), "Metal"),
            part(WORLD, "FrenteVIP", (-11, 5.7, VZ + 14.5), (14, 10, 1), (255, 200, 40), "Metal"),
            part(WORLD, "FrenteVIP", (11, 5.7, VZ + 14.5), (14, 10, 1), (255, 200, 40), "Metal"),
            part(WORLD, "SobrePortaVIP", (0, 9.2, VZ + 14.5), (8, 3, 1), (255, 200, 40), "Metal"),
            part(WORLD, "PortaVIP", (0, 4.2, VZ + 14.5), (8, 7, 0.6), (255, 215, 0), "Neon", transp=0.45),
            part(WORLD, "PlacaVIP", (0, 13.5, VZ + 15.2), (16, 4, 0.4), (25, 20, 35)),
            part(WORLD, "MolduraPlacaVIP", (0, 13.5, VZ + 14.9), (17, 5, 0.3), (255, 215, 0), "Neon"),
            part(WORLD, "BauVIP", (0, 1.9, VZ - 9), (4, 2.4, 2.6), (120, 60, 20), "Wood"),
            part(WORLD, "TampaBauVIP", (0, 3.4, VZ - 9), (4.2, 0.7, 2.8), (255, 200, 40), "Metal"),
            part(WORLD, "PedestalTrono", (-10, 1.3, VZ - 10), (6, 1.2, 5), (192, 20, 40), "Fabric"),
            part(WORLD, "Trono", (-10, 3.4, VZ - 10.5), (3.4, 3, 3), (255, 200, 40), "Metal"),
            part(WORLD, "EncostoTrono", (-10, 6, VZ - 12), (3.4, 5, 0.6), (255, 200, 40), "Metal"))
    for sx in (-12, 12):
        vip.add(part(WORLD, "SofaVIP", (sx, 1.6, VZ + 2), (3, 1.6, 10), (90, 20, 40), "Fabric"),
                part(WORLD, "EncostoSofaVIP", (sx + (-1.6 if sx < 0 else 1.6), 3, VZ + 2), (0.8, 2.6, 10), (90, 20, 40), "Fabric"))
    for (fx, fz) in ((-15, VZ - 12), (15, VZ - 12), (-15, VZ + 11), (15, VZ + 11)):
        vip.add(part(WORLD, "Vaso", (fx, 1.7, fz), (2, 2, 2), (255, 200, 40), "Metal"),
                part(WORLD, "Planta", (fx, 3.8, fz), (3, 3, 3), PLANT, "Grass", shape=0))
    vip.add(part(WORLD, "LustreVIP", (0, 9.6, VZ), (4, 0.6, 4), (255, 240, 200), "Neon", collide=False))
    ws.add(lobby, vip)
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
