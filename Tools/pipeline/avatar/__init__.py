# -*- coding: utf-8 -*-
"""Player-avatar composer for CY-Source (CLI: Tools/pipeline/avatar.py).

Builds complete player looks (body parts, face, hair, costume, weapons, ornaments, mount + rider)
as synthetic LogicModel objects in the all.obj dialect, so TlbbViewer and oracle tests can show
what the game shows.  Everything here is read-only on client_GL.

Modules
  rules     assembly rules recovered from the 0.85 source and the client_GL Game.exe decompiles,
            each with file:line evidence
  data      read-only access to client_GL tables, all.obj, all.material, all.effect, files
  objxml    LogicModel object XML parse / edit / write (byte-exact GBK via a latin-1 bridge)
  compose   AvatarSpec -> composite objects
  validate  reference checks of generated objects against client_GL
  gallery   the 2026 gallery set -> Assets/Staging/avatars
"""
__version__ = '1.0'
