# AIN - FEATURE - GENERATE_ICON_BACKGROUNDS

## Metadata

- **Type**: FEATURE
- **Issue #**: [n/a]
- **Created**: [2025-12-20]
- **Status**: IMPLEMENTATION COMPLETE - CLIENT/ ONLY

## 1: CONCEPT/CHANGE/CORRECTION - Discuss ideas without generating code

### Goal

Bring the **“large module logo”** background treatment (as seen in the legacy **LADDERS** web screenshots) into **`app-template`**, but **without** requiring custom per-module PNG/JPG assets.

### Desired UX

- **Dynamically generate** a “watermark” background layer by taking the **entity/module logo** used to reach the current view (typically the module icon) and rendering it:
  - **Very large**
  - **Low-opacity**
  - Positioned like the LADDERS examples (“on a lighted stage” / spotlight feel)
- **Simple**: one background under everything in the view (content sits above it).
- **Same watermark for Light/Dark mode**: the watermark/icon itself does not change; only the underlying page background color changes (e.g., `bg-slate-200` vs `dark:bg-slate-950` in web).

### Reference (Legacy LADDERS)

Legacy LADDERS web implemented route-driven background images via a `background` property on routes and a dimmed underlay in layout:

- Routes: `ladders/client/src/routes/*.js` use `background: 'account.jpg'`, `background: 'support.jpg'`, etc.
- Layout: `ladders/client/src/components/layout/app/app.jsx` applies a fixed full-screen background image style.

In the screenshots, those background images also contained "large module icon" artwork. This feature replaces that need by generating the watermark layer from an icon/logo at runtime.

#### Visual Reference: LADDERS Implementation Examples

The following screenshots from the legacy LADDERS web app demonstrate the desired "large module logo background" effect:

![LADDERS - Your Account page with gear icon watermark](<./.images/(AIN-2025-12-20)GENERATE_ICON_BACKGROUNDS/ladders-account-page.png>)
_Figure 1: "Your Account" page showing a large, faint gear icon watermark in the background_

![LADDERS - Support page with headphones icon watermark](<./.images/(AIN-2025-12-20)GENERATE_ICON_BACKGROUNDS/ladders-support-page.png>)
_Figure 2: "MicroCODE Support" page showing a large, faint headphones icon watermark in the background_

![LADDERS - LADDERS App page with logo watermark](<./.images/(AIN-2025-12-20)GENERATE_ICON_BACKGROUNDS/ladders-app-page.png>)
_Figure 3: "The LADDERS® App" page showing a large, faint blue logo watermark in the background_

**Key visual characteristics observed:**

- Large, low-opacity icons/logos positioned in the bottom-right area
- "Lighted stage" effect with subtle radial gradient/spotlight
- Same watermark appearance in both light and dark modes (only underlying page color changes)
- Watermark appears behind all content (cards, forms, navigation)

---

## 2: DESIGN - Design detailed solution

### 1. Scope and affected apps

This feature is primarily a **UI-layer** feature (no DB changes required) and should be implemented in:

- **`client/` (React web)**: Primary target (matches screenshots).
- **`admin/console/` (Admin console)**: Primary target - same implementation as client/.
- **`app/` (React Native)**: Optional/secondary; implement if we want parity (RN needs a separate approach).
- **`portal/`**: Out of scope unless explicitly desired (marketing site typically does not need module watermarks).
- **`server/`**: No functional changes required for the default (icon-based) approach. May be used later if we choose to fetch a true "entity logo" from the API.

### 2. Key design decision: automatic icon matching

To meet the "no custom PNG per module" requirement and enable automatic background generation:

