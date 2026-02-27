# Documento de Diseño (Detallado) — Clon de Catan en Godot 4.4 (GDScript)
> **Orientado a Codex**: sistemas, estados, modelos, acciones y tickets “mergeables”.  
> **Alcance del core**: API de juego (sin UI). La UI/escenas las conectás vos.

---

## 0. Resumen
Vamos a desarrollar un clon de Catan para aprender Godot 4.4 y su capacidad de organizar un proyecto medianamente grande con buen desacople.

### Etapas
1. **Etapa 1 — Sandbox interactivo (sin flujo completo obligatorio)**  
   Construcción, jugadores, turnos básicos, recursos, estado del juego, validaciones, eventos y serialización.  
2. **Etapa 2 — Flujo completo + IA**  
   FSM completa (setup, tiradas, producción, 7/ladrón, etc.) y bots para testing.  
3. **Etapa 3 — Multiplayer**  
   Autoridad server, acciones serializables, replicación por eventos/snapshots, resync.

### Principios no negociables
- **Core sin UI**: `game/core` no instancia nodos, no accede a escenas, no usa Input.
- **Determinismo**: con `seed` fijo + secuencia de acciones, mismo resultado.
- **Acciones serializables** (command pattern): todo cambio de estado se ejecuta por `Action`.
- **Eventos** hacia afuera: UI/IA/Net se enteran por `GameEvent`.
- **Tickets pequeños**: cada ticket debe dejar el repo en estado funcional (tests o demo headless).

---

## 1. Estructura de proyecto (propuesta)
```
res://
  game/
    core/
      model/
        game_state.gd
        player_state.gd
        map_state.gd
        bank_state.gd
        deck_state.gd
        robber_state.gd
        config.gd
      hex/
        hex.gd
        hex_directions.gd
        hex_math.gd
        hex_ids.gd
      actions/
        action.gd
        action_types.gd
        build_road_action.gd
        build_settlement_action.gd
        build_city_action.gd
        end_turn_action.gd
        set_phase_action.gd          # útil para sandbox/debug
        roll_dice_action.gd          # etapa 2
        trade_bank_action.gd         # etapa 2
        ...
      rules/
        build_rules.gd
        resource_rules.gd
        robber_rules.gd
        trade_rules.gd
        victory_rules.gd
      reducers/
        apply_action.gd              # dispatcher: valida + aplica + emite eventos
      fsm/
        game_fsm.gd
        game_phases.gd
      events/
        game_event.gd
        event_bus.gd
      util/
        rng.gd
        ids.gd
        errors.gd
        serialize.gd
        asserts.gd

    facade/
      game_api.gd                    # entrada pública para UI/IA/Net

    ai/                              # etapa 2
      ai_agent.gd
      policies/
        random_policy.gd
        heuristic_policy.gd

    net/                             # etapa 3
      net_protocol.gd
      authority_server.gd
      client_proxy.gd

  tests/                             # opcional (puede ser scripts headless)
    test_hex.gd
    test_build_rules.gd
    test_apply_action.gd
    test_fsm.gd
```

### Convenciones
- `class_name` por archivo para uso cómodo.
- Todo lo serializable usa `to_dict()` / `from_dict()` (o helpers de `serialize.gd`).
- IDs **deterministas** (strings) para edges/vertices.
- Errores/validación: siempre devolver `ValidationResult` (no `push_error` desde core).

---

## 2. Definición del “Core API”
El core expone 2 capas:

### 2.1 Capa baja (pura)
- Modelos: `GameState`, `MapState`, `PlayerState`, etc.
- Sistemas/reglas: `BuildRules`, `ResourceRules`, `FSM`.
- Dispatcher: `ApplyAction` (valida/aplica, emite eventos).

### 2.2 Fachada (para UI/IA/Net)
`facade/game_api.gd` ofrece métodos simples y estables:

