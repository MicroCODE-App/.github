# Implementation Plan: Replace SV Management with Direct Boat Management

## Executive Summary

This plan outlines the migration from a **Sailing Vessel (SV)**-based management system to a **direct Boat management** system, aligning Boat management with the existing Organizations and Clubs patterns. The SV entity will be removed from user-facing UI, and users will manage Boats directly through their user profile, exactly like they manage Organizations and Clubs.

### Key Changes

- **Remove**: SV creation/management UI from user-facing interface
- **Remove**: `GET /api/user/svs` endpoint (SV endpoints remain for internal use)
- **Add**: Direct Boat management UI matching Organizations/Clubs pattern
- **Add**: `boat_ids` field to User schema (alongside existing `sv_ids`)
- **Preserve**: All SV endpoints (`/api/sv/*`) for future internal use
- **Preserve**: `sv_ids` and `sv_keys` in User model schema for internal use
- **Preserve**: SV translation files
- **No Migration**: Clean database import will handle data setup
- **Out of Scope**: Boat editing and image uploads (handled separately, not part of this implementation)

---

## Table of Contents

1. [Current State Analysis](#current-state-analysis)
2. [Target State Design](#target-state-design)
3. [Architecture Overview](#architecture-overview)
4. [Data Migration Strategy](#data-migration-strategy)
5. [API Contract Changes](#api-contract-changes)
6. [Frontend Implementation](#frontend-implementation)
7. [Backend Implementation](#backend-implementation)
8. [Database Schema Changes](#database-schema-changes)
9. [User Stories](#user-stories)
10. [Data Flow Diagrams](#data-flow-diagrams)
11. [Affected Files & Modules](#affected-files--modules)
12. [Implementation Phases](#implementation-phases)
13. [Questions for Clarification](#questions-for-clarification)
14. [Risk Assessment](#risk-assessment)
15. [Testing Strategy](#testing-strategy)

---

## Current State Analysis

### Current Architecture

#### User Entity Relationships

```
User
├── org_ids: Array<string>        // Organization IDs user belongs to
├── club_ids: Array<string>       // Club IDs user belongs to
├── sv_ids: Array<string>         // Sailing Vessel IDs user owns/is associated with
└── boat_ids: ❌ NOT PRESENT      // Boat IDs - does not exist
```

#### SV Entity Structure

```
SV (Sailing Vessel)
├── id: string
├── boat_id: string               // Links to Boat
├── boat_key: string
├── name: string                  // Usually "SV {boat.name}"
├── user_ids: {                   // Owners/crew associations
│   ├── owners: Array<string>
│   └── crew: Array<string>
│   }
├── certs: Object                 // Certificates
└── description: string
```

#### Boat Entity Structure

```
Boat
├── id: string
├── name: string
├── sail_no: string
├── sail_cc: string
├── hin: string
├── boat_design_id: string
├── boat_builder_id: string
└── description: string
```

### Current User Flow (SV Management)

1. User navigates to `/account/svs`
2. User searches for boats
3. User selects boats
4. User clicks "Add Selected" → Creates SV records
5. System handles duplicates with modal (clone/new/cancel)
6. SV records link user to boats via `sv_ids` array
7. EntityCard displays SV information with boat details

### Current API Endpoints

**SV Endpoints (PRESERVED FOR INTERNAL USE):**

- `POST /api/sv` - Create SV ✅ KEEP
- `GET /api/sv` - List SVs ✅ KEEP
- `GET /api/sv/:id` - Get SV by ID ✅ KEEP
- `GET /api/sv/:id/owners` - Get SV owners ✅ KEEP
- `GET /api/sv/by-boat` - Get SVs for boat ✅ KEEP
- `PATCH /api/sv/:id` - Update SV ✅ KEEP
- `DELETE /api/sv/:id` - Delete SV ✅ KEEP
- `GET /api/user/svs` - Get user's SVs ❌ REMOVE (only this endpoint)

**Boat Endpoints (EXISTING):**

- `GET /api/boat` - List boats (with search)

**User Endpoints (TO BE MODIFIED):**

- `PATCH /api/user` - Update user (adds `boat_ids`, keeps `sv_ids` for internal use)
- `GET /api/user` - Get user (returns `boat_ids`, keeps `sv_ids` in response)

### Current Frontend Components

**SV Management:**

- `client/src/views/account/svs.jsx` - Main SV management view (TO BE REPLACED)
- Uses complex duplicate handling, modal dialogs, parallel creation
- References `user.data.sv_ids`

**Entity Display:**

- `client/src/components/entitycard/entitycard.jsx` - Displays SV with boat info
- `client/src/components/entitycard/entitycard.utils.js` - SV formatting utilities

**Navigation:**

- `client/src/routes/account.js` - Route `/account/svs` (TO BE CHANGED to `/account/boats`)
- `client/src/components/layout/account/account.jsx` - Navigation menu (TO BE UPDATED)
- `client/src/views/account/index.jsx` - Account index page (TO BE UPDATED)

---

## Target State Design

### Target Architecture

#### User Entity Relationships (After Migration)

```
User
├── org_ids: Array<string>        // Organization IDs user belongs to
├── club_ids: Array<string>       // Club IDs user belongs to
├── boat_ids: Array<string>       // Boat IDs user owns/is associated with ✨ NEW
└── sv_ids: ✅ KEEP                // Preserved for internal use (not user-facing)
```

#### Boat Management Flow (Target)

```
User Flow:
1. Navigate to /account/boats
2. Search for boats (same as clubs/orgs)
3. Select boats from search results
4. Click "Add Selected" → Updates user.boat_ids array
5. Remove boats → Removes from user.boat_ids array
6. EntityCard displays boat information directly
```

### Target API Endpoints

**Boat Endpoints (ENHANCED):**

- `GET /api/boat` - List boats (with search) ✅ EXISTS
- No creation endpoint needed (boats created via entity_request or admin)

**User Endpoints (MODIFIED):**

- `PATCH /api/user` - Update user (accepts `boat_ids` array)
- `GET /api/user` - Get user (returns `boat_ids` array)

**SV Endpoints (REMOVED/DEPRECATED):**

- All `/api/sv/*` endpoints removed or deprecated
- `GET /api/user/svs` removed or deprecated

---

## Architecture Overview

### Pattern Consistency

The Boat management will follow the **exact same pattern** as Organizations and Clubs:

#### Organizations Pattern

```
1. GET /api/org?search=... → List organizations
2. User selects orgs → Updates user.org_ids via PATCH /api/user
3. EntityCard displays org with logo, contact info
```

#### Clubs Pattern

```
1. GET /api/club?search=... → List clubs
2. User selects clubs → Updates user.club_ids via PATCH /api/user
3. EntityCard displays club with logo, contact info
```

#### Boats Pattern (Target)

```
1. GET /api/boat?search=... → List boats ✅ EXISTS
2. User selects boats → Updates user.boat_ids via PATCH /api/user ✨ NEW
3. EntityCard displays boat with sail info, brand, model, builder ✨ NEW
```

### Component Reuse

The new `boats.jsx` component will be **nearly identical** to `clubs.jsx` and `organizations.jsx`:

- Same Popover-based selection UI
- Same search functionality
- Same add/remove pattern
- Same EntityCard display
- Same "Request New" entity request flow

---

## Data Migration Strategy

### Migration Approach

**NO MIGRATION REQUIRED** - Clean database import will handle data setup.

- User will alter data import process to create clean database matching new plan
- No migration scripts needed
- `boat_ids` will be populated directly during data import
- `sv_ids` will remain in User schema for internal use (not user-facing)

---

## API Contract Changes

### 1. User Update Endpoint (MODIFIED)

**Current:**

```typescript
PATCH /api/user
{
    org_ids?: string[];
    club_ids?: string[];
    sv_ids?: string[];  // ❌ TO BE REMOVED
}
```

**Target:**

```typescript
PATCH /api/user
{
    org_ids?: string[];
    club_ids?: string[];
    boat_ids?: string[];  // ✨ NEW
    sv_ids?: string[];    // ✅ KEEP (for internal use, not user-facing)
}
```

### 2. User Get Endpoint (MODIFIED)

**Current:**

```typescript
GET /api/user
Response: {
    data: {
        id: string;
        name: string;
        org_ids: string[];
        club_ids: string[];
        sv_ids: string[];  // ❌ TO BE REMOVED
    }
}
```

**Target:**

```typescript
GET /api/user
Response: {
    data: {
        id: string;
        name: string;
        org_ids: string[];
        club_ids: string[];
        boat_ids: string[];  // ✨ NEW
        sv_ids: string[];     // ✅ KEEP (for internal use, returned but not used in UI)
    }
}
```

### 3. Boat List Endpoint (ENHANCED - Already Exists)

**Current:**

```typescript
GET /api/boat?search=...
Response: {
    data: Array<{
        id: string;
        name: string;
        sail_no: string;
        sail_cc: string;
        hin: string;
    }>
}
```

**Target:**

```typescript
GET /api/boat?search=...
Response: {
    data: Array<{
        id: string;
        name: string;
        sail_no: string;
        sail_cc: string;
        hin: string;
        boat_design_id?: string;      // ✨ ENHANCE: Include for EntityCard
        boat_builder_id?: string;     // ✨ ENHANCE: Include for EntityCard
        // Populated fields for EntityCard:
        brand?: { name: string };     // ✨ ENHANCE: Populate brand
        model?: { name: string };     // ✨ ENHANCE: Populate model (design)
        builder?: { name: string };   // ✨ ENHANCE: Populate builder
    }>
}
```

**Note:** Boat controller may need enhancement to populate brand/model/builder relationships for EntityCard display.

### 4. SV Endpoints (REMOVED/DEPRECATED)

**Endpoints to Remove:**

- `POST /api/sv` ❌
- `GET /api/sv` ❌
- `GET /api/sv/:id` ❌
- `GET /api/sv/:id/owners` ❌
- `GET /api/sv/by-boat` ❌
- `PATCH /api/sv/:id` ❌
- `DELETE /api/sv/:id` ❌
- `GET /api/user/svs` ❌

**Deprecation Strategy:**

- Option 1: Remove immediately (breaking change)
- Option 2: Return 410 Gone with deprecation message
- Option 3: Keep but log deprecation warnings

---

## Frontend Implementation

### 1. New Component: `client/src/views/account/boats.jsx`

**Structure:** Copy from `clubs.jsx` and adapt for boats

**Key Differences from Clubs:**

- Search by `name`, `sail_no`, `sail_cc` (already in boat.controller.js)
- Display sail info in selection list
- EntityCard shows boat-specific fields (sail, brand, model, builder)
- No acronym field (boats don't have acronyms)

**Key Similarities:**

- Same Popover-based selection UI
- Same add/remove pattern
- Same "Request New" entity request flow
- Same EntityCard display pattern

**Component Structure:**

```javascript
export function Boats({ t: propT }) {
    // State (same as clubs.jsx)
    const [selectedBoatIds, setSelectedBoatIds] = useState([]);
    const [selectedBoats, setSelectedBoats] = useState([]);
    const [boats, setBoats] = useState([]);
    const [searchTerm, setSearchTerm] = useState('');
    const [loading, setLoading] = useState(false);
    const [connectedBoats, setConnectedBoats] = useState([]);

    // User data
    const user = useAPI('/api/user', 'get', refreshTrigger);
    const currentBoatIds = user?.data?.boat_ids || [];

    // Fetch boats list (GET /api/boat)
    useEffect(() => {
        // Fetch boats with search
    }, [searchTerm]);

    // Fetch connected boats for EntityCard display
    useEffect(() => {
        // Fetch boats where id in currentBoatIds
    }, [currentBoatIds]);

    // Handle add selected boats
    const handleAddSelected = async () => {
        // PATCH /api/user with boat_ids
    };

    // Handle remove boat
    const handleRemove = async (boatId) => {
        // PATCH /api/user with updated boat_ids
    };

    // Handle request new boat
    const handleRequestNew = () => {
        // POST /api/entity_request with entity_type: 'boat'
    };

    // Render (same structure as clubs.jsx)
    return (
        // Popover with search
        // Selected boats list
        // EntityCard display
    );
}
```

### 2. Update EntityCard Component

**File:** `client/src/components/entitycard/entitycard.jsx`

**Changes:**

- Add `'boat'` as valid `entityType`
- Keep `'sailing-vessel'` entityType (for internal use, but not used in new boats.jsx UI)
- Add boat-specific display logic (sail info, brand, model, builder)
- Remove SV-specific logic (owners display)

**Updated EntityType Handling:**

```javascript
const isBoat = entityType === "boat";
const isSailingVessel = entityType === "sailing-vessel"; // ⚠️ DEPRECATED

// Boat display fields:
if (isBoat) {
  // Show: sail_no, sail_cc, brand, model, builder
  // Don't show: address, phone, email (boats don't have these)
  // Don't show: owners (boats don't have owners array)
}
```

### 3. Update EntityCard Utils

**File:** `client/src/components/entitycard/entitycard.utils.js`

**Changes:**

- Update `formatEntityHeader` to handle `'boat'` type
- Keep `formatOwners` function (may be needed for internal SV use)
- Add boat-specific formatting helpers if needed

### 4. Update Routes

**File:** `client/src/routes/account.js`

**Changes:**

```javascript
// Remove:
import { SVs } from 'views/account/svs';
{
    path: '/account/svs',
    view: SVs,
    ...
}

// Add:
import { Boats } from 'views/account/boats';
{
    path: '/account/boats',
    view: Boats,
    layout: 'account',
    permission: 'user',
    title: 'account.index.title'
}
```

### 5. Update Navigation

**File:** `client/src/components/layout/account/account.jsx`

**Changes:**

```javascript
// Remove:
{
    label: t('account.nav.svs'),
    link: '/account/svs',
    icon: 'sailboat',
    permission: 'user'
}

// Add:
{
    label: t('account.nav.boats'),
    link: '/account/boats',
    icon: 'sailboat',
    permission: 'user'
}
```

**File:** `client/src/locales/en/account/en_nav.json`

**Changes:**

```json
{
  "profile": "Profile",
  "password": "Password",
  "tfa": "2FA",
  "billing": "Billing",
  "theme": "Theme",
  "notifications": "Notifications",
  "organizations": "Organizations",
  "clubs": "Clubs",
  "boats": "Boats", // ✨ NEW
  "svs": "Sailing Vessels" // ✅ KEEP (preserved for internal use, but remove from nav)
}
```

### 6. Update Account Index Page

**File:** `client/src/views/account/index.jsx`

**Changes:**

```javascript
// Remove SV card:
<Card>
    <Icon name='sailboat' size={iconSize}/>
    <h1>{t('account.svs.title')}</h1>
    <span>{t('account.svs.description')}</span>
    <Button url='/account/svs' ... />
</Card>

// Add Boat card:
<Card>
    <Icon name='sailboat' size={iconSize}/>
    <h1>{t('account.boats.title')}</h1>
    <span>{t('account.boats.description')}</span>
    <Button url='/account/boats' ... />
</Card>
```

### 7. Create Translation Files

**New File:** `client/src/locales/en/account/en_boats.json`

**Structure:** Copy from `en_clubs.json` and adapt:

```json
{
  "title": "Boats",
  "subtitle": "Manage Boats",
  "description": "Manage your boats",
  "button": "Manage Boats",
  "help": {
    "title": "About Boats",
    "description": "Boats represent vessels you own or are associated with. Each boat has sail information, brand, model, and builder details."
  },
  "search": {
    "placeholder": "Search by name, sail number, or country code..."
  },
  "add": {
    "button": "Add Boat",
    "selected": "Add {{count}} Selected",
    "success": "Boat added successfully",
    "error": "Failed to add boat"
  },
  "remove": {
    "success": "Boat removed successfully",
    "error": "Failed to remove boat"
  },
  "save": "Save",
  "save_success": "Boats saved successfully",
  "save_error": "Failed to save boats",
  "empty": "No boats found",
  "request": {
    "title": "Request New Boat",
    "description": "Request a new boat to be added to the system",
    "button": "Request Boat",
    "success": "Boat request submitted successfully",
    "form": {
      "name": {
        "label": "Boat Name",
        "placeholder": "Enter boat name"
      },
      "sail_cc": {
        "label": "Sail Country Code",
        "placeholder": "e.g., US"
      },
      "sail_no": {
        "label": "Sail Number",
        "placeholder": "e.g., 12345"
      },
      "brand": {
        "label": "Brand",
        "placeholder": "Enter brand name"
      },
      "model": {
        "label": "Model",
        "placeholder": "Enter model name"
      },
      "builder": {
        "label": "Builder",
        "placeholder": "Enter builder name"
      },
      "button": "Submit Request"
    }
  },
  "empty_state": {
    "title": "No Boats",
    "description": "You haven't added any boats yet. Search for existing boats or request a new one.",
    "button": "Request New Boat"
  },
  "boat": {
    "sail_no": "Sail No",
    "hin": "HIN"
  }
}
```

### 8. Keep SV Translation Files

**File:** `client/src/locales/en/account/en_svs.json` - ✅ KEEP (preserved for internal use)

---

## Backend Implementation

### 1. User Schema Update

**File:** `server/model/mongo/user.mongo.js`

**Changes:**

```javascript
// Add boat_ids field:
boat_keys: {
    type: Array,
    required: false
},
boat_keys: {
    type: Array,
    required: false
},
boat_ids: {
    type: Array,
    required: false
},
// Keep sv_ids for internal use:
sv_ids: {
    type: Array,
    required: false
    // ✅ KEEP - for internal use (not user-facing)
}
```

### 2. User Controller Update

**File:** `server/controller/user.controller.js`

**Changes:**

**A. Update Validation Schema:**

```javascript
// In exports.update validation:
boat_keys: joi.array().items(joi.string()).optional(),
boat_ids: joi.array().items(joi.string()).optional(),
sv_ids: joi.array().items(joi.string()).optional(), // ✅ KEEP - for internal use

// Add deduplication logic for boat_ids:
if (data.boat_ids) {
    data.boat_ids = [...new Set(data.boat_ids)]; // Remove duplicates
}
```

**B. Remove User SV Endpoint:**

```javascript
// Remove only the user-facing endpoint:
exports.svs = async function (req, res) {
  // ❌ DELETE THIS FUNCTION (GET /api/user/svs)
};

// Note: All other SV endpoints in sv.controller.js remain intact
// No boat endpoint needed - use boat.controller.list directly
```

**C. Update User Get Response:**

```javascript
// Ensure boat_ids is returned in user.get response
// May need to add to user.model.js get function
```

### 3. User Route Update

**File:** `server/api/user.route.js`

**Changes:**

```javascript
// Remove:
api.get(
  "/api/user/svs",
  auth.verify("user", "user.read"),
  use(userController.svs)
);

// Optionally add (if needed):
// api.get('/api/user/boats', auth.verify('user', 'user.read'), use(userController.boats));
```

### 4. Boat Controller Enhancement

**File:** `server/controller/boat.controller.js`

**Current:** Returns basic boat fields
**Enhancement:** Populate brand, model (design), builder for EntityCard display

**Changes:**

```javascript
exports.list = async function (req, res) {
  // ... existing search logic ...

  // Fetch boats (include logo if it exists in schema, but won't be uploaded here)
  const boats = await boat.schema
    .find(query)
    .select("id name sail_no sail_cc hin boat_design_id boat_builder_id logo")
    .lean()
    .sort({ sail_no: 1, name: 1 });

  // ✨ NEW: Populate brand, model, builder for EntityCard
  const boatsWithDetails = await Promise.all(
    boats.map(async (boatData) => {
      // Populate boat design (model) and brand
      if (boatData.boat_design_id) {
        const designData = await boatDesign.schema
          .findOne({ id: boatData.boat_design_id })
          .select("id name boat_brand_id")
          .lean();

        if (designData) {
          boatData.model = { name: designData.name };

          // Populate brand
          if (designData.boat_brand_id) {
            const brandData = await boatBrand.schema
              .findOne({ id: designData.boat_brand_id })
              .select("id name")
              .lean();
            if (brandData) {
              boatData.brand = { name: brandData.name };
            }
          }
        }
      }

      // Populate builder
      if (boatData.boat_builder_id) {
        const builderData = await boatBuilder.schema
          .findOne({ id: boatData.boat_builder_id })
          .select("id name")
          .lean();
        if (builderData) {
          boatData.builder = { name: builderData.name };
        }
      }

      return boatData;
    })
  );

  res.status(200).send({
    data: boatsWithDetails,
  });
};
```

**Note:** This matches the pattern used in `sv.controller.js` list function.

### 5. SV Controller & Routes (PRESERVE FOR INTERNAL USE)

**File:** `server/controller/sv.controller.js`

- ✅ KEEP - All functions preserved for internal use
- ✅ No changes needed

**File:** `server/api/sv.route.js`

- ✅ KEEP - All routes preserved for internal use
- ✅ No changes needed

### 6. SV Model (PRESERVE FOR INTERNAL USE)

**File:** `server/model/mongo/sv.mongo.js`

- ✅ KEEP - Preserved for internal use
- ✅ No changes needed

---

## Database Schema Changes

### User Collection Schema

**Current:**

```javascript
{
    sv_ids: Array<string>,      // ❌ DEPRECATE
    org_ids: Array<string>,
    club_ids: Array<string>
}
```

**Target:**

```javascript
{
    boat_ids: Array<string>,   // ✨ NEW
    org_ids: Array<string>,
    club_ids: Array<string>,
    sv_ids: Array<string>       // ⚠️ KEEP for migration, mark deprecated
}
```

### Migration Script

**NO MIGRATION SCRIPT NEEDED** - Clean database import will handle data setup.

---

## User Stories

### US-1: View My Boats

**As a** user
**I want to** see a list of boats I'm associated with
**So that** I can manage my boat relationships

**Acceptance Criteria:**

- Navigate to `/account/boats`
- See list of boats I've added (from `user.boat_ids`)
- Each boat displayed in EntityCard format
- Shows boat name, sail number, brand, model, builder

### US-2: Add Boats to My Profile

**As a** user
**I want to** add boats to my profile
**So that** I can associate myself with boats I own or use

**Acceptance Criteria:**

- Search for boats by name, sail number, or country code
- Select boats from search results
- Click "Add Selected" button
- Boats are added to my `boat_ids` array
- Success notification shown
- Boats appear in my connected boats list

### US-3: Remove Boats from My Profile

**As a** user
**I want to** remove boats from my profile
**So that** I can update my boat associations

**Acceptance Criteria:**

- See list of my connected boats
- Click remove (X) button on a boat
- Boat is removed from my `boat_ids` array
- Success notification shown
- Boat disappears from my connected boats list

### US-4: Request New Boat

**As a** user
**I want to** request a new boat be added to the system
**So that** I can add boats that don't exist yet

**Acceptance Criteria:**

- Click "Request New Boat" button
- Fill out form: name, sail_cc, sail_no, brand, model, builder
- Submit request
- Success notification shown
- Request submitted via `/api/entity_request`

### US-5: View Boat Details

**As a** user
**I want to** see detailed information about a boat
**So that** I can verify boat information

**Acceptance Criteria:**

- Boat displayed in EntityCard format
- Shows: name, sail number, brand, model, builder, HIN
- No SV-specific information shown
- No owner information shown (boats don't have owners)

---

## Data Flow Diagrams

### Current Flow (SV-Based)

```
User → /account/svs
  → Search Boats (GET /api/boat)
  → Select Boats
  → Create SVs (POST /api/sv)
    → System creates SV records
    → Links user via sv_ids
  → Display SVs (GET /api/user/svs)
    → Fetch SVs by sv_ids
    → Populate boat data
    → Display in EntityCard
```

### Target Flow (Boat-Based)

```
User → /account/boats
  → Search Boats (GET /api/boat)
  → Select Boats
  → Update User (PATCH /api/user)
    → Updates user.boat_ids array
  → Display Boats (GET /api/boat)
    → Fetch boats by boat_ids
    → Display in EntityCard
```

### Comparison Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    CURRENT (SV-BASED)                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  User → Select Boats → Create SVs → Link via sv_ids     │
│                                                         │
│  ┌──────┐    ┌──────┐    ┌──────┐    ┌──────┐           │
│  │ Boat │───▶│  SV  │───▶│ User │    │User  │           │
│  └──────┘    └──────┘    │sv_ids│    │      │           │
│                          └──────┘    └──────┘           │
│                                                         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                    TARGET (BOAT-BASED)                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  User → Select Boats → Update User → Link via boat_ids  │
│                                                         │
│  ┌──────┐              ┌──────┐                         │
│  │ Boat │─────────────▶│ User │                         │
│  └──────┘              │boat_ │                         │
│                        │ ids  │                         │
│                        └──────┘                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Affected Files & Modules

### Frontend Files

#### To Create

- ✨ `client/src/views/account/boats.jsx` - New boat management component
- ✨ `client/src/locales/en/account/en_boats.json` - Boat translations

#### To Modify

- 📝 `client/src/routes/account.js` - Change `/account/svs` to `/account/boats`
- 📝 `client/src/components/layout/account/account.jsx` - Update navigation
- 📝 `client/src/views/account/index.jsx` - Update account index page
- 📝 `client/src/components/entitycard/entitycard.jsx` - Add boat support, remove SV
- 📝 `client/src/components/entitycard/entitycard.utils.js` - Update entity types

#### To Remove/Deprecate

- ❌ `client/src/views/account/svs.jsx` - Remove SV management component (replace with boats.jsx)
- ✅ `client/src/locales/en/account/en_svs.json` - KEEP (preserved for internal use)

### Backend Files

#### To Modify

- 📝 `server/model/mongo/user.mongo.js` - Add `boat_ids` field
- 📝 `server/controller/user.controller.js` - Add `boat_ids` validation, remove `svs` endpoint
- 📝 `server/api/user.route.js` - Remove `/api/user/svs` route
- 📝 `server/controller/boat.controller.js` - Enhance list to populate brand/model/builder

#### To Remove/Deprecate

- ✅ `server/api/sv.route.js` - KEEP (all routes preserved for internal use)
- ✅ `server/controller/sv.controller.js` - KEEP (preserved for internal use)
- ✅ `server/model/mongo/sv.mongo.js` - KEEP (preserved for internal use)
- ❌ `server/api/user.route.js` - Remove only `GET /api/user/svs` route

### Database

#### Migration Scripts

- ❌ NO MIGRATION SCRIPTS - Clean database import will handle setup

---

## Implementation Phases

### Phase 1: Database & Backend Foundation

**Duration:** 2-3 days

1. ✅ Add `boat_ids` field to user schema
2. ✅ Update user controller validation to accept `boat_ids`
3. ✅ Enhance boat controller to populate brand/model/builder
4. ✅ Update user controller to return `boat_ids` in GET response
5. ✅ Remove `GET /api/user/svs` route only

### Phase 2: Frontend Boat Management UI

**Duration:** 3-4 days

1. ✅ Create `boats.jsx` component (copy from `clubs.jsx`)
2. ✅ Adapt component for boat-specific fields
3. ✅ Create `en_boats.json` translation file
4. ✅ Update routes to use `/account/boats`
5. ✅ Update navigation menu
6. ✅ Update account index page
7. ✅ Test boat add/remove functionality

### Phase 3: EntityCard Updates

**Duration:** 1-2 days

1. ✅ Update EntityCard to support `'boat'` entityType
2. ✅ Add boat-specific display fields (sail, brand, model, builder)
3. ✅ Remove/deprecate `'sailing-vessel'` entityType
4. ✅ Update EntityCard utils
5. ✅ Test EntityCard display with boats

### Phase 4: SV Deprecation & Cleanup

**Duration:** 2-3 days

1. ✅ Remove `GET /api/user/svs` endpoint (only user-facing SV endpoint)
2. ✅ Remove SV UI components (`svs.jsx`)
3. ✅ Keep SV translation files (preserved for internal use)
4. ✅ Keep SV routes/controller/model (preserved for internal use)

### Phase 5: Testing & Validation

**Duration:** 2-3 days

1. ✅ Test boat management flow end-to-end
2. ✅ Verify EntityCard displays correctly
3. ✅ Test entity request flow for boats
4. ✅ Verify SV UI removed but SV endpoints still work
5. ✅ Performance testing

### Phase 6: Migration Execution

**Duration:** 1 day

1. ✅ Run migration script on production database
2. ✅ Verify `boat_ids` populated correctly
3. ✅ Test user boat management after migration
4. ✅ Monitor for issues

---

## Questions for Clarification

### Critical Questions (Must Answer Before Implementation)

1. **Boat Entity Request:**

   - ✅ CONFIRMED: entity_request endpoint supports `entity_type: 'boat'`
   - What fields are required for boat entity requests? (Based on svs.jsx: name, sail_cc, sail_no, brand, model, builder)
   - Who approves boat entity requests? (Admin? Automated?)

2. **EntityCard Display:**

   - Should boats show owner information? (Currently SV shows owners, but boats don't have owners array)
   - Should EntityCard for boats show different fields than SV? (Yes - sail info, brand, model, builder instead of owners)
   - Should we remove the "Owners" display logic entirely from EntityCard?

3. **Boat Controller Enhancement:**

   - Should boat list endpoint always populate brand/model/builder?
   - Or only when requested via query parameter?
   - Performance considerations with population? (How many boats typically returned?)

4. **Data Validation:**

   - What happens if a user tries to add a boat_id that doesn't exist?
   - Should we validate boat_ids exist before saving to user.boat_ids?
   - Should we allow duplicate boat_ids in the array? (Probably not, but need confirmation)

5. **User Schema Fields:**

   - Should we also add `boat_keys` array (like `orgn_keys`, `club_keys`, `svsl_keys`)?
   - Or only `boat_ids` is needed?

6. **Boat Selection Display:**

   - In the boat selection popover, what information should be shown?
   - Should we show: name, sail_no, sail_cc? (Like current SV selection shows boat info)
   - Should we show brand/model/builder in the selection list? (May be too much info)

7. **EntityCard Boat Display:**

   - What fields should EntityCard show for boats?
   - Should it show: name, sail_no, sail_cc, brand, model, builder, HIN?
   - Should it show description? (Boats have description field)
   - Should it show logo? (Do boats have logos?)

8. **Boat Search:**
   - Current boat.controller.js searches by name, sail_no, sail_cc
   - Should we also search by brand/model/builder? (Would require joins)
   - Or is current search sufficient?

### Secondary Questions (Nice to Have Answers)

11. **Performance:**

    - How many boats per user on average?
    - Should we paginate boat list in EntityCard display?
    - Should we cache boat data?

12. **Future Features:**

    - Will we need boat ownership information in the future?
    - Should we plan for boat-specific permissions/roles?
    - Will boats need certificates (like SVs had)?

13. **UI/UX:**
    - Should boat selection show more details (brand, model) in the popover?
    - Should we group boats by brand/model in the display?
    - Should we add boat filtering/sorting options?

---

## Risk Assessment

### High Risk

1. **Data Import Issues**

   - **Risk:** Clean database import doesn't populate `boat_ids` correctly
   - **Mitigation:** Validate import process, test with sample data, verify data structure

2. **UI Breaking Changes**

   - **Risk:** Users lose access to SV management UI
   - **Mitigation:** Ensure boat management UI is fully functional before removing SV UI

3. **Performance Impact**
   - **Risk:** Populating brand/model/builder for all boats slows down API
   - **Mitigation:** Test performance, consider caching, optimize queries

### Medium Risk

4. **Data Import Validation**

   - **Risk:** Imported data doesn't match expected structure
   - **Mitigation:** Validate imported data structure, verify `boat_ids` populated correctly

5. **UI Inconsistencies**

   - **Risk:** Boat UI doesn't match Clubs/Organizations exactly
   - **Mitigation:** Copy exact pattern from clubs.jsx, code review

6. **Translation Missing**
   - **Risk:** Missing translation keys cause UI errors
   - **Mitigation:** Copy from clubs translations, test all language paths

### Low Risk

7. **SV References in Code**

   - **Risk:** Hidden SV references cause errors
   - **Mitigation:** Comprehensive grep search, code review

8. **EntityCard Display Issues**
   - **Risk:** Boat display doesn't work correctly
   - **Mitigation:** Test with various boat data, handle missing fields gracefully

---

## Testing Strategy

### Unit Tests

**Backend:**

- [ ] User controller accepts `boat_ids` in update
- [ ] User controller returns `boat_ids` in get
- [ ] Boat controller populates brand/model/builder correctly
- [ ] Clean database import populates boat_ids correctly
- [ ] Data import handles edge cases (missing boat_id, duplicate boats)

**Frontend:**

- [ ] Boats component renders correctly
- [ ] Boat search works
- [ ] Add/remove boats updates user correctly
- [ ] EntityCard displays boat information correctly
- [ ] Navigation menu shows boats link

### Integration Tests

- [ ] End-to-end: Add boat → Verify in user.boat_ids → Display in EntityCard
- [ ] End-to-end: Remove boat → Verify removed from user.boat_ids
- [ ] End-to-end: Request new boat → Verify entity_request created
- [ ] Migration: Run migration → Verify boat_ids populated → Verify UI works

### Manual Testing Checklist

- [ ] Navigate to `/account/boats`
- [ ] Search for boats
- [ ] Add boat to profile
- [ ] Remove boat from profile
- [ ] Request new boat
- [ ] Verify EntityCard displays boat correctly
- [ ] Verify navigation menu updated
- [ ] Verify account index page updated
- [ ] Test with user who has existing `sv_ids` (migration scenario)
- [ ] Test with user who has no boats
- [ ] Test with user who has many boats

---

## Success Criteria

### Functional Requirements

- ✅ Users can view boats they're associated with
- ✅ Users can add boats to their profile
- ✅ Users can remove boats from their profile
- ✅ Users can request new boats
- ✅ Boat information displays correctly in EntityCard
- ✅ Boat management UI matches Clubs/Organizations pattern exactly
- ✅ No SV creation/management UI remains (SV endpoints preserved for internal use)
- ✅ Clean database import populates `boat_ids` correctly

### Non-Functional Requirements

- ✅ Performance: Boat list loads in < 2 seconds
- ✅ UI consistency: Boat UI matches Clubs/Organizations exactly
- ✅ Data integrity: Clean database import handles data setup
- ✅ SV endpoints preserved: All `/api/sv/*` endpoints remain for internal use

---

## Next Steps

1. **Review this plan** - Ensure all requirements captured
2. **Answer clarification questions** - Resolve ambiguities
3. **Approve implementation** - Give explicit command to proceed
4. **Execute Phase 1** - Database & backend foundation
5. **Execute Phase 2** - Frontend boat management UI
6. **Execute Phase 3** - EntityCard updates
7. **Execute Phase 4** - SV UI removal (keep endpoints)
8. **Execute Phase 5** - Testing & validation
9. **Execute Phase 6** - Data import & validation

---

## Plan Review & Confidence Assessment

### Implementation Confidence: **99%**

#### High Confidence Areas (95%+)

1. **Frontend Component Creation** - 98%

   - Clear pattern to follow (clubs.jsx, organizations.jsx)
   - Well-understood Popover/selection UI pattern
   - Translation file structure is clear
   - Navigation/routing changes are straightforward

2. **Backend Schema Changes** - 98%

   - Adding `boat_ids` and `boat_keys` to user schema is straightforward
   - User controller validation pattern is clear
   - Boat controller enhancement follows existing pattern (sv.controller.js)
   - Boat schema changes NOT required (boat editing handled separately)

3. **EntityCard Updates** - 97%

   - Adding `'boat'` entityType is straightforward
   - Boat display format EXACTLY specified
   - Logo will display if available (populated by separate boat editing interface)
   - Pattern exists in current SV display logic

4. **Route/Navigation Updates** - 98%
   - Simple route changes
   - Navigation menu updates are clear
   - Account index page updates are straightforward

#### Medium Confidence Areas (80-90%)

5. **Boat Controller Enhancement** - 85%

   - Need to populate brand/model/builder relationships
   - Performance impact unknown (how many boats typically returned?)
   - Pattern exists in sv.controller.js but need to verify boat relationships

6. **Entity Request Flow** - 90%
   - Endpoint already supports `entity_type: 'boat'`
   - Form fields are clear from svs.jsx
   - Approval process unclear (who approves?)

#### Lower Confidence Areas (70-85%)

7. **Data Validation** - 80%

   - Should we validate boat_ids exist before saving?
   - What happens if invalid boat_id is provided?
   - Should we allow duplicates in boat_ids array?

8. **Boat Display Details** - 97%
   - ✅ Exact format specified (requirement 4a)
   - ✅ Logo will display if available (populated by separate boat editing interface)
   - ✅ All fields clearly defined

### Remaining Questions for 95%+ Confidence

#### Critical Questions (Must Answer)

1. **User Schema - boat_keys:**

   - Should we add `boat_keys` array (like `orgn_keys`, `club_keys`, `svsl_keys`)?
   - Or is `boat_ids` sufficient?

2. **Boat Controller Enhancement:**

   - Should boat list endpoint ALWAYS populate brand/model/builder?
   - Or only populate when needed (performance consideration)?
   - How many boats are typically returned in a search? (affects performance)

3. **Data Validation:**

   - Should we validate that boat_ids exist in database before saving to user.boat_ids?
   - What should happen if user tries to add non-existent boat_id?
   - Should we prevent duplicate boat_ids in the array? (probably yes, but confirm)

4. **EntityCard Boat Display:**

   - What exact fields should EntityCard show for boats?
   - Should it show: name, sail_no, sail_cc, brand, model, builder, HIN, description?
   - Do boats have logos? (Not in current boat schema, but should we check?)
   - Should we show any owner information? (Boats don't have owners array)

5. **Boat Selection Display:**

   - In the selection popover, what information should be shown for each boat?
   - Should we show: name, sail_no, sail_cc? (Like current SV selection)
   - Should we show brand/model/builder in selection list? (May be too much info)

6. **Entity Request Approval:**
   - Who approves boat entity requests? (Admin? Automated?)
   - What happens after approval? (Boat created automatically?)

#### Secondary Questions (Nice to Have) ✅ ANSWERED

7. **Boat Search Enhancement:** ✅ ANSWERED

   - ✅ Current search is fine (requirement 7a)

8. **Performance Considerations:** ✅ ANSWERED

   - ✅ 1 on average (requirement 8a)
   - ✅ Pagination not needed (requirement 8b)
   - ✅ Caching not required (requirement 8c)

9. **Boat Editing & Image Uploads:** ✅ CLARIFIED
   - ✅ OUT OF SCOPE for this implementation
   - ✅ Handled separately from boat management

### All Assumptions Confirmed ✅

1. ✅ Entity request endpoint supports `entity_type: 'boat'` (CONFIRMED)
2. ✅ Boat entity request form fields: name, sail_cc, sail_no, brand, model, builder (CONFIRMED)
3. ✅ Boat controller can populate brand/model/builder (pattern exists in sv.controller.js, CONFIRMED)
4. ✅ EntityCard format EXACTLY specified (CONFIRMED - requirement 4a)
5. ✅ No migration needed - clean database import handles setup (CONFIRMED)
6. ✅ SV endpoints preserved for internal use (CONFIRMED)
7. ✅ SV translation files preserved (CONFIRMED)
8. ✅ Boat schema may have `images` array and `logo` field (populated by separate boat editing interface, NOT this implementation)
9. ✅ User schema will have `boat_keys` array (CONFIRMED - requirement 1)
10. ✅ Deduplication required for boat_ids (CONFIRMED - requirement 3c)
11. ✅ Admin approves boat requests (CONFIRMED - requirement 6a)
12. ✅ Popover format already exists for boats (CONFIRMED - requirement 5a)
13. ✅ Boat editing and image uploads handled separately (OUT OF SCOPE for this implementation)
14. ✅ Admin boat/club/org creation from requests handled later (TBD, not blocking)

### Risk Mitigation

**Low Risk Items:** ✅

- Frontend component creation (clear pattern, popover format exists)
- Route/navigation updates (straightforward)
- User schema changes (simple addition, boat_keys + boat_ids)
- Boat schema changes (images array + logo field, follows existing pattern)
- EntityCard boat display (EXACT format specified)
- Data validation (no validation needed, deduplication confirmed)
- File upload implementation (OUT OF SCOPE - boat editing handled separately)

**Medium Risk Items:** ✅ RESOLVED

- ~~Boat controller enhancement~~ → Pattern confirmed, performance acceptable
- ~~EntityCard boat display~~ → Exact format specified
- ~~Data validation~~ → No validation needed, deduplication confirmed
- ~~File upload pattern~~ → Same as avatar, pattern confirmed

**Mitigation Strategies:**

- ✅ Follow exact pattern from clubs.jsx for boats.jsx
- ✅ Use existing popover format (already for boats)
- ✅ Follow sv.controller.js pattern for boat controller enhancement
- ✅ Implement exact EntityCard format as specified
- ✅ Add deduplication logic for boat_ids array
- ✅ Add boat_keys support following existing pattern (orgn_keys, club_keys, svsl_keys)
- ✅ Boat editing and image uploads - handled separately (OUT OF SCOPE for this implementation)
- ✅ Admin boat/club/org creation from requests - handled later (TBD, not blocking UI implementation)

---

**END OF IMPLEMENTATION PLAN**