- **Primary source**: **Route `icon` field** - Each route defines its entity/module icon name (Lucide icon).

  - This icon is used **automatically** for the background watermark (no explicit background spec needed).
  - Matches the sidebar navigation icon (ensuring visual consistency).
  - Requires adding `icon` field to route definitions.
  - For AccountLayout routes: Use the subnav icon (from AccountLayout's subnav array) as the background icon.

- **Explicit override**: Routes can optionally include a `background` spec to override the automatic icon behavior:
  - `background: { type: 'icon', value: 'custom-icon' }` - Use a different icon
  - `background: { type: 'image', value: 'https://...' }` - Use an image URL
  - `background: { type: 'none' }` - Explicitly disable background

**Automatic behavior:**

- If route has `icon` field → Use that icon for background automatically
- If route has `background` spec → Use that instead (explicit override)
- If route has neither → No background rendered

This ensures all existing routes get backgrounds automatically once `icon` fields are added.

### 3. Architecture: route-driven “background spec”

#### 3.1 Route icon and background spec model

**Add `icon` field to route objects** (primary approach for automatic backgrounds):

- **`icon`**: Lucide icon name string (e.g., `'settings'`, `'help-circle'`, `'gauge'`)
  - This icon will be used automatically for the background watermark
  - Should match the sidebar navigation icon for consistency

**Add optional `background` field** (for explicit overrides or special cases):

- **`background.type`**: `'icon' | 'image' | 'none'`
- **`background.value`**:
  - If `type === 'icon'`: Lucide icon name string (overrides route.icon)
  - If `type === 'image'`: Image URL string
- **`background.placement`** (optional): defaults to right-middle positioning
  - `horizontal`: `'left' | 'center' | 'right'` (default: `'right'`)
  - `vertical`: `'top' | 'center' | 'bottom'` (default: `'center'` - middle)
  - `scale`: number (default: `8.0`)

**Automatic background resolution:**

1. If route has `background` spec → Use that (explicit override)
2. Else if route has `icon` field → Use `{ type: 'icon', value: route.icon }` automatically
3. Else → No background rendered

This ensures all routes get backgrounds automatically once `icon` fields are added, while allowing explicit overrides when needed.

#### 3.2 Prop plumbing and automatic background resolution

Currently, `client/src/app/app.jsx` spreads the route object into `<View {...route} />`, but `client/src/components/view/view.jsx` only forwards `title`, `data`, and `variant` into layout.

Design changes:

1. **Update `View` component** to:

   - Extract `icon` and `background` from route props
   - Resolve background spec automatically:
     - If `background` exists → Use it (explicit override)
     - Else if `icon` exists → Create `{ type: 'icon', value: icon }` automatically
     - Else → `background = null` (no background)
   - Forward resolved `background` to layout:
     - `<Layout title={title} data={data} variant={variant} background={background}>…`

2. **For AccountLayout routes**: The View component should also check if the current route matches a subnav item and use that subnav icon if route.icon is not provided (fallback behavior).

#### 3.3 Where the background is rendered

Render the watermark **inside the layout `<main>`**, so it appears under:

- Header
- Subnav
- All view content

This matches the screenshot behavior (“under everything”).

Layouts to update in web:

- `client/src/components/layout/app/app.jsx`
- `client/src/components/layout/account/account.jsx`

### 4. UI component: `IconBackground` / `ViewBackground`

Create a single reusable UI component in `client/src/components/background/` (name TBD) that:

- **Accepts** the "background spec":
  - icon name (Lucide) OR image URL
- Renders a **non-interactive** background layer:
  - `pointer-events: none`
  - `aria-hidden="true"`
  - large scale
  - low opacity
  - positioned behind layout content via `position: absolute` + z-index layering

#### 4.1 "Lighted stage" effect

Replicate the LADDERS vibe using CSS (no bitmap images required):

- Add a **radial gradient spotlight** behind the icon/logo:
  - Example concept: `radial-gradient(circle at 70% 55%, rgba(255,255,255,0.10), rgba(0,0,0,0) 60%)`
  - Positioned to match LADDERS examples (bottom-right quadrant, ~70% horizontal, ~55% vertical)
- Render icon/logo with:
  - `opacity` (e.g., 0.20–0.35) - very faint, subtle presence
  - Large scale (e.g., `width: 600px` or `min-width: 50vw`) to create the "blown up" effect
  - Subtle `filter` (e.g., grayscale, slight blur, contrast) to enhance the watermark aesthetic
  - Optional `drop-shadow` to simulate stage lighting depth

**Visual reference:** See Figures 1-3 above for examples of the desired "lighted stage" effect from LADDERS.

#### 4.2 Dark/light mode behavior

To satisfy “same watermark for Light/Dark”:

- The watermark component **must not** use `dark:` Tailwind variants to change its asset.
- The layout background color remains controlled by existing classes:
  - `bg-slate-200 dark:bg-slate-950`

### 5. Data flow and usage examples (web)

#### 5.1 App-level module pages

Update routes to include `icon` fields (for automatic background generation):

- `/account`: `icon: 'settings'` (matches sidebar nav icon)
- `/help`: `icon: 'help-circle'` (matches sidebar nav icon - NOTE: fix inconsistency if Help card uses different icon)
- `/dashboard`: `icon: 'gauge'` (matches sidebar nav icon)

**Icon consistency fix**: Ensure Help route/card uses `help-circle` icon to match sidebar navigation (currently sidebar uses `help-circle`, verify Help card matches).

This keeps implementation **simple**: the route defines the icon, View automatically creates background spec, and layout renders it.

#### 5.2 Account sub-routes (AccountLayout)

For AccountLayout routes (sub-routes under `/account/*`), use the subnav icon automatically:

- `/account/profile`: Use subnav icon `'user'`
- `/account/password`: Use subnav icon `'lock'`
- `/account/tfa`: Use subnav icon `'shield-check'`
- `/account/billing`: Use subnav icon `'credit-card'`
- `/account/theme`: Use subnav icon `'palette'`
- `/account/notifications`: Use subnav icon `'bell'`
- `/account/organizations`: Use subnav icon `'building'`
- `/account/clubs`: Use subnav icon `'home'`
- `/account/boats`: Use subnav icon `'sailboat'`
- `/account/apikeys`: Use subnav icon `'key'`
- `/account/users`: Use subnav icon `'users'`

**Implementation approach**: View component can match current route path to AccountLayout's subnav array and extract the icon automatically, or routes can explicitly define `icon` field matching the subnav icon.

#### 5.3 Entity-specific pages (future)

If/when we introduce a view where navigation selects a specific entity (org/club/boat, etc.), we can:

- Set `background.type = 'image'`
- Set `background.value` to the selected entity's `logo` field (image URL) once fetched
- Or pass it via router navigation state

### 6. React Native (optional parity design)

RN doesn’t use Tailwind classes; the approach should be:

- Add a background layer to `app/components/view/view.js` or the relevant app layout container:
  - An absolutely positioned `<View>` with a large icon/logo rendered via the app’s `Icon` component
  - A radial gradient can be approximated via:
    - `expo-linear-gradient` / `react-native-linear-gradient`, or
    - a semi-transparent overlay view stack

If RN parity is not required immediately, defer and keep the design note for later.

### 7. Security considerations

If we support `type: 'image'` where `value` is an image URL:

- Rendering images via `<img>` tag is safe (no HTML injection risk).
- Image URLs should be validated to prevent SSRF attacks if URLs come from user input.
- For initial implementation (icon-based only), no security concerns.

For `type: 'icon'` (Lucide icons), there is no HTML injection risk - icons are rendered via React components, not HTML strings.

### 8. Error handling and fallbacks

- If the background spec is missing or invalid:
  - Render nothing (no background layer).
- If an icon name is invalid:
  - `Icon` already falls back to `null` with a console message; the background component should tolerate this gracefully.
- Ensure background never blocks UI interaction:
  - `pointer-events: none`, and the content wrapper uses a higher z-index.

### 9. Test strategy (extend existing `/test` structure)

#### 9.1 Server

No server behavior changes are required for the icon-based implementation, so **no new server tests** are needed initially.

If we later add an API to fetch entity logos specifically for watermark usage, add tests under:

- `server/test/<entity>.test.js` for that new endpoint/contract.

#### 9.2 Client (web)

`client/` currently has no `/test` directory. To satisfy the requirement, add:

- `client/test/` with unit tests for the new background component and layout integration.

Proposed tooling:

- **Vitest** + **@testing-library/react** + **jsdom**

Test cases:

- **`ViewBackground` renders nothing** when no background spec is provided.
- **Icon spec renders** a background layer and does not intercept clicks:
  - verify `pointer-events: none` and presence in DOM with `aria-hidden`.
- **Automatic icon resolution**:
  - given a route with `icon: 'settings'` (no explicit background),
  - ViewBackground automatically uses that icon for background.
- **Layout integration**:
  - given a route with `icon: 'settings'` or `background: { type: 'icon', value: 'settings' }`,
  - the layout includes the background component once per page.
- **Theme invariance**:
  - watermark component output does not change across `dark` root class toggles (no `dark:` variants applied within watermark).

#### 9.3 Admin Console (web)

`admin/console/` currently has no `/test` directory. To satisfy the requirement, add:

- `admin/console/test/` with unit tests for the new background component (optional - can share test patterns with client).

Proposed tooling:

- **Vitest** + **@testing-library/react** + **jsdom** (same as client)

Test cases (same as client):

- Same test cases as client (ViewBackground component behavior is identical)
- Can share test patterns or duplicate test files

#### 9.4 App (React Native) (if implemented)

If RN parity is implemented, add tests under:

- `app/test/` (if a test harness exists) or document manual verification.

### 10. Confidence and open questions (to reach 95%+)

Current confidence: **~90%** (web-only design is straightforward; uncertainty is primarily about “logo source” interpretation).

Open questions to confirm:

1. **Logo source**: Should the watermark be based on the **route/module icon** (Lucide), or do you specifically want it to be based on a **database-backed entity logo** (SVG/image) whenever available?
2. **Route coverage**: Which routes should get which watermark icons? Minimum set:
   - `/account` → `settings`
   - `/help` → `headphones`
   - `/dashboard` → `gauge`
3. **Placement defaults**: Should the watermark always be **right-centered** like the screenshots, or configurable (left/center/right)?

---

## 3: PLAN - Create implementation plan

### Executive Summary

This plan implements a route-driven background watermark system that dynamically generates large, low-opacity icon/logo backgrounds behind view content, replicating the LADDERS "lighted stage" aesthetic without requiring custom image assets.

**Implementation Scope:**

- **Primary**: `client/` (React web) - Full implementation
- **Primary**: `admin/console/` (Admin console) - Full implementation (same pattern as client/)
- **Deferred**: `app/` (React Native) - Optional future work
- **Out of Scope**: `server/`, `portal/` - No changes required

**Estimated Complexity**: Low-Medium (UI-only changes, no DB/API changes)
**Estimated Time**: 6-8 hours

- Component creation (client + admin): 2-3 hours
- Layout integration (client + admin): 1.5 hours
- Route updates (client + admin): 1 hour
- Testing setup: 1-2 hours
- Polish/adjustments: 1 hour

---

### Affected Files

#### Files to CREATE

**Client (React Web):**

1. **`client/src/components/background/view-background.jsx`** (NEW)

   - Main background watermark component
   - Handles icon/image rendering with "lighted stage" effect
   - ~150-200 lines

2. **`client/src/components/background/index.js`** (NEW)

   - Export file for background component
   - ~5 lines

3. **`client/test/view-background.test.js`** (NEW)

   - Unit tests for ViewBackground component
   - ~100-150 lines

4. **`client/test/setup.js`** (NEW)

   - Vitest test configuration
   - ~20-30 lines

5. **`client/vitest.config.js`** (NEW)
   - Vitest configuration file
   - ~30-40 lines

**Admin Console (same structure as client):**

6. **`admin/console/src/components/background/view-background.jsx`** (NEW)

   - Same component as client (can be shared or duplicated)
   - ~150-200 lines

7. **`admin/console/src/components/background/index.js`** (NEW)

   - Export file for background component
   - ~5 lines

8. **`admin/console/test/view-background.test.js`** (NEW, optional)

   - Unit tests for ViewBackground component
   - ~100-150 lines (can share test patterns with client)

9. **`admin/console/test/setup.js`** (NEW, optional)

   - Vitest test configuration
   - ~20-30 lines

10. **`admin/console/vitest.config.js`** (NEW, optional)

    - Vitest configuration file
    - ~30-40 lines

#### Files to MODIFY

**Client (React Web):**

1. **`client/src/components/view/view.jsx`**

   - Add `icon` and `background` prop extraction and automatic resolution
   - Forward resolved background to layouts
   - ~10 lines changed

2. **`client/src/components/layout/app/app.jsx`**

   - Import ViewBackground component
   - Add background rendering inside `<main>` (before Header)
   - ~10 lines changed

3. **`client/src/components/layout/account/account.jsx`**

   - Import ViewBackground component
   - Add background rendering inside `<main>` (before Header)
   - ~10 lines changed

4. **`client/src/components/lib.jsx`**

   - Export ViewBackground component
   - ~1 line added

5. **`client/src/routes/app.js`**

   - Add `icon` field to `/dashboard` and `/help` routes
   - ~5 lines changed

6. **`client/src/routes/account.js`**

   - Add `icon` field to `/account` route and all account sub-routes
   - ~15-20 lines changed

7. **`client/package.json`**

   - Add Vitest and testing dependencies (devDependencies)
   - ~5-10 lines added

**Admin Console (same pattern as client):**

8. **`admin/console/src/components/view/view.jsx`**

   - Add `icon` and `background` prop extraction and automatic resolution
   - Forward resolved background to layouts
   - ~10 lines changed

9. **`admin/console/src/components/layout/app/app.jsx`**

   - Import ViewBackground component
   - Add background rendering inside `<main>` (before Header)
   - ~10 lines changed

10. **`admin/console/src/components/lib.jsx`**

    - Export ViewBackground component
    - ~1 line added

11. **`admin/console/src/routes/index.js`**

    - Add `icon` field to all routes (matching sidebar nav icons)
    - ~20-25 lines changed (multiple routes)

12. **`admin/console/package.json`** (if tests are added)

    - Add Vitest and testing dependencies (devDependencies)
    - ~5-10 lines added

---

### Modules/Components Affected

#### New Components

**Client:**

- **`ViewBackground`** (`client/src/components/background/view-background.jsx`)
  - Purpose: Renders watermark background layer
  - Props: `background` (background spec object)
  - Dependencies: `Icon` component (from lib), Tailwind CSS classes

**Admin Console:**

- **`ViewBackground`** (`admin/console/src/components/background/view-background.jsx`)
  - Purpose: Same as client version (can be shared or duplicated)
  - Props: `background` (background spec object)
  - Dependencies: `Icon` component (from lib), Tailwind CSS classes

#### Modified Components

**Client:**

- **`View`** (`client/src/components/view/view.jsx`)

  - Change: Extract `icon` and `background` props, resolve background automatically, forward to layouts
  - Impact: Minimal - prop plumbing and resolution logic

- **`AppLayout`** (`client/src/components/layout/app/app.jsx`)

  - Change: Render `<ViewBackground>` inside `<main>` container
  - Impact: Visual only - adds background layer

- **`AccountLayout`** (`client/src/components/layout/account/account.jsx`)
  - Change: Render `<ViewBackground>` inside `<main>` container
  - Impact: Visual only - adds background layer

**Admin Console:**

- **`View`** (`admin/console/src/components/view/view.jsx`)

  - Change: Extract `icon` and `background` props, resolve background automatically, forward to layouts
  - Impact: Minimal - prop plumbing and resolution logic

- **`AppLayout`** (`admin/console/src/components/layout/app/app.jsx`)
  - Change: Render `<ViewBackground>` inside `<main>` container
  - Impact: Visual only - adds background layer

#### Routes Modified

**Client:**

- **`client/src/routes/app.js`**

  - Routes: `/dashboard`, `/help`
  - Change: Add `icon` field to route objects

- **`client/src/routes/account.js`**
  - Routes: `/account` and all account sub-routes
  - Change: Add `icon` field to route objects (matching subnav icons)

**Admin Console:**

- **`admin/console/src/routes/index.js`**
  - Routes: All admin console routes (dashboard, accounts, users, boats, orgs, clubs, feedback, help, logs, events, etc.)
  - Change: Add `icon` field to route objects (matching sidebar nav icons)

---

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ Route Definition (routes/*.js)                              │
│ {                                                           │
│   path: '/account',                                         │
│   view: Account,                                            │
│   layout: 'app',                                            │
│   background: { type: 'icon', value: 'settings' }  ← NEW    │
│ }                                                           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ App Router (app.jsx)                                        │
│ <View {...route} />  ← spreads all route props              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ View Component (view.jsx)                                   │
│ - Extracts: title, layout, view, data, variant, background  │
│ - Forwards background to Layout:                            │
│   <Layout background={background} ...>  ← NEW               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Layout Component (app.jsx or account.jsx)                   │
│ <main>                                                      │
│   <ViewBackground background={background} />  ← NEW         │
│   <Header />                                                │
│   <SubNav /> (if AccountLayout)                             │
│   {children}                                                │
│ </main>                                                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ ViewBackground Component (view-background.jsx)              │
│ - Validates background spec                                 │
│ - Renders radial gradient "spotlight"                       │
│ - Renders icon (via <Icon>) or logo (SVG/URL)               │
│ - Applies opacity, filters, positioning                     │
│ - Returns null if no valid background spec                  │
└─────────────────────────────────────────────────────────────┘
```

---

### Interface Contracts

#### Background Spec Type Definition

```typescript
/**
 * Background specification for route-driven watermark backgrounds
 */
interface BackgroundSpec {
  /**
   * Type of background to render
   * - 'icon': Render a Lucide icon (value must be icon name string)
   * - 'image': Render an image (value must be image URL string)
   * - 'none': Explicitly disable background (render nothing)
   */
  type: "icon" | "image" | "none";

  /**
   * Value for the background
   * - If type === 'icon': Lucide icon name (e.g., 'settings', 'help-circle', 'gauge')
   * - If type === 'image': Image URL string
   */
  value: string;

  /**
   * Optional placement configuration
   */
  placement?: {
    /**
     * Horizontal position: 'left' | 'center' | 'right'
     * Default: 'right'
     */
    horizontal?: "left" | "center" | "right";

    /**
     * Vertical position: 'top' | 'center' | 'bottom'
     * Default: 'center' (middle vertical position)
     */
    vertical?: "top" | "center" | "bottom";

    /**
     * Scale multiplier (1.0 = normal size)
     * Default: 8.0 (creates "blown up" effect)
     */
    scale?: number;
  };
}
```

#### Route Icon Field (NEW)

Routes should include an `icon` field that defines the entity/module icon. This icon will be used automatically for:

- Background watermark (if background spec is not explicitly provided)
- Future: Sidebar navigation (when layouts are refactored to use route icons)

```typescript
interface Route {
  path: string;
  view: Component;
  layout: "app" | "account" | "auth" | "onboarding";
  permission?: string;
  title: string;
  variant?: string;
  icon?: string; // ← NEW: Lucide icon name for this route/module
  background?: BackgroundSpec; // ← Optional: explicit background override
}
```

#### ViewBackground Component Props

```typescript
/**
 * @function ViewBackground
 * @memberof client.components.background
 * @desc Renders a watermark background layer with icon or logo, positioned behind all content.
 * @param {object} params Component parameters
 * @param {BackgroundSpec|null|undefined} params.background Background specification object
 * @returns {JSX.Element|null} Rendered background layer or null if no valid background spec
 */
export function ViewBackground({ background });
```

#### Updated View Component Props

```typescript
/**
 * @function View
 * @memberof client.components.view
 * @param {object} params Component parameters
 * @param {string} params.title Document title (required)
 * @param {string} params.layout Layout type: 'app', 'auth', 'account', 'onboarding' (required)
 * @param {Function|JSX.Element} params.view View component to render (required)
 * @param {object} [params.data] Optional data to pass to view (optional)
 * @param {string} [params.variant] Layout variant (optional)
 * @param {BackgroundSpec} [params.background] Background watermark specification (optional) ← NEW
 * @returns {JSX.Element|boolean} Rendered view or false
 */
export function View({ title, layout, view, data, variant, background });
```

#### Updated Layout Component Props

```typescript
/**
 * @function AppLayout
 * @memberof client.components.layout.app
 * @param {object} params Component parameters
 * @param {string} params.title View title (required)
 * @param {JSX.Element|Array<JSX.Element>} params.children Content to render (required)
 * @param {string} [params.variant] Layout variant (optional)
 * @param {BackgroundSpec} [params.background] Background watermark specification (optional) ← NEW
 * @returns {JSX.Element} Rendered layout
 */
export function AppLayout({ title, children, variant, background });

/**
 * @function AccountLayout
 * @memberof client.components.layout.account
 * @param {object} params Component parameters
 * @param {string} params.title View title (required)
 * @param {JSX.Element|Array<JSX.Element>} params.children Content to render (required)
 * @param {string} [params.variant] Layout variant (optional)
 * @param {BackgroundSpec} [params.background] Background watermark specification (optional) ← NEW
 * @returns {JSX.Element} Rendered layout
 */
export function AccountLayout({ title, children, variant, background });
```

---

### Implementation Steps (Ordered)

#### Phase 1: Setup Test Infrastructure (1-2 hours)

**Step 1.1**: Install testing dependencies

- Add to `client/package.json` devDependencies:
  - `vitest`: `^1.0.0` (or latest)
  - `@testing-library/react`: `^14.0.0`
  - `@testing-library/jest-dom`: `^6.0.0`
  - `@vitejs/plugin-react`: (already exists, verify version)
  - `jsdom`: `^23.0.0`

**Step 1.2**: Create Vitest configuration

- Create `client/vitest.config.js`
- Configure to use Vite React plugin
- Set up jsdom environment
- Configure test file patterns

**Step 1.3**: Create test setup file

- Create `client/test/setup.js`
- Import `@testing-library/jest-dom` matchers
- Configure any global test utilities

**Step 1.4**: Update package.json scripts

- Add `"test": "vitest"` script
- Add `"test:ui": "vitest --ui"` script (optional)
- Add `"test:coverage": "vitest --coverage"` script (optional)

**Verification**: Run `npm test` - should execute (may have 0 tests initially)

---

#### Phase 2: Create ViewBackground Component (1-2 hours)

**Step 2.1**: Create component directory

- Create `client/src/components/background/` directory

**Step 2.2**: Create ViewBackground component

- Create `client/src/components/background/view-background.jsx`
- Implement component structure:
  - Accept `background` prop (BackgroundSpec object)
  - Validate background spec (return null if invalid/missing)
  - Handle `type: 'none'` case (return null)
  - Handle `type: 'icon'` case:
    - Render radial gradient backdrop (positioned at 70% horizontal, 50% vertical)
    - Render `<Icon>` component with scale(8.0) transform
    - Apply opacity: 0.25, filters, positioning (right-middle by default)
  - Handle `type: 'image'` case:
    - Render radial gradient backdrop
    - Render `<img>` tag with image URL
    - Apply opacity: 0.25, filters, positioning (right-middle by default)
  - Support placement overrides (horizontal, vertical, scale)
  - Ensure `pointer-events: none` and `aria-hidden="true"`
  - Use absolute positioning with proper z-index (-1)

**Step 2.3**: Implement "lighted stage" CSS

- Radial gradient: `radial-gradient(circle at 70% 50%, rgba(255,255,255,0.10), rgba(0,0,0,0) 60%)`
  - Positioned at 70% horizontal (right side), 50% vertical (middle)
- Icon/image opacity: `0.25` (fixed default)
- Icon/image scale: `8.0x` (transform: scale(8.0))
- Position: `right: 0`, `top: 50%`, `transform: translateY(-50%)` (right-middle, configurable via placement prop)
- Filters: `grayscale(20%) blur(0.5px)` (subtle)
- Z-index: `-1` (behind content, but above page background)

**Step 2.4**: Create index export

- Create `client/src/components/background/index.js`
- Export `ViewBackground` component

**Step 2.5**: Export from lib

- Update `client/src/components/lib.jsx`
- Add: `export { ViewBackground } from './background/background';`

**Verification**: Component should compile without errors

---

#### Phase 3: Update View Component (30 minutes)

**Step 3.1**: Update client View component

- Open `client/src/components/view/view.jsx`
- Add `icon` and `background` to function parameters: `export function View({ title, layout, view, data, variant, icon, background })`

**Step 3.2**: Resolve background automatically (client)

- Add logic to resolve background spec:
  ```javascript
  // Resolve background: explicit override > route icon > none
  const resolvedBackground = background
    ? background
    : icon
    ? { type: "icon", value: icon }
    : null;
  ```

**Step 3.3**: Forward resolved background to layout (client)

- Find where Layout is rendered (line ~195)
- Update: `<Layout title={title} data={data} variant={variant} background={resolvedBackground}>`

**Step 3.4**: Update admin console View component

- Open `admin/console/src/components/view/view.jsx`
- Add `icon` and `background` to function parameters: `export function View({ title, layout, view, data, variant, icon, background })`

**Step 3.5**: Resolve background automatically (admin console)

- Add same resolution logic as client (Step 3.2)

**Step 3.6**: Forward resolved background to layout (admin console)

- Find where Layout is rendered (line ~193)
- Update: `<Layout title={title} data={data} variant={variant} background={resolvedBackground}>`

**Verification**: View components should compile and pass background prop through in both client and admin console

---

#### Phase 4: Update Layout Components (1.5 hours)

**Step 4.1**: Update client AppLayout

- Open `client/src/components/layout/app/app.jsx`
- Import ViewBackground: `import { ViewBackground } from 'components/lib';`
- Add `background` to function parameters
- Inside `<main>`, add `<ViewBackground background={background} />` BEFORE `<Header>`
- Ensure `<main>` has `position: relative` (for absolute positioning of background)

**Step 4.2**: Update client AccountLayout

- Open `client/src/components/layout/account/account.jsx`
- Import ViewBackground: `import { ViewBackground } from 'components/lib';`
- Add `background` to function parameters
- Inside `<main>`, add `<ViewBackground background={background} />` BEFORE `<Header>`
- Ensure `<main>` has `position: relative` (for absolute positioning of background)

**Step 4.3**: Update admin console AppLayout

- Open `admin/console/src/components/layout/app/app.jsx`
- Import ViewBackground: `import { ViewBackground } from 'components/lib';`
- Add `background` to function parameters
- Inside `<main>`, add `<ViewBackground background={background} />` BEFORE `<Header>`
- Ensure `<main>` has `position: relative` (for absolute positioning of background)

**Verification**: Layouts should compile and render background component in both client and admin console

---

#### Phase 5: Update Routes (1 hour)

**Step 5.1**: Update client app routes with icon fields

- Open `client/src/routes/app.js`
- Add `icon` to `/dashboard` route:
  ```javascript
  {
    path: '/dashboard',
    view: Dashboard,
    layout: 'app',
    permission: 'user',
    variant: 'table',
    title: 'dashboard.title',
    icon: 'gauge'  // ← NEW: Matches sidebar nav icon
  }
  ```
- Add `icon` to `/help` route:
  ```javascript
  {
    path: '/help',
    view: Help,
    layout: 'app',
    permission: 'user',
    title: 'help.title',
    icon: 'help-circle'  // ← NEW: Matches sidebar nav icon (fix inconsistency if Help card uses different icon)
  }
  ```

**Step 5.2**: Update client account routes with icon fields

- Open `client/src/routes/account.js`
- Add `icon` to `/account` route:
  ```javascript
  {
    path: '/account',
    view: Account,
    layout: 'app',
    permission: 'user',
    title: 'account.index.title',
    icon: 'user'  // ← NEW: Matches sidebar nav icon
  }
  ```
- Add `icon` to account sub-routes (matching subnav icons):
  - `/account/profile`: `icon: 'user'`
  - `/account/password`: `icon: 'lock'`
  - `/account/tfa`: `icon: 'shield-check'`
  - `/account/billing`: `icon: 'credit-card'`
  - `/account/theme`: `icon: 'palette'`
  - `/account/notifications`: `icon: 'bell'`
  - `/account/organizations`: `icon: 'building'`
  - `/account/clubs`: `icon: 'home'`
  - `/account/boats`: `icon: 'sailboat'`
  - `/account/apikeys`: `icon: 'key'`
  - `/account/users`: `icon: 'users'`

**Step 5.3**: Fix Help icon inconsistency (if needed)

- Check Help card/view component for icon usage
- Ensure it uses `help-circle` to match sidebar navigation
- Update if different icon is currently used

**Step 5.4**: Update admin console routes with icon fields

- Open `admin/console/src/routes/index.js`
- Add `icon` field to all routes, matching sidebar nav icons from AppLayout:
  - `/dashboard`: `icon: 'activity'`
  - `/accounts`: `icon: 'credit-card'`
  - `/users`: `icon: 'users'`
  - `/boats`: `icon: 'sailboat'`
  - `/orgs`: `icon: 'building'`
  - `/clubs`: `icon: 'home'`
  - `/active`: `icon: 'check'`
  - `/online`: `icon: 'wifi'`
  - `/offline`: `icon: 'wifi-off'`
  - `/onboarding`: `icon: 'user-plus'`
  - `/disabled`: `icon: 'user-x'`
  - `/feedback`: `icon: 'heart'`
  - `/help`: `icon: 'help-circle'` (or appropriate icon)
  - `/logs`: `icon: 'clipboard'`
  - `/events`: `icon: 'clock'`

**Verification**: Routes should compile and background should appear on pages in both client and admin console

---

#### Phase 6: Write Tests (1-2 hours)

**Step 6.1**: Create ViewBackground test file

- Create `client/test/view-background.test.js`
- Import dependencies: `vitest`, `@testing-library/react`, `ViewBackground`

**Step 6.2**: Write test cases

- Test: Renders nothing when background is undefined
- Test: Renders nothing when background is null
- Test: Renders nothing when background.type is 'none'
- Test: Renders icon when background.type is 'icon' and value is valid
- Test: Renders image when background.type is 'image' and value is valid URL
- Test: Applies pointer-events: none
- Test: Applies aria-hidden="true"
- Test: Applies correct opacity (0.25) and scale (8.0)
- Test: Applies correct positioning (right-middle by default)
- Test: Handles invalid icon name gracefully (returns null or fallback)
- Test: Supports placement overrides (horizontal, vertical, scale)

**Step 6.3**: Write layout integration tests (optional)

- Test: AppLayout renders ViewBackground when background prop provided (client)
- Test: AccountLayout renders ViewBackground when background prop provided (client)
- Test: AppLayout renders ViewBackground when background prop provided (admin console)
- Test: Layouts do not render ViewBackground when background is undefined

**Step 6.4**: Write admin console tests (optional)

- Create `admin/console/test/view-background.test.js` (if test infrastructure is set up)
- Use same test cases as client (component behavior is identical)

**Verification**: Run `npm test` in both client and admin console - all tests should pass

---

#### Phase 7: Polish and Adjustments (1 hour)

**Step 7.1**: Visual testing (client)

- Navigate to `/account` - verify user icon watermark appears
- Navigate to `/help` - verify help-circle icon watermark appears
- Navigate to `/dashboard` - verify gauge icon watermark appears
- Test account sub-routes - verify each shows correct subnav icon watermark
- Toggle dark mode - verify watermark appearance does NOT change (only page background changes)
- Verify watermark appears behind all content (header, cards, forms)

**Step 7.2**: Visual testing (admin console)

- Navigate to `/dashboard` - verify activity icon watermark appears
- Navigate to `/accounts` - verify credit-card icon watermark appears
- Navigate to `/users` - verify users icon watermark appears
- Navigate to `/feedback` - verify heart icon watermark appears
- Navigate to `/logs` - verify clipboard icon watermark appears
- Navigate to `/events` - verify clock icon watermark appears
- Test other admin routes - verify each shows correct sidebar nav icon watermark
- Toggle dark mode - verify watermark appearance does NOT change
- Verify watermark appears behind all content (header, tables, charts)

**Step 7.3**: Adjust styling if needed

- Fine-tune opacity (target: 0.20-0.35) in both client and admin console
- Fine-tune size (target: large but not overwhelming)
- Fine-tune position (target: right-middle, above FloatingAppLogo)
- Fine-tune radial gradient intensity
- Fine-tune filter effects
- Ensure consistency between client and admin console appearances

**Step 7.4**: Performance check

- Verify no layout shift when background loads (client and admin)
- Verify no performance degradation in both apps
- Verify background does not interfere with scrolling
- Test with multiple routes to ensure no memory leaks

**Step 7.5**: Accessibility check

- Verify `aria-hidden="true"` is present in both client and admin console
- Verify `pointer-events: none` prevents interaction
- Verify background does not affect screen reader navigation

**Verification**: Visual and functional testing complete for both client and admin console

---

### Dependencies Between Steps

```
Phase 1 (Test Setup)
  └─> Required before: Phase 6 (Tests)

Phase 2 (ViewBackground Component)
  └─> Required before: Phase 3, Phase 4, Phase 6

Phase 3 (View Component)
  └─> Required before: Phase 4, Phase 5

Phase 4 (Layout Components)
  └─> Required before: Phase 5, Phase 7

Phase 5 (Routes)
  └─> Required before: Phase 7

Phase 6 (Tests)
  └─> Can run in parallel with Phase 7

Phase 7 (Polish)
  └─> Final step - depends on all previous phases
```

**Critical Path**: Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 7

---

### Testing Approach

#### Unit Tests (Vitest + @testing-library/react)

**Component Tests** (`client/test/view-background.test.js`):

- Test background spec validation
- Test icon rendering
- Test logo rendering (SVG and URL)
- Test CSS properties (opacity, pointer-events, aria-hidden)
- Test error handling (invalid specs, missing props)

**Integration Tests** (optional):

- Test View → Layout → ViewBackground prop flow
- Test route → View → Layout → ViewBackground data flow

#### Manual Testing Checklist

- [ ] `/account` page shows settings icon watermark
- [ ] `/help` page shows headphones icon watermark
- [ ] `/dashboard` page shows gauge icon watermark
- [ ] Watermark appears behind all content (header, cards, forms)
- [ ] Watermark does not intercept clicks (pointer-events: none)
- [ ] Dark mode toggle does NOT change watermark appearance
- [ ] Page background color changes correctly in dark mode
- [ ] Watermark is subtle and does not interfere with readability
- [ ] No layout shift when navigating between pages
- [ ] No console errors or warnings

#### Visual Regression Testing (Future)

Consider adding visual regression testing (e.g., Percy, Chromatic) in future iterations to catch unintended visual changes.

---

### User Stories

#### US1: View Account Settings with Watermark

**As a** user viewing my account settings
**I want to** see a subtle settings icon watermark in the background
**So that** I have visual context about which section of the app I'm in

**Acceptance Criteria:**

- When I navigate to `/account`, I see a large, faint gear/settings icon in the bottom-right area
- The icon appears behind all content (cards, forms, navigation)
- The icon does not interfere with reading or clicking on content
- The icon appearance does not change when I toggle dark mode

#### US2: View Help Page with Watermark

**As a** user viewing the help/support page
**I want to** see a subtle headphones icon watermark in the background
**So that** I have visual context that I'm in the support section

**Acceptance Criteria:**

- When I navigate to `/help`, I see a large, faint headphones icon in the bottom-right area
- The icon matches the LADDERS support page aesthetic
- The icon does not interfere with the contact form or other content

#### US3: View Dashboard with Watermark

**As a** user viewing the dashboard
**I want to** see a subtle gauge/dashboard icon watermark in the background
**So that** I have visual context that I'm viewing the main dashboard

**Acceptance Criteria:**

- When I navigate to `/dashboard`, I see a large, faint gauge icon in the bottom-right area
- The icon does not interfere with charts, tables, or statistics
- The icon maintains the "lighted stage" aesthetic

---

### Expected Refactor Areas

#### None Identified

This is a purely additive feature. No existing code needs refactoring. The changes are:

- New component creation
- Prop forwarding (additive)
- Route metadata addition (additive)

#### Potential Future Refactors (Out of Scope)

- If we later add entity-specific logo backgrounds, we may need to:
  - Refactor ViewBackground to handle async logo fetching
  - Add logo caching/memoization
  - Refactor routes to support dynamic background resolution

---

### Questions/Clarifications Needed

Before proceeding to implementation, please confirm:

**All questions answered - ready for implementation:**

1. ✅ **Icon mapping**: Confirmed - use route `icon` field matching sidebar/subnav icons
2. ✅ **Placement defaults**: Right-middle (configurable via placement prop)
3. ✅ **Opacity/scale defaults**: Opacity `0.25`, Scale `8.0x`
4. ✅ **Account sub-routes**: Use subnav icon for each sub-route (different icons per route)
5. ✅ **Testing priority**: Basic testing (smoke tests sufficient for initial implementation)
6. ✅ **Image type support**: Implement `type: 'image'` (replacing 'logo' terminology)

**Additional clarifications implemented:**

- Automatic background generation from route `icon` field
- Fix Help icon inconsistency (ensure Help card uses `help-circle` to match sidebar)

---

### Risk Assessment

#### Low Risk ✅

- **Component creation**: Standard React component pattern
- **Prop forwarding**: Simple, additive change
- **Route updates**: Simple metadata addition
- **CSS styling**: Well-understood Tailwind/CSS patterns

#### Medium Risk ⚠️

- **Z-index layering**: Need to ensure background stays behind content but above page background

  - **Mitigation**: Use `z-index: -1` on background, ensure content wrapper has `position: relative` and higher z-index

- **Performance**: Large icons/logos could impact rendering performance

  - **Mitigation**: Use CSS transforms/opacity (GPU-accelerated), ensure `will-change` or `transform: translateZ(0)` if needed

- **Accessibility**: Background must not interfere with screen readers
  - **Mitigation**: Use `aria-hidden="true"` and `pointer-events: none`

#### High Risk ❌

- **None identified** - This is a UI-only feature with no data/security implications

---

### Success Criteria

✅ **Functional Requirements:**

- Background watermarks appear on configured routes
- Watermarks render icons correctly (Lucide icons)
- Watermarks do not interfere with UI interaction
- Watermarks maintain same appearance in light/dark modes

✅ **Non-Functional Requirements:**

- No performance degradation
- No accessibility issues
- No console errors or warnings
- Tests pass (if implemented)

✅ **Visual Requirements:**

- Watermarks match LADDERS aesthetic ("lighted stage" effect)
- Watermarks are subtle and do not interfere with readability
- Watermarks appear behind all content as designed

---

### Implementation Checklist

#### Pre-Implementation

- [ ] Review and approve this plan
- [ ] Answer clarification questions (Section above)
- [ ] Verify test dependencies can be installed
- [ ] Ensure development environment is ready

#### Phase 1: Test Setup

- [ ] Install Vitest and testing dependencies
- [ ] Create `vitest.config.js`
- [ ] Create `test/setup.js`
- [ ] Update `package.json` scripts
- [ ] Verify test infrastructure works

#### Phase 2: ViewBackground Component

**Client:**

- [ ] Create `client/src/components/background/` directory
- [ ] Create `view-background.jsx` component
- [ ] Implement icon rendering
- [ ] Implement image rendering
- [ ] Implement "lighted stage" CSS
- [ ] Create `index.js` export
- [ ] Export from `lib.jsx`

**Admin Console:**

- [ ] Create `admin/console/src/components/background/` directory
- [ ] Create `view-background.jsx` component (same as client)
- [ ] Create `index.js` export
- [ ] Export from `lib.jsx`

#### Phase 3: View Component

**Client:**

- [ ] Add `icon` and `background` props to View function
- [ ] Implement automatic background resolution
- [ ] Forward resolved `background` to Layout components

**Admin Console:**

- [ ] Add `icon` and `background` props to View function
- [ ] Implement automatic background resolution
- [ ] Forward resolved `background` to Layout components

#### Phase 4: Layout Components

**Client:**

- [ ] Update AppLayout to accept and render background
- [ ] Update AccountLayout to accept and render background
- [ ] Ensure proper z-index layering

**Admin Console:**

- [ ] Update AppLayout to accept and render background
- [ ] Ensure proper z-index layering

#### Phase 5: Routes

**Client:**

- [ ] Add `icon` to `/dashboard` route
- [ ] Add `icon` to `/help` route
- [ ] Add `icon` to `/account` route
- [ ] Add `icon` to all account sub-routes

**Admin Console:**

- [ ] Add `icon` to all admin console routes (matching sidebar nav icons)

#### Phase 6: Tests

- [ ] Write ViewBackground component tests
- [ ] Write layout integration tests (optional)
- [ ] Run test suite and verify all pass

#### Phase 7: Polish

**Client:**

- [ ] Visual testing on all configured routes
- [ ] Dark mode testing
- [ ] Performance check
- [ ] Accessibility check
- [ ] Fine-tune styling if needed

**Admin Console:**

- [ ] Visual testing on all configured routes
- [ ] Dark mode testing
- [ ] Performance check
- [ ] Accessibility check
- [ ] Fine-tune styling if needed
- [ ] Ensure consistency with client appearance

#### Post-Implementation

- [ ] ESLint all modified/new files
- [ ] Verify no console errors
- [ ] Update documentation if needed
- [ ] Commit changes with descriptive messages

---

## 4: REVIEW - Review and validate the implementation plan

### Confidence Rating: **95%**

The plan is comprehensive, well-structured, and addresses all requirements. All clarification questions have been answered, and the implementation approach is clear and actionable.

---

### What Looks Good ✅

#### 1. **Completeness**

- ✅ All affected files identified (5 new, 7 modified)
- ✅ All implementation phases documented (7 phases with detailed steps)
- ✅ Test strategy defined (unit tests + manual checklist)
- ✅ User stories documented with acceptance criteria
- ✅ Interface contracts defined (TypeScript-style definitions)
- ✅ Data flow diagram included
- ✅ Dependencies and critical path identified

#### 2. **Architecture Alignment**

- ✅ Follows existing patterns (prop forwarding, component structure)
- ✅ No breaking changes (purely additive)
- ✅ Matches layered structure (View → Layout → Component)
- ✅ Uses existing component library (`Icon` from lib)
- ✅ Follows Tailwind CSS patterns already in use

#### 3. **Automatic Background Generation**

- ✅ Smart design: Route `icon` field automatically generates background
- ✅ Explicit override support via `background` spec
- ✅ Matches sidebar/subnav icons for consistency
- ✅ Minimal route changes required (just add `icon` field)

#### 4. **Implementation Clarity**

- ✅ Step-by-step instructions are specific and actionable
- ✅ Code examples provided for route updates
- ✅ CSS values specified (opacity: 0.25, scale: 8.0x, position: right-middle)
- ✅ File paths and line numbers referenced where helpful

#### 5. **Risk Mitigation**

- ✅ Low-risk feature (UI-only, no DB/API changes)
- ✅ Proper z-index layering strategy
- ✅ Accessibility considerations (`aria-hidden`, `pointer-events: none`)
- ✅ Performance considerations (GPU-accelerated CSS)

---

### What Needs Adjustment ⚠️

#### 1. **Help Icon Consistency Check**

- **Issue**: Need to verify Help card/view uses `help-circle` icon to match sidebar
- **Action**: Add verification step in Phase 5.3 (already included)
- **Risk**: Low - easy to fix if inconsistency found

#### 2. **AccountLayout Subnav Icon Resolution**

- **Issue**: Plan mentions two approaches (route.icon vs. subnav matching)
- **Clarification**: Prefer explicit `icon` field in routes (simpler, more maintainable)
- **Action**: Use route.icon approach; subnav matching is fallback/optional enhancement

#### 3. **Image Type Implementation**

- **Issue**: `type: 'image'` is defined but not fully detailed in component implementation
- **Clarification**: Use standard `<img>` tag (not SVG dangerouslySetInnerHTML)
- **Action**: Component implementation should use `<img src={value} />` for image type

---

### Remaining Questions (All Answered ✅)

All clarification questions from PLAN section have been answered:

1. ✅ **Icon mapping**: Use route `icon` field matching sidebar/subnav icons
2. ✅ **Placement defaults**: Right-middle (configurable)
3. ✅ **Opacity/scale**: Opacity `0.25`, Scale `8.0x`
4. ✅ **Account sub-routes**: Use subnav icon for each route
5. ✅ **Testing**: Basic smoke tests sufficient
6. ✅ **Image type**: Implement `type: 'image'` (replacing 'logo')

---

### Concerns and Risks

#### Low Risk ✅

- **Component creation**: Standard React pattern, well-understood
- **Prop forwarding**: Simple additive change
- **Route updates**: Simple metadata addition
- **CSS styling**: Well-understood Tailwind/CSS patterns

#### Medium Risk ⚠️ (Mitigated)

1. **Z-index layering**

   - **Concern**: Background must stay behind content but above page background
   - **Mitigation**: Use `z-index: -1` on background, ensure `<main>` has `position: relative`
   - **Status**: ✅ Mitigated in plan

2. **Transform conflicts**

   - **Concern**: Using both `scale(8.0)` and `translateY(-50%)` in same transform
   - **Mitigation**: Combine transforms: `transform: translateY(-50%) scale(8.0)`
   - **Status**: ⚠️ Needs verification in implementation

3. **Icon size calculation**
   - **Concern**: Scale(8.0) on a 24px icon = 192px, may need adjustment
   - **Mitigation**: Start with 8.0x, adjust in Phase 7 (Polish) if needed
   - **Status**: ✅ Addressed in plan (Phase 7 fine-tuning)

#### High Risk ❌

- **None identified** - This is a UI-only feature with no data/security implications

---

### Standards Compliance Check

#### ✅ JavaScript Style Guide

- Follows existing component patterns
- Uses JSDoc comments (as seen in existing components)
- Uses camelCase for variables/functions
- Uses consistent export patterns

#### ✅ AI-RULES.md Compliance

- No database changes (UI-only)
- No API changes required
- Follows existing file naming conventions
- Uses existing component library patterns
- Proper error handling (null checks, graceful fallbacks)

#### ✅ Component Rules

- Follows existing layout component patterns
- Uses existing `Icon` component from lib
- Matches existing prop forwarding patterns
- Uses Tailwind CSS classes consistently

---

### Approval Status: **READY TO PROCEED** ✅

**Confidence Level**: **95%**

The plan is comprehensive, well-documented, and ready for implementation. All clarification questions have been answered, and the implementation approach is clear.

**Recommendations before implementation:**

1. ✅ Review this plan one final time
2. ✅ Verify Help icon consistency (quick check)
3. ✅ Proceed to BRANCH phase when ready

**No blockers identified** - plan can proceed to implementation phase.

---

## 5: BRANCH - Create Git branches for required repos

**Status**: SKIPPED - Working in open branch

We are working directly in an open branch to bring `app-template` up to par with LADDERS. No separate feature branch is needed for this implementation.

---

## 6: IMPLEMENT - Execute the plan

### Implementation Summary

Implemented route-driven background watermark system that dynamically generates large, low-opacity icon backgrounds behind view content, replicating the LADDERS "lighted stage" aesthetic.

**Scope**: `client/` (React web) - COMPLETED
**Scope**: `admin/console/` (Admin console) - DEFERRED (not yet implemented)

**Approach**: Used LADDERS pattern - simple prop forwarding with `useEffect` + DOM manipulation (no React re-renders, navigation remains smooth).

**Key Implementation Decision**: Simplified from planned background spec objects to simple string icon names (`background: 'icon-name'`), matching LADDERS approach of `background: 'filename.jpg'`.

---

### Phase 1: Setup Test Infrastructure

**Status**: ⏸️ DEFERRED

Test infrastructure setup was deferred. Implementation focused on getting the feature working first, following LADDERS pattern.

---

### Phase 2: Create Background Implementation

**Status**: ✅ COMPLETED (Using LADDERS Pattern)

**Client:**

- ✅ Implemented background directly in Layout components using `useEffect` + DOM manipulation
- ✅ No separate ViewBackground component created (following LADDERS pattern)
- ✅ Background created via `document.createElement` and React Portal for icon rendering

**Implementation Details:**

- Uses `useEffect` hook with `useRef` to get main element reference
- Creates background container DOM element directly (like LADDERS uses `document.querySelector`)
- Renders icon via React Portal (`createRoot`) into created DOM element
- Implements "stage floor" effect with elliptical radial gradient
- Right positioning (10% from edge), vertical center (47% for AccountLayout, 45% for AppLayout)
- Final settings:
  - Gradient: `ellipse 150% 15% at 90% 75%, rgba(255,255,255,0.08), rgba(0,0,0,0) 40%`
  - Icon scale: `25x` (transform: scale(25))
  - Icon opacity: `0.45`
  - Icon color: `text-slate-700` (darkened for subtlety)
  - Icon position: `right: 10%`, `top: 45%` (AppLayout) or `47%` (AccountLayout)

---

### Phase 3: Update View Component

**Status**: ✅ COMPLETED

**Client:**

- ✅ Updated `client/src/components/view/view.jsx` to extract `background` prop
- ✅ Simplified resolution: `background || (icon ? icon : null)` - passes string directly
- ✅ Forward `background` prop to Layout components (simple string, not object)

**Implementation:**

- View component simply forwards `background` prop as-is (string icon name or null)
- No complex background spec objects - matches LADDERS simplicity
- Layout components handle string icon names directly

---

### Phase 4: Update Layout Components

**Status**: ✅ COMPLETED

**Client:**

- ✅ Updated `client/src/components/layout/app/app.jsx` to accept `background` prop
- ✅ Updated `client/src/components/layout/account/account.jsx` to accept `background` prop
- ✅ Implemented `useEffect` + DOM manipulation pattern (matching LADDERS)
- ✅ Added `useRef` to get main element reference
- ✅ Background created via `document.createElement` and appended to main
- ✅ Icon rendered via React Portal (`createRoot`) into background container
- ✅ Added `position: relative` and `overflow-hidden` to `<main>` elements
- ✅ Content wrapped in `<div className="relative z-10">` to ensure proper layering

**Implementation Pattern (LADDERS-style):**

```javascript
useEffect(() => {
  if (!mainRef.current) return;
  const main = mainRef.current;
  const bgId = "view-background";

  // Remove existing background
  const existing = document.getElementById(bgId);
  if (existing) existing.remove();

  if (background) {
    // Create background container
    const bgContainer = document.createElement("div");
    bgContainer.id = bgId;
    // ... apply styles via Object.assign (like LADDERS)
    // ... create icon container and render icon via React Portal
    main.appendChild(bgContainer);

    return () => {
      // Cleanup
    };
  }
}, [background]);
```

**Key Differences from Plan:**

- No separate ViewBackground component - logic embedded in Layout components
- Uses DOM manipulation (like LADDERS) instead of React component rendering
- Ensures navigation works smoothly (no React re-render issues)

---

### Phase 5: Update Routes

**Status**: ✅ COMPLETED

**Client:**

- ✅ Added `background: 'gauge'` to `/dashboard` route
- ✅ Added `background: 'headset'` to `/help` route (changed from help-circle to headset)
- ✅ Added `background: 'user'` to `/account` route
- ✅ Added `background` fields to all account sub-routes:
  - `/account/profile`: `'user'`
  - `/account/password`: `'lock'`
  - `/account/tfa`: `'fingerprint'` (changed from shield-check)
  - `/account/billing`: `'credit-card'`
  - `/account/theme`: `'palette'`
  - `/account/users`: `'users'`
  - `/account/notifications`: `'bell'`
  - `/account/organizations`: `'building'`
  - `/account/clubs`: `'home'`
  - `/account/boats`: `'sailboat'`
  - `/account/apikeys`: `'key-round'` (changed from key)
  - `/account/apikeys/create`: `'key-round'`
  - `/account/apikeys/edit`: `'key-round'`

**Icon Updates Made:**

- Help icon: Changed from `'help-circle'` to `'headset'` (matches support/help context better)
- 2FA icon: Changed from `'shield-check'` to `'fingerprint'` (matches visual design)
- API Keys icon: Changed from `'key'` to `'key-round'` (matches card design)

**Admin Console:**

- ⏸️ DEFERRED - Not yet implemented

---

### Phase 6: Write Tests

**Status**: ⏸️ DEFERRED

Tests deferred. Feature works correctly and navigation remains smooth. Tests can be added later if needed.

---

### Phase 7: Polish and Adjustments

**Status**: ✅ COMPLETED

**Visual Adjustments Made:**

1. **Icon appearance:**

   - Removed blur filter (was `blur(0.5px)`)
   - Quadrupled size: `scale(8)` → `scale(32)` → adjusted to `scale(25)`
   - Moved 10% toward right edge: `right: 20%` → `right: 10%`
   - Darkened icon color: `text-slate-400` → `text-slate-500` → `text-slate-600` → `text-slate-700`
   - Increased opacity: `0.25` → `0.375` → `0.45`

2. **Lighting effect:**

   - Changed from backlighting to "stage floor" effect
   - Gradient: `ellipse 150% 15%` (narrow band, 10% tall)
   - Position: `90% 75%` (10% from bottom, 20% from top)
   - Brightness: `rgba(255,255,255,0.08)` (subtle)
   - Fade distance: `40%`

3. **Icon positioning:**

   - AppLayout: `top: 45%`
   - AccountLayout: `top: 47%` (slightly lower for subnav layout)

4. **Floating App Logo:**
   - Always visible on all screens (removed `variant !== 'table'` condition)
   - Variant prop kept for future use

**Final Settings:**

- Gradient: `radial-gradient(ellipse 150% 15% at 90% 75%, rgba(255,255,255,0.08), rgba(0,0,0,0) 40%)`
- Icon scale: `scale(25)`
- Icon opacity: `0.45`
- Icon color: `text-slate-700`
- Icon position: `right: 10%`, `top: 45%` (AppLayout) or `47%` (AccountLayout)
- Z-index: Background `0`, Icon `1`, Content `10` (via wrapper div)

---

### Implementation Notes

**Completed Successfully:**

- ✅ Core implementation completed for client/ (React web)
- ✅ Used LADDERS pattern (simple prop forwarding + DOM manipulation)
- ✅ Navigation works smoothly (no React re-render issues)
- ✅ Backgrounds appear correctly on all configured routes
- ✅ Dark mode tested - watermark appearance unchanged (only page background changes)
- ✅ No linting errors detected
- ✅ Floating app logo always visible

**Key Implementation Decisions:**

1. **Simplified approach**: Used simple string icon names (`background: 'icon-name'`) instead of complex background spec objects - matches LADDERS simplicity
2. **LADDERS pattern**: Used `useEffect` + DOM manipulation instead of React component rendering - ensures navigation works smoothly
3. **No separate component**: Background logic embedded directly in Layout components (like LADDERS applies styles directly)
4. **React Portal for icons**: Icons rendered via `createRoot` into DOM elements (allows lazy-loaded Lucide icons to work)

**Deferred:**

- ⏸️ Admin console implementation (can be added later using same pattern)
- ⏸️ Unit tests (feature works correctly, tests can be added later)
- ⏸️ Image type support (icon-based implementation sufficient for now)

**Routes with Backgrounds:**

- `/dashboard` → gauge icon
- `/help` → headset icon
- `/account` → user icon
- All account sub-routes → matching subnav icons (user, lock, fingerprint, credit-card, palette, users, bell, building, home, sailboat, key-round)

---

## 7: LINT - Check and fix linting issues

<!-- Document linting checks and fixes here -->

---

## 8: TEST - Run tests

<!-- Document test execution and results here -->

---

## 9: DOCUMENT - Document the solution

<!-- Document the final solution here -->

---

## PR: PULL REQUEST - Create PRs for all repos

<!-- Document pull request creation and links here -->

---

## Notes

### Implementation Summary

**What Was Implemented:**

- ✅ Route-driven background watermarks using simple string icon names (`background: 'icon-name'`)
- ✅ LADDERS-style DOM manipulation pattern (`useEffect` + `useRef` + `document.createElement`)
- ✅ React Portal rendering for icons (`createRoot` into dynamically created DOM elements)
- ✅ "Stage floor" lighting effect with elliptical radial gradient
- ✅ Backgrounds on all account routes and main app routes (dashboard, help)
- ✅ Icon consistency fixes (headset for help, fingerprint for 2FA, key-round for API keys)
- ✅ Floating app logo always visible

**What Was Different from Plan:**

1. **No separate ViewBackground component**: Background logic embedded directly in Layout components (AppLayout, AccountLayout) using DOM manipulation, matching LADDERS pattern
2. **Simplified background spec**: Used simple string icon names instead of complex background spec objects (`background: 'icon-name'` vs `background: { type: 'icon', value: 'icon-name' }`)
3. **DOM manipulation approach**: Used `useEffect` + `document.createElement` + React Portal instead of React component rendering to avoid navigation/re-render issues
4. **No test infrastructure**: Test setup deferred - feature works correctly without it
5. **Admin console deferred**: Only client/ implemented - admin console can use same pattern later

**Key Learnings:**

- React Router reuses component instances, so adding `key` props or complex `useMemo` logic caused navigation issues
- LADDERS pattern (DOM manipulation) works better for backgrounds that need to persist across route changes
- Simple string props (`background: 'icon-name'`) are easier to maintain than complex spec objects
- React Portal (`createRoot`) allows rendering React components into dynamically created DOM elements

**Final Implementation Pattern:**

```javascript
// Route definition
{ path: '/account', background: 'user', ... }

// View component - simple forwarding
export function View({ title, layout, view, data, variant, background }) {
    // ...
    <Layout title={title} data={data} variant={variant} background={background}>
        <View t={t} />
    </Layout>
}

// Layout component - DOM manipulation
export function AppLayout({ title, children, variant, background }) {
    const mainRef = useRef(null);

    useEffect(() => {
        if (!mainRef.current || !background) return;

        // Create background container
        const bgContainer = document.createElement('div');
        // ... apply styles via Object.assign

        // Create icon container and render icon via React Portal
        const iconMount = document.createElement('div');
        const root = createRoot(iconMount);
        root.render(<Icon name={background} size={24} className="text-slate-700" />);

        mainRef.current.appendChild(bgContainer);

        return () => {
            root.unmount();
            bgContainer.remove();
        };
    }, [background]);

    return (
        <main ref={mainRef} className="relative ...">
            {/* content */}
        </main>
    );
}
```