#### Métodos mínimos (Etapa 1)
- `new_game(config: GameConfig) -> void`
- `load_state(data: Dictionary) -> void`
- `save_state() -> Dictionary`
- `get_state() -> GameState` (o `Dictionary` readonly si preferís)
- `list_legal_actions(player_id: int) -> Array[Action]`
- `validate_action(action: Action) -> ValidationResult`
- `apply_action(action: Action) -> ApplyResult`
- `poll_events() -> Array[GameEvent]` *(si usás event queue)*
- `peek_phase() -> int`

> Nota: UI no muta estado directo: siempre manda `Action`.

---

## 3. Modelo del tablero (Hex + grafo Catan)
### 3.1 Hex (coordenadas cúbicas)
Usamos `Hex(q, r, s)` con invariante `q + r + s == 0`.

Operaciones:
- `add(a, b)`
- `neighbors(hex)`
- `distance(a, b)`
- `ring(center, radius)` / `spiral(center, radius)`

### 3.2 Grafo de construcción
Catan no construye “en hexes”, sino en:
- **Vertices** (intersecciones) → asentamiento / ciudad
- **Edges** (aristas) → caminos
- **Tiles** (hex) → terreno + token number + ladrón

#### IDs deterministas
Para estabilidad y serialización:
- `VertexId`: `"V:<q>,<r>,<s>:<corner>"` donde `corner` ∈ [0..5]
- `EdgeId`: `"E:<VertexIdA>|<VertexIdB>"` con A/B ordenados (lexicográfico)

> La implementación del mapeo “tile+corner -> vertex” y “tile+side -> edge” debe producir el MISMO ID aunque se llegue desde hex adyacente.  
> Esta consistencia es crítica para que el mapa funcione.

### 3.3 MapState (mínimo Etapa 1)
- `tiles: Dictionary[HexKey -> TileState]`
- `vertices: Dictionary[VertexId -> VertexState]`
- `edges: Dictionary[EdgeId -> EdgeState]`
- `ports: Dictionary[VertexId -> PortState]` *(opcional etapa 2)*
- `robber_hex: HexKey` *(etapa 2, desierto por defecto)*

`HexKey` puede ser string `"H:<q>,<r>,<s>"` para usar como key de diccionario.

---

## 4. Modelos (detallados)
### 4.1 GameConfig
- `seed: int`
- `map_rings: int` *(o preset “catan_standard”)*
- `player_count: int`
- `starting_resources: Dictionary` *(por defecto vacío)*
- `enable_ports: bool`
- `enable_dev_cards: bool`
- `victory_points_to_win: int` *(10 default)*

### 4.2 GameState
- `version: int`
- `seed: int`
- `turn_index: int`
- `current_player_id: int`
- `phase: int` *(enum `GamePhase`)*
- `players: Dictionary[int -> PlayerState]`
- `turn_order: Array[int]`
- `map: MapState`
- `bank: BankState`
- `deck: DeckState` *(etapa 2)*
- `robber: RobberState` *(etapa 2)*
- `flags: Dictionary` *(debug/sandbox)*

### 4.3 PlayerState
- `id: int`
- `name: String`
- `color_id: int` *(solo referencia para UI)*
- `resources: Dictionary[Resource -> int]`
- `dev_cards_hand: Array[int]` *(etapa 2)*
- `roads: Array[EdgeId]`
- `settlements: Array[VertexId]`
- `cities: Array[VertexId]`
- `victory_points: int` *(puede ser derivable por `VictoryRules`)*
- `played_dev_card_this_turn: bool` *(etapa 2)*
- `trade_rates: Dictionary[Resource -> int]` *(etapa 2)*

### 4.4 TileState
- `hex: HexKey`
- `terrain: int` *(enum Terrain)*
- `token_number: int` *(2..12, sin 7; desierto=0)*
- `has_robber: bool`

### 4.5 VertexState
- `owner_player_id: int` (-1 si vacío)
- `building: int` *(enum Building: NONE/SETTLEMENT/CITY)*

### 4.6 EdgeState
- `a: VertexId`
- `b: VertexId`
- `owner_player_id: int` (-1 si vacío)

### 4.7 BankState
- `stock: Dictionary[Resource -> int]` *(si modelás stock real)*
- `unlimited: bool` *(si preferís simplificar en etapa 1)*

### 4.8 RobberState (etapa 2)
- `hex: HexKey`
- `pending_steal_from: Array[int]` *(quiénes son elegibles)*
- `pending_discard: Dictionary[int -> int]` *(player -> cantidad a descartar)*

---

## 5. Enumeraciones (core)
### Resources
- WOOD, BRICK, SHEEP, WHEAT, ORE

### Terrain
- FOREST, HILLS, PASTURE, FIELDS, MOUNTAINS, DESERT

### Building
- NONE, SETTLEMENT, CITY

### GamePhase (mínimo etapa 1)
- SANDBOX
- TURN_START
- MAIN_ACTIONS
- TURN_END

### GamePhase (etapa 2, completa)
- SETUP_1
- SETUP_2
- TURN_START
- ROLL_OR_PLAY_DEV
- RESOLVE_ROLL
- MAIN_ACTIONS
- DISCARD
- MOVE_ROBBER
- STEAL
- END_TURN

---

## 6. Sistema de Acciones (Command Pattern)
### 6.1 Reglas
- Toda mutación se hace por `Action`.
- `Action` debe ser serializable (`to_dict` / `from_dict`).
- Validación separada de aplicación.

### 6.2 Action base
Campos:
- `type: String` *(o int enum)*
- `player_id: int`
- `payload: Dictionary`
- `nonce: int` *(para net, etapa 3)*

### 6.3 Acciones Etapa 1 (mínimas)
- `BUILD_ROAD { edge_id }`
- `BUILD_SETTLEMENT { vertex_id }`
- `BUILD_CITY { vertex_id }`
- `END_TURN {}`
- `SET_PHASE { phase }` *(solo debug/sandbox, opcional)*

### 6.4 Acciones Etapa 2 (agregar)
- `ROLL_DICE {}`
- `TRADE_WITH_BANK { give: {res:n}, take: {res:n} }`
- `MOVE_ROBBER { hex }`
- `DISCARD_RESOURCES { resources: {res:n} }`
- `STEAL_RESOURCE { from_player_id }`
- `PLAY_DEV_CARD { card_type, ... }`

---

## 7. Validación y resultados
### 7.1 ValidationResult
- `ok: bool`
- `code: String` *(ej: "NOT_YOUR_TURN", "EDGE_OCCUPIED")*
- `message: String`
- `details: Dictionary` *(opcional)*

### 7.2 ApplyResult
- `ok: bool`
- `events: Array[GameEvent]`
- `validation: ValidationResult` *(si ok=false)*

---

## 8. Event Bus
### 8.1 GameEvent
Campos:
- `type: String` *(ej: "BUILD_PLACED")*
- `payload: Dictionary`
- `turn_index: int` *(opcional)*

Eventos Etapa 1 (mínimos):
- `PHASE_CHANGED { from, to }`
- `TURN_STARTED { player_id }`
- `TURN_ENDED { player_id }`
- `BUILD_PLACED { building_type, owner_player_id, id }`
- `RESOURCE_CHANGED { player_id, delta: {res:n} }`
- `INVALID_ACTION { code, message, action_summary }`

> El core puede devolver eventos como array, y/o encolar en `EventBus` para que la UI los “poll”.

---

## 9. Reglas de construcción (BuildRules)
### 9.1 Objetivo
Resolver:
- Ocupación y tipo de building.
- Reglas de distancia para asentamientos.
- Conectividad por carreteras del jugador.
- Costos (si activado en etapa 1, opcional; en etapa 2 obligatorio).

### 9.2 Funciones
- `can_build_road(state, player_id, edge_id) -> ValidationResult`
- `can_build_settlement(state, player_id, vertex_id) -> ValidationResult`
- `can_build_city(state, player_id, vertex_id) -> ValidationResult`
- `road_would_connect_network(state, player_id, edge_id) -> bool`
- `vertex_is_far_enough(state, vertex_id) -> bool`
- `get_cost(building) -> Dictionary[Resource->int]`

> En etapa 1, podés permitir “free build” por flag (sandbox).  
> En etapa 2, costos siempre aplican.

---

## 10. FSM (máquina de estados)
### 10.1 Etapa 1 (simple)
- `TURN_START` -> `MAIN_ACTIONS` -> `TURN_END` -> siguiente jugador -> `TURN_START`
Acciones permitidas:
- `MAIN_ACTIONS`: build_* y end_turn
- otras fases: solo internas o debug

### 10.2 Etapa 2 (completa)
- Setup 1 / Setup 2 con orden y reglas especiales
- Loop de turnos con roll obligatorio (salvo dev), producción, 7, robber y steal.

La FSM debe exponer:
- `get_allowed_action_types(phase) -> Array`
- `on_action_applied(state, action, events) -> void` *(posible transición)*

---

## 11. Serialización
Requisito: **todo estado y acciones serializables a Dictionary**.

- `GameState.to_dict()` produce un Dictionary “plano” con keys estables.
- `GameState.from_dict(d)` reconstruye el estado.
- IDs de vertices/edges como string.
- HexKey como string.

> Para multiplayer (etapa 3) y tests (etapa 2), esta capa es crítica.

---

## 12. Testing (recomendado)
### 12.1 Tests Etapa 1
- Hex invariants: `q+r+s==0`, neighbors, distance.
- IDs deterministas de vertex/edge.
- BuildRules: no permite construir en ocupado, distancia, etc.
- ApplyAction: acción inválida no muta el estado.

### 12.2 Tests Etapa 2
- Determinismo: same seed + same actions -> same final hash.
- Montecarlo: N partidas con bots random sin crashear.
- Invariantes: recursos >= 0, IDs existentes, fases válidas.

---

## 13. “Definition of Done” (para tickets)
Un ticket está “done” si:
- Compila y corre en Godot 4.4.
- No introduce dependencias de UI en `core`.
- Tiene al menos 1 test headless o demo script reproducible.
- Documenta brevemente cómo verificarlo (README del ticket o comentario).

---

# 14. Plan de implementación (Tickets orientados a Codex)

> Cada ticket: objetivo + archivos + pasos + criterios de aceptación.  
> Codex debe implementarlos **en orden** para minimizar retrabajo.

---

## Ticket 01 — Scaffolding del Core + Convenciones
**Objetivo:** crear estructura de carpetas/archivos vacíos, enums, utilidades base.
**Archivos:**
- `game/core/util/errors.gd`, `serialize.gd`, `rng.gd`, `asserts.gd`
- `game/core/model/config.gd`
- `game/core/actions/action.gd`, `action_types.gd`
- `game/core/events/game_event.gd`, `event_bus.gd`
**Criterios de aceptación:**
- Proyecto abre sin errores.
- Se puede instanciar `EventBus`, `RNG`, `GameConfig`.
- `Action` y `GameEvent` tienen `to_dict()`.

---

## Ticket 02 — Librería Hex (cube coords)
**Objetivo:** implementar `Hex`, direcciones, distancia, ring/spiral.
**Archivos:**
- `game/core/hex/hex.gd`
- `game/core/hex/hex_directions.gd`
- `game/core/hex/hex_math.gd`
**Criterios de aceptación:**
- `Hex` valida `q+r+s==0` (assert opcional en debug).
- `neighbors()` devuelve 6 hex.
- `distance(a,a)==0`, `distance(a, neighbor)==1`.
- `ring(center, 1)` devuelve 6 hex, `spiral(center, 2)` devuelve 1+6+12 hex.

---

## Ticket 03 — IDs deterministas de Vertex/Edge
**Objetivo:** definir un esquema robusto de IDs y helpers.
**Archivos:**
- `game/core/hex/hex_ids.gd`
**Criterios de aceptación:**
- `vertex_id(hex, corner)` produce string estable.
- `edge_id(vertex_a, vertex_b)` produce string estable con orden.
- Dos formas equivalentes de llegar al mismo vertex/edge producen el mismo ID (tests/ejemplos).

---

## Ticket 04 — MapState básico + Generación de mapa (standard simplificado)
**Objetivo:** crear `MapState` y generar tiles/vertices/edges para un mapa de anillos.
**Archivos:**
- `game/core/model/map_state.gd`
- `game/core/model/tile_state.gd` *(si lo separás)*
- `game/core/model/vertex_state.gd`, `edge_state.gd`
- `game/core/model/game_state.gd` (stub mínimo)
- `game/core/util/ids.gd` (si querés separar helpers)
**Criterios de aceptación:**
- `MapState.generate_rings(rings, seed)` crea tiles con terrains y token_number (simple placeholder en etapa 1).
- `vertices` y `edges` se completan consistentemente (no duplicados).
- Se puede consultar por `get_vertex(vertex_id)` y `get_edge(edge_id)`.

---

## Ticket 05 — PlayerState + BankState
**Objetivo:** definir jugador y banco, recursos y helpers.
**Archivos:**
- `game/core/model/player_state.gd`
- `game/core/model/bank_state.gd`
- `game/core/model/game_state.gd` (completar)
**Criterios de aceptación:**
- Crear `GameState` con N jugadores y turno inicial.
- Métodos: `player_add_resources`, `player_can_pay`, `player_pay` (o en `BankState`).
- `to_dict/from_dict` funcional para estos modelos.

---

## Ticket 06 — BuildRules (validación completa Etapa 1)
**Objetivo:** implementar validaciones de construcción.
**Archivos:**
- `game/core/rules/build_rules.gd`
**Criterios de aceptación:**
- No permite construir road en edge ocupado.
- No permite settlement en vertex ocupado.
- Regla de distancia para settlements (no adyacentes).
- (Opcional etapa 1) Conectividad: road/settlement deben conectar a red del jugador, configurable por `sandbox_free_build`.

---

## Ticket 07 — Sistema de Acciones (acciones base)
**Objetivo:** implementar clases de acciones y serialización.
**Archivos:**
- `game/core/actions/build_road_action.gd`
- `game/core/actions/build_settlement_action.gd`
- `game/core/actions/build_city_action.gd`
- `game/core/actions/end_turn_action.gd`
**Criterios de aceptación:**
- Cada acción puede crearse y serializarse (to_dict/from_dict).
- `ActionFactory.from_dict()` (si la agregás) reconstruye acciones por type.

---

## Ticket 08 — ApplyAction (dispatcher) + Eventos básicos
**Objetivo:** validar, aplicar mutaciones y emitir eventos.
**Archivos:**
- `game/core/reducers/apply_action.gd`
- `game/core/events/event_bus.gd` (si es queue)
**Criterios de aceptación:**
- Acción válida muta estado y devuelve eventos `BUILD_PLACED`.
- Acción inválida retorna `ApplyResult.ok=false` y evento `INVALID_ACTION`, y **no muta estado**.
- `END_TURN` cambia jugador y emite `TURN_ENDED` + `TURN_STARTED`.

---

## Ticket 09 — FSM mínima (Etapa 1) + Allowed actions
**Objetivo:** agregar fases simples, y bloquear acciones por fase.
**Archivos:**
- `game/core/fsm/game_phases.gd`
- `game/core/fsm/game_fsm.gd`
**Criterios de aceptación:**
- `MAIN_ACTIONS` permite construir y end_turn.
- `TURN_START/TURN_END` bloquean construcción.
- Transiciones automáticas correctas al aplicar acciones.

---

## Ticket 10 — GameAPI (fachada) lista para UI
**Objetivo:** exponer una API estable a la vista.
**Archivos:**
- `game/facade/game_api.gd`
**Criterios de aceptación:**
- UI puede: `new_game`, `list_legal_actions`, `apply_action`, `poll_events`.
- No hay imports de UI dentro de core.
- Incluye método `get_snapshot()` (dict) para debug.

---

## Ticket 11 — Serialización completa de GameState (save/load)
**Objetivo:** poder guardar/cargar una partida sin UI.
**Archivos:**
- `game/core/util/serialize.gd` (completar)
- `game/core/model/*` (to_dict/from_dict)
**Criterios de aceptación:**
- `save_state()` seguido de `load_state()` reproduce el mismo estado (hash o comparación profunda).
- IDs de vertex/edge se conservan.

---

## Ticket 12 — Scripts de verificación headless (smoke tests)
**Objetivo:** crear scripts ejecutables para validar rápido.
**Archivos:**
- `tests/test_hex.gd`
- `tests/test_build_rules.gd`
- `tests/test_apply_action.gd`
**Criterios de aceptación:**
- Se pueden ejecutar en modo headless y reportan pass/fail.
- Cubren al menos: hex distance, build invalid, apply invalid not mutate.

---

# Etapa 2 — Tickets (Flujo completo + IA)

## Ticket 13 — Dados + producción de recursos
- `ROLL_DICE`, `ResourceRules.produce`
- Eventos: `DICE_ROLLED`, `RESOURCES_PRODUCED`, `RESOURCE_CHANGED`
- Criterio: producción consistente con edificios adyacentes (settlement=1, city=2), ignorar robber.

## Ticket 14 — Robber + descarte por 7
- `RobberRules.on_seven`, fase DISCARD, fase MOVE_ROBBER, fase STEAL
- Acciones: `DISCARD_RESOURCES`, `MOVE_ROBBER`, `STEAL_RESOURCE`
- Criterio: jugadores con >7 descartan mitad (floor), robber bloquea producción.

## Ticket 15 — Costos y banco real
- Enforce costos de build
- Bank con stock real (opcional simplificado)
- Criterio: no permite construir sin recursos.

## Ticket 16 — Trade con banco + puertos
- `TRADE_WITH_BANK`, `trade_rates`
- Criterio: 4:1 default, 3:1 o 2:1 según puerto.

## Ticket 17 — VictoryRules
- cálculo de puntos (settlement/city + extras opcionales)
- fin de juego y evento `GAME_ENDED`
- Criterio: se detecta ganador correctamente.

## Ticket 18 — IA RandomPolicy + simulador
- `AIAgent.choose_action`
- Simular partidas con seeds
- Criterio: N partidas sin crash, métricas básicas.

---

# Etapa 3 — Tickets (Multiplayer)

## Ticket 19 — Protocolo de red (acciones + eventos)
- `net_protocol.gd`: encode/decode actions/events
- nonce, turn_index, sync hashes
- Criterio: acciones via red se reconstruyen igual que local.

## Ticket 20 — Server autoritativo + ClientProxy
- Server valida/aplica, clientes solo envían acciones
- Criterio: un cliente no puede aplicar acción inválida (server rechaza).

## Ticket 21 — Resync por snapshot
- Snapshot del state, rejoin
- Criterio: cliente desfasado vuelve a sync.

---

# 15. Prompts recomendados para Codex (copiar/pegar)

## Prompt base (planificar ticket)
“Leé `docs/design_codex.md`. Implementá **solo** el Ticket XX.  
No avances a otros tickets.  
No uses nodos/UI.  
Agregá/actualizá tests correspondientes en `tests/`.  
Al finalizar, imprimí un resumen de archivos tocados y cómo verificar.”

## Prompt para revisión de cambios
“Mostrame el diff y justificá decisiones. Verificá invariantes. Si algo queda dudoso, agregalo en `docs/decisions.md`.”

## Prompt para refactor seguro
“Refactorizá sin cambiar comportamiento: mantené tests pasando y serialización estable.”

---

## 16. Notas de implementación (consejos)
- Empezá con **free-build sandbox** y luego activás costos/flujo completo.
- Dejá banderas en `GameConfig` para habilitar/deshabilitar reglas.
- Asegurá determinismo: RNG propio (`util/rng.gd`) y no uses `randi()` global.
- Evitá `Node` dentro del core. Si necesitás señales, usá `EventBus` con cola.

---

Fin.
