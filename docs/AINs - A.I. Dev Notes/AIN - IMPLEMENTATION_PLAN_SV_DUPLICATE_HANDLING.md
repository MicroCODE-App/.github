# Implementation Plan: SV Duplicate Handling with User Choice Modal

## Executive Summary

When a user attempts to create a Sailing Vessel (SV) for a boat that already has existing SV(s), display a modal dialog allowing the user to choose between:

1. **Create New SV** (sole owner) - Creates new SV, deletes existing non-immutable SV
2. **Clone Existing SV** (joint owner) - Clones selected existing SV and adds user as owner
3. **Cancel** - Aborts the operation

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Data Flow Diagrams](#data-flow-diagrams)
3. [API Contract Changes](#api-contract-changes)
4. [Frontend Implementation](#frontend-implementation)
5. [Backend Implementation](#backend-implementation)
6. [User Interface Design](#user-interface-design)
7. [State Management](#state-management)
8. [Error Handling](#error-handling)
9. [Security Considerations](#security-considerations)
10. [Testing Strategy](#testing-strategy)
11. [Translation Keys](#translation-keys)
12. [Migration Considerations](#migration-considerations)

---

![1765735263410](image/IMPLEMENTATION_PLAN_SV_DUPLICATE_HANDLING/1765735263410.png)![1765735264193](image/IMPLEMENTATION_PLAN_SV_DUPLICATE_HANDLING/1765735264193.png)![1765735265560](image/IMPLEMENTATION_PLAN_SV_DUPLICATE_HANDLING/1765735265560.png)![1765735266128](image/IMPLEMENTATION_PLAN_SV_DUPLICATE_HANDLING/1765735266128.png)![1765735266860](image/IMPLEMENTATION_PLAN_SV_DUPLICATE_HANDLING/1765735266860.png)![1765735267459](image/IMPLEMENTATION_PLAN_SV_DUPLICATE_HANDLING/1765735267459.png)![1765735268026](image/IMPLEMENTATION_PLAN_SV_DUPLICATE_HANDLING/1765735268026.png)![1765735270255](image/IMPLEMENTATION_PLAN_SV_DUPLICATE_HANDLING/1765735270255.png)
![1765735284112](image/IMPLEMENTATION_PLAN_SV_DUPLICATE_HANDLING/1765735284112.png)![1765735329277](image/IMPLEMENTATION_PLAN_SV_DUPLICATE_HANDLING/1765735329277.png)![1765735348146](image/IMPLEMENTATION_PLAN_SV_DUPLICATE_HANDLING/1765735348146.png)![1765735356812](image/IMPLEMENTATION_PLAN_SV_DUPLICATE_HANDLING/1765735356812.png)![1765735387662](image/IMPLEMENTATION_PLAN_SV_DUPLICATE_HANDLING/1765735387662.png)![1765735388913](image/IMPLEMENTATION_PLAN_SV_DUPLICATE_HANDLING/1765735388913.png)![1765735389129](image/IMPLEMENTATION_PLAN_SV_DUPLICATE_HANDLING/1765735389129.png)![1765735389315](image/IMPLEMENTATION_PLAN_SV_DUPLICATE_HANDLING/1765735389315.png)

## Architecture Overview

### Current Flow

```
User selects boats → Click "Add Selected"
→ POST /api/sv { boat_id } (parallel for all)
→ If duplicate: Return existing SV with duplicate: true
→ Show toast notification
→ Refresh data
```

### New Flow

```
User selects boats → Click "Add Selected"
→ POST /api/sv { boat_id } (parallel for all)
→ Process results:
  ├─ Success: Add to success list
  ├─ Duplicate:
  │   ├─ Fetch ALL existing SVs for boat_id
  │   ├─ Show modal with list of existing SVs
  │   ├─ User selects action + existing_sv_id
  │   └─ POST /api/sv { boat_id, action, existing_sv_id }
  └─ Failed: Add to failed list
→ Show notifications
→ Refresh data
```

---

## Data Flow Diagrams

### Sequence Diagram: Duplicate SV Creation Flow

```
User          Frontend          Backend          Database
 │               │                 │                 │
 │──Select Boats─>                 │                 │
 │               │                 │                 │
 │──Click Add───>                 │                 │
 │               │                 │                 │
 │               │──POST /api/sv──>                 │
 │               │  {boat_id}      │                 │
 │               │                 │──Query SV──────>│
 │               │                 │<─Existing SV────│
 │               │<─200 duplicate──│                 │
 │               │  {existingSv}   │                 │
 │               │                 │                 │
 │               │──GET /api/sv/by-boat?boat_id───>  │
 │               │                 │──Query ALL SVs─>│
 │               │<─200 {svs[]}───│<─Multiple SVs───│
 │               │                 │                 │
 │<──Show Modal──│                 │                 │
 │  (List SVs)   │                 │                 │
 │               │                 │                 │
 │──Select:      │                 │                 │
 │  Clone + SV──>│                 │                 │
 │               │                 │                 │
 │               │──POST /api/sv──>│                 │
 │               │  {boat_id,      │                 │
 │               │   action:       │                 │
 │               │   'clone',      │                 │
 │               │   existing_     │                 │
 │               │   sv_id}        │                 │
 │               │                 │──Query SV───────>│
 │               │                 │<─Existing SV────│
 │               │                 │──Clone & Insert>│
 │               │                 │<─New SV─────────│
 │               │<─201 Created───│                 │
 │               │                 │                 │
 │<──Success─────│                 │                 │
 │  Notification │                 │                 │
```

### State Machine: Modal Flow

```
[Initial State]
    │
    ├─> [Processing Duplicates]
    │       │
    │       ├─> [Show Modal]
    │       │       │
    │       │       ├─> User selects "New" ──> [Create New SV]
    │       │       │                              │
    │       │       │                              └─> [Success]
    │       │       │
    │       │       ├─> User selects "Clone" + SV ──> [Clone SV]
    │       │       │                                  │
    │       │       │                                  ├─> Success ──> [Success]
    │       │       │                                  └─> Fail ──> [Fallback to New]
    │       │       │
    │       │       └─> User selects "Cancel" ──> [Skip]
    │       │
    │       └─> [Next Duplicate?]
    │               │
    │               ├─> Yes ──> [Show Modal] (loop)
    │               └─> No ──> [Complete]
    │
    └─> [All Complete]
            │
            └─> [Show Final Notifications]
```

---

## API Contract Changes

### 1. POST /api/sv (Modified)

#### Request Body (Enhanced)

```typescript
{
  boat_id: string;           // Required - Boat ID
  description?: string;      // Optional - SV description
  action?: 'new' | 'clone'; // Optional - Action when duplicate exists
  existing_sv_id?: string;  // Required if action='clone' - Existing SV ID to clone
}
```

#### Response Codes

**201 Created** - SV created successfully

```json
{
  "message": "sv.create.success",
  "data": {
    "id": "svsl_...",
    "name": "SV Boat Name",
    "boat_id": "boat_...",
    "user_ids": {
      "owners": ["user_..."]
    },
    ...
  }
}
```

**200 OK** - Duplicate detected (no action specified)

```json
{
  "message": "sv.create.duplicate",
  "data": {
    "id": "svsl_...",
    "name": "SV Boat Name",
    ...
  },
  "duplicate": true,
  "existing_svs": [  // NEW: Array of all existing SVs for this boat
    {
      "id": "svsl_...",
      "name": "SV Boat Name",
      "immutable": false,
      "user_ids": {
        "owners": ["user_1", "user_2"]
      },
      "boat": {
        "name": "Boat Name",
        "sail_cc": "US",
        "sail_no": "12345"
      }
    }
  ]
}
```

**201 Created** - SV cloned successfully

```json
{
  "message": "sv.create.clone_success",
  "data": {
    "id": "svsl_new_...",
    "name": "SV Boat Name",
    "previous_id": "svsl_original_...",
    "user_ids": {
      "owners": ["user_original_1", "user_original_2", "user_current"]
    },
    ...
  },
  "cloned": true
}
```

**400 Bad Request** - Invalid action or missing existing_sv_id

```json
{
  "message": "sv.create.invalid_action"
}
```

### 2. GET /api/sv/by-boat (New Endpoint)

#### Query Parameters

```
?boat_id=<boat_id>
```

#### Response

```json
{
  "data": [
    {
      "id": "svsl_...",
      "name": "SV Boat Name",
      "immutable": false,
      "user_ids": {
        "owners": ["user_1", "user_2"],
        "crew": ["user_3"]
      },
      "boat": {
        "id": "boat_...",
        "name": "Boat Name",
        "sail_cc": "US",
        "sail_no": "12345"
      },
      "owners": [
        // NEW: Populated owner names
        {
          "id": "user_1",
          "name": "John Doe"
        },
        {
          "id": "user_2",
          "name": "Jane Smith"
        }
      ]
    }
  ]
}
```

---

## Frontend Implementation

### File: `client/src/views/account/svs.jsx`

#### Changes Required

**1. Add State for Modal Management**

```javascript
const [pendingDuplicates, setPendingDuplicates] = useState([]); // Queue: [{ boatId, boatData, existingSvs }]
const [currentDuplicateIndex, setCurrentDuplicateIndex] = useState(0); // Current index in queue
const [isModalOpen, setIsModalOpen] = useState(false);
const [duplicateProgress, setDuplicateProgress] = useState({
  current: 0,
  total: 0,
}); // For progress bar
```

**2. Modify `handleCreateSVs` Function**

**Current Structure:**

```javascript
handleCreateSVs() {
  → Create SVs in parallel
  → Process results (successful, duplicates, failed)
  → Show notifications
}
```

**New Structure:**

```javascript
handleCreateSVs() {
  → Create SVs in parallel (first attempt)
  → Process results:
    → Successful: Add to success list
    → Duplicates:
      → Fetch all existing SVs for each boat (GET /api/sv/by-boat)
      → Queue duplicates for sequential processing
      → Process first duplicate (show modal)
    → Failed: Add to failed list
  → After modal closes:
    → Based on user choice:
      → 'new': POST /api/sv { boat_id, action: 'new' }
      → 'clone': POST /api/sv { boat_id, action: 'clone', existing_sv_id }
      → 'cancel': Skip
    → Process next duplicate (if any)
  → Show final notifications
  → Refresh data
}
```

**3. New Function: `handleDuplicateChoice`**

```javascript
handleDuplicateChoice(boatId, action, existingSvId) {
  → POST /api/sv { boat_id: boatId, action, existing_sv_id: existingSvId }
  → Handle response:
    → Success: Add to success list
    → Error:
      → If clone failed: Fallback to 'new' with warning toast
      → Add to failed list
  → Process next duplicate
}
```

**4. New Function: `showDuplicateModal`**

```javascript
showDuplicateModal(boatId, boatData, existingSvs, currentIndex, totalCount) {
  → Format existing SVs for display:
    → Boat name: boatData.name
    → Sail info: `${boatData.sail_cc} ${boatData.sail_no}`.trim()
    → Owner names: Format as "First Last" from owners array
    → Filter out SVs where user is already owner (frontend validation)
  → Show dialog with:
    → Progress indicator (if totalCount > 1): "Processing {currentIndex + 1} of {totalCount}"
    → Boat and sail information display
    → List of existing SVs with owners
    → Radio buttons for action selection
    → Conditional dropdown for existing_sv_id (only when action='clone')
    → Continue/Cancel buttons
  → On X button close: Cancel all remaining duplicates
  → On submit: Call handleDuplicateChoice
  → On cancel: Skip this duplicate, process next
}
```

**Frontend Validation**:

- Filter existingSvs to exclude SVs where user is already in owners array
- Validate existing_sv_id belongs to boat_id before API call
- Prevent cloning SV user already owns

````

**5. Modal Component Structure**

```javascript
viewContext.dialog.open({
  title: t("account.svs.duplicate.modal.title"),
  description: t("account.svs.duplicate.modal.description", {
    boatName: boat.name,
    sailInfo: `${boat.sail_cc} ${boat.sail_no}`.trim(),
  }),
  form: {
    inputs: {
      action: {
        type: "radio",
        label: t("account.svs.duplicate.modal.action.label"),
        options: [
          {
            value: "new",
            label: t("account.svs.duplicate.modal.action.new.label"),
            description: t(
              "account.svs.duplicate.modal.action.new.description"
            ),
          },
          {
            value: "clone",
            label: t("account.svs.duplicate.modal.action.clone.label"),
            description: t(
              "account.svs.duplicate.modal.action.clone.description"
            ),
          },
          {
            value: "cancel",
            label: t("account.svs.duplicate.modal.action.cancel.label"),
            description: t(
              "account.svs.duplicate.modal.action.cancel.description"
            ),
          },
        ],
        defaultValue: "new",
        required: true,
      },
      existing_sv_id: {
        type: "radio", // Radio buttons for SV selection
        label: t("account.svs.duplicate.modal.existing_sv.label"),
        options: existingSvs.map((sv) => ({
          value: sv.id,
          label: formatSvDisplay(sv), // "SV Name - Owner1, Owner2 [Immutable]"
        })),
        required: true, // Only required when action='clone'
        conditional: (formData) => formData.action === "clone",
      },
    },
    buttonText: t("account.svs.duplicate.modal.button.continue"),
    callback: async (res, formData) => {
      if (formData.action === "cancel") {
        // Skip this duplicate
        return;
      }
      await handleDuplicateChoice(
        boatId,
        formData.action,
        formData.existing_sv_id
      );
    },
  },
});
````

**6. Helper Function: `formatSvDisplay`**

```javascript
formatSvDisplay(sv) {
  // Format owner names as "First Last, First Last"
  const ownerNames = sv.owners
    ?.map(o => {
      // Name is already formatted as "First Last" from backend
      return o.name || 'Unknown';
    })
    .join(', ') || 'Unknown';

  const immutableBadge = sv.immutable ? ' [Immutable]' : '';
  return `${sv.name} - ${ownerNames}${immutableBadge}`;
}
```

**7. Helper Function: `fetchExistingSVsForBoat`**

```javascript
async fetchExistingSVsForBoat(boatId) {
  → GET /api/sv/by-boat?boat_id=${boatId}
  → Get array of existing SVs
  → For each SV: GET /api/sv/${sv.id}/owners to populate owner names
  → Return array of SVs with populated owners
}
```

**Note**: Frontend calls owners endpoint for each SV to get owner names. Could be optimized with Promise.all for parallel calls.

````

---

## Backend Implementation

### File: `server/controller/sv.controller.js`

#### Changes Required

**1. Modify `exports.create` Function**

**Current Logic:**

```javascript
exports.create() {
  → Validate boat_id
  → Check for duplicate (user is owner)
  → If duplicate: Return existing SV
  → Create new SV
}
````

**New Logic:**

```javascript
exports.create() {
  → Validate boat_id, action, existing_sv_id
  → If action provided:
    → Handle action-specific logic
  → Else:
    → Check for duplicate (user is owner)
    → If duplicate:
      → Fetch ALL existing SVs for boat_id
      → Populate owner names
      → Return with existing_svs array
    → Create new SV
}
```

**2. New Function: `handleNewSvAction`**

```javascript
async handleNewSvAction(req, res, boatData, data) {
  → Find ALL existing SVs for boat_id where user is owner
  → For each existing SV:
    → If immutable: DO NOT TOUCH (leave as-is, immutable records are protected)
    → If not immutable: Delete SV entirely (sv.delete())
  → Create new SV with only current user as owner
  → Return created SV
}
```

**Important**:

- **DO NOT modify immutable SVs** - They are protected and used in race results
- Delete ALL mutable SVs where user is owner (user selected "sole ownership")
- User will own both immutable SV (if exists) and new SV after this operation

````

**3. New Function: `handleCloneSvAction`**

```javascript
async handleCloneSvAction(req, res, boatData, data, existingSvId) {
  → Validate existing_sv_id exists and belongs to boat_id
  → Validate user is NOT already an owner (prevent duplicate)
  → Fetch existing SV
  → Clone SV:
    → Copy ALL fields including:
      → name (same)
      → display (copy)
      → description (copy)
      → certs (deep copy)
      → user_keys (copy array as-is)
      → user_ids (copy structure, add current user to owners)
      → boat_key, boat_id (copy)
    → Set new fields:
      → id (new unique ID)
      → key (omit - don't set)
      → user_ids.owners (add current user to existing owners array)
      → previous_id (set to existing SV id)
      → immutable (always set to false)
      → created_at (new timestamp)
      → updated_at (null)
      → rev (0)
  → Create cloned SV
  → Return cloned SV
}
````

**Deep Copy for certs**:

- Use JSON.parse(JSON.stringify(existingSv.certs)) or structuredClone()
- Ensure nested objects are fully copied

````

**4. Helper Function: `getAllSVsForBoat`**

```javascript
async getAllSVsForBoat(boatId) {
  → Query: sv.schema.find({ boat_id: boatId })
  → Populate boat data
  → Populate owner names (user.get() for each owner ID)
  → Return array with owners array populated
}
````

**5. New Endpoint: `GET /api/sv/:id/owners` (Get Owners for SV)**

```javascript
exports.getOwners = async function(req, res) {
  → Validate sv_id parameter
  → Fetch SV by id
  → Extract owner IDs from user_ids.owners
  → Fetch user data for each owner ID (batch lookup)
  → Format names as "First Last"
  → Return: { owners: [{ id: "user_...", name: "John Doe" }, ...] }
}
```

**Note**: This endpoint will be called from frontend for each SV to populate owner names. Backend handles name formatting.

````

**Name Formatting Logic**:

```javascript
function formatUserName(user) {
  if (!user || !user.name) return "Unknown";

  // user.name might be "John Doe" or structured object
  // If string: split and take first + last
  // If object: use name.first + name.last
  if (typeof user.name === "string") {
    const parts = user.name.trim().split(/\s+/);
    if (parts.length >= 2) {
      return `${parts[0]} ${parts[parts.length - 1]}`;
    }
    return parts[0] || "Unknown";
  }

  // If structured name object
  if (user.name.first && user.name.last) {
    return `${user.name.first} ${user.name.last}`;
  }

  return "Unknown";
}
````

````

### File: `server/api/sv.route.js`

#### New Routes

```javascript
api.get("/api/sv/by-boat", auth.verify("user"), use(svController.getByBoat));
api.get("/api/sv/:id/owners", auth.verify("user"), use(svController.getOwners));
````

### File: `server/controller/sv.controller.js`

#### New Function: `exports.getByBoat`

```javascript
exports.getByBoat = async function(req, res) {
  → Validate boat_id query parameter
  → Fetch all SVs for boat_id
  → Populate boat data
  → Populate owner names
  → Return array of SVs
}
```

---

## User Interface Design

### Modal Layout

```
┌─────────────────────────────────────────────┐
│  Sailing Vessel Already Exists        [X]   │
├─────────────────────────────────────────────┤
│                                             │
│  A sailing vessel already exists for:       │
│                                             │
│  Boat: [Boat Name]                          │
│  Sail: [US 12345]                          │
│                                             │
│  Existing Sailing Vessel(s):                │
│  ┌─────────────────────────────────────┐   │
│  │ • SV Boat Name                      │   │
│  │   Owners: John Doe, Jane Smith      │   │
│  │   [Immutable]                       │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  Note: Only Boat Name and Sail info shown  │
│  (No description, certs, dates)            │
│                                             │
│  What would you like to do?                 │
│                                             │
│  ○ Create New SV (I am the sole owner)     │
│    Create a new sailing vessel with only   │
│    you as the owner.                       │
│                                             │
│  ○ Clone Existing SV (Joint ownership)     │
│    Create a copy of an existing SV and     │
│    add yourself as a joint owner.          │
│                                             │
│    Select SV to clone:                      │
│    [Dropdown: SV Boat Name - John, Jane ▼]  │
│                                             │
│  ○ Cancel (Selection mistake)              │
│    Do not create a sailing vessel for      │
│    this boat.                              │
│                                             │
│                    [Cancel]  [Continue]     │
└─────────────────────────────────────────────┘
```

### Conditional Display Logic

- **Action = "new"**: Hide existing_sv_id dropdown
- **Action = "clone"**: Show existing_sv_id dropdown (required, filtered to exclude SVs user already owns)
- **Action = "cancel"**: Hide existing_sv_id dropdown
- **Multiple Existing SVs**: Show dropdown/select list of all available SVs
- **Single Existing SV**: Pre-select in dropdown (if clone selected and user doesn't own it)
- **Immutable SV**: Show "[Immutable]" badge/indicator
- **Progress Bar**: Show if totalCount > 1 (e.g., "Processing 2 of 5")
- **X Button**: Cancel all remaining duplicates, close modal, show cancellation notification

### Progress Bar Implementation (All Operations, Bottom of Modal)

```javascript
// Progress bar shows ALL operations (successful + duplicates + failed)
// Location: Bottom of modal, above buttons
{
  totalOperations > 1 && (
    <div className="mt-6 pt-4 border-t border-slate-200 dark:border-slate-700">
      <div className="text-sm text-slate-600 dark:text-slate-400 mb-2">
        Processing {completedOperations + 1} of {totalOperations}
      </div>
      <div className="w-full bg-slate-200 dark:bg-slate-800 rounded-full h-2">
        <div
          className="bg-primary h-2 rounded-full transition-all"
          style={{
            width: `${((completedOperations + 1) / totalOperations) * 100}%`,
          }}
        />
      </div>
    </div>
  );
}
```

**Progress Calculation**:

- `totalOperations` = successful + duplicates + failed (all boats selected)
- `completedOperations` = successful + processed duplicates + failed
- Update after each operation completes

---

## State Management

### State Variables

```javascript
// Existing
const [selectedBoatIds, setSelectedBoatIds] = useState([]);
const [creating, setCreating] = useState(false);

// New
const [pendingDuplicates, setPendingDuplicates] = useState([]); // Queue: [{ boatId, boatData, existingSvs }]
const [currentDuplicateIndex, setCurrentDuplicateIndex] = useState(0);
const [duplicateResults, setDuplicateResults] = useState({
  successful: [],
  cloned: [],
  failed: [],
  cancelled: [],
});
```

### State Flow

```
Initial State
  → User clicks "Add Selected"
  → creating = true
  → Create SVs in parallel (first attempt)
  → Process results:
    → Successful → Add to success list, show success toast
    → Duplicates →
      → Fetch all existing SVs for boat (GET /api/sv/by-boat)
      → Filter out SVs where user is already owner (frontend validation)
      → Add to pendingDuplicates queue: [{ boatId, boatData, existingSvs }]
    → Failed → Add to failed list, show error toast
  → If pendingDuplicates.length > 0:
    → Set duplicateProgress: { current: 0, total: pendingDuplicates.length }
    → Show modal for pendingDuplicates[0]
    → Wait for user choice:
      → User selects action + existing_sv_id (if clone)
      → User clicks Continue:
        → Validate existing_sv_id belongs to boat_id (frontend)
        → POST /api/sv with action
        → Process response:
          → Success → Add to appropriate list
          → Clone failed → Fallback to 'new' with warning toast
      → User clicks Cancel OR X button:
        → Cancel all remaining duplicates
        → Clear pendingDuplicates queue
        → Close modal
        → Show cancellation notification
    → If Continue clicked:
      → Remove current from queue
      → Increment currentDuplicateIndex
      → Update duplicateProgress
      → If more in queue → Show next modal
      → If queue empty → Complete
  → creating = false
  → Show final summary notifications
  → Refresh data (triggerRefresh, triggerSvsRefresh)
```

### Cancel All Behavior

When user clicks X button or Cancel:

```javascript
→ Count cancelled operations: pendingDuplicates.length
→ Clear pendingDuplicates queue
→ Set currentDuplicateIndex to 0
→ Close modal
→ Show notification: "Cancelled creating {count} sailing vessel(s)"
  → Example: "Cancelled creating 3 sailing vessel(s)"
→ Continue with already successful SVs
→ Refresh data
```

**Notification Format**:

- Show count only: "Cancelled creating X sailing vessel(s)"
- No list of boat names
- No additional details

---

## Error Handling

### Error Scenarios

**1. Clone Fails (Validation/Other Error)**

- **Action**: Fallback to 'new' action automatically
- **User Feedback**: Warning toast: "Clone failed, created new SV instead"
- **Backend Response**: Return success with flag `{ cloned: false, fallback: true }`
- **Logging**: Log fallback for debugging

**2. Clone Fails (SV Not Found)**

- **Action**: Return 404 error
- **User Feedback**: Error toast with message
- **Logging**: Log error

**3. Clone Fails (Network Error)**

- **Action**: Show error, allow retry
- **User Feedback**: Error toast with retry option
- **Logging**: Log error

**4. Delete Fails (Non-Immutable SV)**

- **Action**: Continue with creation, log error
- **User Feedback**: Error toast: "Failed to delete existing SV, but new SV was created"
- **Logging**: Log error for debugging/admin review

**5. Invalid Action Parameter**

- **Action**: Return 400 Bad Request
- **User Feedback**: Error toast
- **Logging**: Log validation error

**6. Missing existing_sv_id for Clone**

- **Action**: Return 400 Bad Request
- **User Feedback**: Error toast
- **Logging**: Log validation error

### Error Handling Code Structure

```javascript
try {
  if (action === 'clone') {
    try {
      return await handleCloneSvAction(...);
    } catch (cloneError) {
      // Fallback to new
      mcode.warn('SV clone failed, falling back to new:', cloneError);
      // Show warning toast (handled in frontend)
      return await handleNewSvAction(...);
    }
  }
} catch (error) {
  // Handle other errors
}
```

---

## Security Considerations

### 1. Authorization Checks

**Before Clone:**

- Verify existing_sv_id belongs to the specified boat_id
- Verify user has permission to clone (anyone can clone, but validate boat_id match)

**Before Delete (New Action):**

- Verify user is owner of existing SV
- Verify SV is not immutable
- Verify SV belongs to specified boat_id

**Before Create:**

- Verify boat_id exists and is valid
- Verify user has permission to create SVs

### 2. Input Validation

```javascript
// Validate action
if (data.action && !["new", "clone"].includes(data.action)) {
  throw { message: res.__("sv.create.invalid_action") };
}

// Validate existing_sv_id when cloning
if (data.action === "clone" && !data.existing_sv_id) {
  throw { message: res.__("sv.create.missing_existing_sv_id") };
}

// Validate existing_sv_id exists and belongs to boat
if (data.action === "clone") {
  const existingSv = await sv.schema
    .findOne({
      id: data.existing_sv_id,
      boat_id: data.boat_id,
    })
    .lean();

  if (!existingSv) {
    throw { message: res.__("sv.create.invalid_existing_sv") };
  }
}
```

### 3. Data Sanitization

- Sanitize boat_id, existing_sv_id (prevent injection)
- Validate boat_id format
- Validate existing_sv_id format

### 4. Rate Limiting

- Existing rate limits apply
- Consider additional limits for clone operations

---

## Testing Strategy

### Unit Tests

**Backend (`server/controller/sv.controller.js`)**

- [ ] Test create with no duplicate (normal flow)
- [ ] Test create with duplicate, no action (returns existing_svs)
- [ ] Test create with action='new', non-immutable SV exists (deletes old, creates new)
- [ ] Test create with action='new', immutable SV exists (keeps old, creates new)
- [ ] Test create with action='clone' (creates clone with user added)
- [ ] Test create with action='clone', invalid existing_sv_id (returns error)
- [ ] Test create with action='clone', existing_sv_id for different boat (returns error)
- [ ] Test clone includes all fields correctly
- [ ] Test clone sets previous_id correctly
- [ ] Test clone sets immutable to false
- [ ] Test populateOwnerNames function
- [ ] Test getAllSVsForBoat function

**Frontend (`client/src/views/account/svs.jsx`)**

- [ ] Test handleCreateSVs with no duplicates
- [ ] Test handleCreateSVs with single duplicate
- [ ] Test handleCreateSVs with multiple duplicates (sequential)
- [ ] Test modal shows correct boat/SV information
- [ ] Test modal radio button selection
- [ ] Test modal SV dropdown (when clone selected)
- [ ] Test handleDuplicateChoice with action='new'
- [ ] Test handleDuplicateChoice with action='clone'
- [ ] Test handleDuplicateChoice with action='cancel'
- [ ] Test clone failure fallback to 'new'
- [ ] Test formatSvDisplay function

### Integration Tests

- [ ] End-to-end: Select boat → Create SV → Duplicate detected → Modal → Clone → Success
- [ ] End-to-end: Select boat → Create SV → Duplicate detected → Modal → New → Success
- [ ] End-to-end: Select boat → Create SV → Duplicate detected → Modal → Cancel → Skipped
- [ ] Multiple boats selected, some duplicates → Process non-duplicates first
- [ ] Clone fails → Fallback to new → Success

### Edge Cases

- [ ] Multiple SVs for same boat (show all in modal)
- [ ] SV with many owners (display truncation)
- [ ] SV with no owners (shouldn't happen, but handle gracefully)
- [ ] Boat with no sail info (display gracefully)
- [ ] Network error during clone → Retry mechanism
- [ ] User closes modal without selecting → Treat as cancel
- [ ] Immutable SV in list (show indicator, disable delete)

---

## Translation Keys

### Client-Side (`client/src/locales/en.json`)

```json
{
  "account": {
    "svs": {
      "duplicate": {
        "modal": {
          "title": "Sailing Vessel Already Exists",
          "description": "A sailing vessel already exists for this boat. Please choose how you would like to proceed.",
          "boat_label": "Boat",
          "sail_label": "Sail",
          "owners_label": "Owner(s)",
          "existing_svs_label": "Existing Sailing Vessel(s)",
          "action": {
            "label": "What would you like to do?",
            "new": {
              "label": "Create New SV (I am the sole owner)",
              "description": "Create a new sailing vessel configuration with only you as the owner. If a non-immutable SV exists where you are an owner, it will be deleted."
            },
            "clone": {
              "label": "Clone Existing SV (Joint ownership)",
              "description": "Create a copy of an existing SV and add yourself as a joint owner. All configuration, certificates, and other owners will be copied."
            },
            "cancel": {
              "label": "Cancel (Selection mistake)",
              "description": "Do not create a sailing vessel for this boat."
            }
          },
          "existing_sv": {
            "label": "Select SV to clone",
            "placeholder": "Choose an existing sailing vessel"
          },
          "button": {
            "continue": "Continue",
            "cancel": "Cancel"
          }
        },
        "clone_fallback_warning": "Failed to clone SV. Creating new SV instead.",
        "clone_success": "Sailing vessel cloned successfully: {name}",
        "new_success": "New sailing vessel created successfully: {name}",
        "cancelled": "Skipped creating sailing vessel for {boatName}"
      }
    }
  }
}
```

### Server-Side (`server/locales/en.json`)

```json
{
  "sv": {
    "create": {
      "success": "Sailing vessel created successfully",
      "clone_success": "Sailing vessel cloned successfully",
      "clone_error": "Failed to clone sailing vessel",
      "new_success": "New sailing vessel created successfully",
      "invalid_action": "Invalid action. Must be 'new' or 'clone'.",
      "missing_existing_sv_id": "existing_sv_id is required when action is 'clone'.",
      "invalid_existing_sv": "The specified existing SV does not exist or does not belong to this boat.",
      "duplicate": "A sailing vessel already exists for this boat."
    }
  }
}
```

---

## Migration Considerations

### Database Changes

- **None required** - All changes are application-level

### Data Integrity

- Existing SVs remain unchanged
- New SVs follow same schema
- `previous_id` field already exists for tracking clones

### Backward Compatibility

- API remains backward compatible:
  - If `action` not provided → Returns duplicate response (existing behavior)
  - If `action` provided → New behavior
- Frontend gracefully handles missing `existing_svs` array in duplicate response

---

## Implementation Checklist

### Phase 1: Backend API Enhancement

- [ ] Add validation for `action` and `existing_sv_id` parameters
- [ ] Implement `handleNewSvAction` function
- [ ] Implement `handleCloneSvAction` function
- [ ] Implement `getAllSVsForBoat` function
- [ ] Implement `populateOwnerNames` helper function
- [ ] Modify `exports.create` to handle actions
- [ ] Add `exports.getByBoat` endpoint
- [ ] Add route for GET /api/sv/by-boat
- [ ] Add server-side translation keys
- [ ] Add error handling and fallback logic
- [ ] Write unit tests for backend functions

### Phase 2: Frontend Modal Implementation

- [ ] Add state management for duplicate queue
- [ ] Modify `handleCreateSVs` to queue duplicates
- [ ] Implement `fetchExistingSVsForBoat` function
- [ ] Implement `showDuplicateModal` function
- [ ] Implement `handleDuplicateChoice` function
- [ ] Implement `formatSvDisplay` helper function
- [ ] Add modal dialog with radio buttons
- [ ] Add conditional SV dropdown for clone action
- [ ] Add client-side translation keys
- [ ] Implement sequential modal processing
- [ ] Add loading states during processing
- [ ] Write unit tests for frontend functions

### Phase 3: Error Handling & Edge Cases

- [ ] Implement clone failure fallback
- [ ] Handle network errors gracefully
- [ ] Handle invalid existing_sv_id
- [ ] Handle immutable SV deletion attempt
- [ ] Add error toast notifications
- [ ] Add warning toast for fallback scenarios
- [ ] Test all error scenarios

### Phase 4: UI/UX Polish

- [ ] Format boat/SV display in modal
- [ ] Format owner names list
- [ ] Show immutable badge/indicator
- [ ] Handle long owner lists (truncation)
- [ ] Handle missing sail info gracefully
- [ ] Add loading indicators
- [ ] Test responsive design
- [ ] Test accessibility (keyboard navigation, screen readers)

### Phase 5: Testing & Documentation

- [ ] Write comprehensive unit tests
- [ ] Write integration tests
- [ ] Test all user flows
- [ ] Test error scenarios
- [ ] Update API documentation
- [ ] Update user documentation (if applicable)

---

## Final Clarifications Needed (Updated with Answers)

### 1. User Removal from Immutable SV Owners ✅ ANSWERED

- **A**: **DO NOT TOUCH immutable records** - Leave completely unchanged
- **A**: User can create new SV even if immutable SV exists
- **A**: User will own both immutable SV (if exists) and new SV after operation

### 2. Multiple Mutable SVs ✅ ANSWERED

- **A**: Delete **ALL** mutable SVs when user chooses "new" (sole ownership)
- **A**: Delete **NONE** when user chooses "clone" (joint ownership)
- **A**: User's radio button choice guides deletion behavior

### 3. Clone Validation ✅ ANSWERED

- **A**: **Re-validate on backend** - Always check SV exists and belongs to boat_id
- **A**: **Auto-fallback to 'new'** if validation fails
- **A**: Log warning, return success response (not error)

### 4. Progress Bar Display ✅ ANSWERED

- **A**: Show **ALL operations** (successful + duplicates + failed)
- **A**: Location: **Bottom of modal**, above buttons
- **A**: Format: "Processing X of Y" where Y = total boats selected

### 5. Modal Information Display ✅ ANSWERED

- **A**: Show **Boat Name** and **Sail (CC + NO)** only
- **A**: No description, certs, dates, or other details
- **A**: Show immutable badge/indicator if SV is immutable

### 6. Cancel All Notification ✅ ANSWERED

- **A**: Show **count only**: "Cancelled creating X sailing vessel(s)"
- **A**: No list of boat names
- **A**: No additional details

---

## Remaining Technical Questions (For 95%+ Confidence)

See `PLAN_REVIEW_CONFIDENCE.md` for detailed questions about:

1. User batch lookup method for owner names
2. Progress bar state tracking details
3. Immutable-only SVs edge case
4. Clone fallback user communication
5. Modal display format (dropdown vs radio)
6. Delete failure handling
7. Boat data field availability

---

## File Change Summary

### Files to Modify

1. **`server/controller/sv.controller.js`**

   - Modify `exports.create` function
   - Add `handleNewSvAction` function
   - Add `handleCloneSvAction` function
   - Add `getAllSVsForBoat` helper function
   - Add `populateOwnerNames` helper function
   - Add `exports.getByBoat` function

2. **`server/api/sv.route.js`**

   - Add GET route for `/api/sv/by-boat`

3. **`client/src/views/account/svs.jsx`**

   - Modify `handleCreateSVs` function
   - Add `showDuplicateModal` function
   - Add `handleDuplicateChoice` function
   - Add `fetchExistingSVsForBoat` function
   - Add `formatSvDisplay` helper function
   - Add state management for duplicate queue

4. **Translation Files**
   - `client/src/locales/en.json` (and other locales)
   - `server/locales/en.json` (and other locales)

### Files to Create

- None (all functionality fits in existing files)

### Files to Review (No Changes Expected)

- `server/model/sv.model.js` - Verify clone logic compatibility
- `server/model/user.model.js` - Verify user lookup for owner names
- `client/src/components/dialog/dialog.jsx` - Verify modal supports our needs
- `client/src/components/form/form.jsx` - Verify form supports conditional fields

---

## Risk Assessment

### Low Risk

- ✅ Modal UI implementation (standard pattern)
- ✅ Radio button selection (existing component)
- ✅ Translation keys (standard pattern)

### Medium Risk

- ⚠️ Sequential modal processing (state management complexity)
- ⚠️ Clone logic (ensure all fields copied correctly)
- ⚠️ Owner name population (performance with many owners)

### High Risk

- 🔴 Delete non-immutable SV (ensure proper cleanup)
- 🔴 Fallback from clone to new (user experience)
- 🔴 Multiple duplicates handling (state management)

### Mitigation Strategies

- **Sequential Processing**: Use queue-based state management with clear state machine
- **Clone Logic**: Comprehensive unit tests for all field copying
- **Owner Names**: Batch user lookups, add caching if needed
- **Delete SV**: Verify cleanup logic, add transaction if needed
- **Fallback**: Clear user communication via toast notifications
- **Multiple Duplicates**: Clear progress indicators, allow cancellation

---

## Success Criteria

### Functional Requirements

- ✅ User can create new SV when duplicate exists
- ✅ User can clone existing SV when duplicate exists
- ✅ User can cancel SV creation when duplicate exists
- ✅ Non-immutable SV is deleted when user chooses "new"
- ✅ Immutable SV is preserved when user chooses "new"
- ✅ Cloned SV includes all configuration from original
- ✅ Cloned SV has user added to owners list
- ✅ Multiple duplicates are handled sequentially
- ✅ Non-duplicates are processed before duplicates

### Non-Functional Requirements

- ✅ Modal displays correct boat and SV information
- ✅ Owner names are displayed correctly
- ✅ Error messages are clear and actionable
- ✅ Clone failures fallback gracefully
- ✅ Performance is acceptable (<2s for modal display)
- ✅ UI is accessible (keyboard navigation, screen readers)

---

## Key Design Decisions (Confirmed)

### 1. Owner Name Display

- ✅ Format: "First Last" only (e.g., "John Doe")
- ✅ Fallback: "Unknown" if name not available
- ✅ No truncation needed (not common occurrence)

### 2. Modal Behavior

- ✅ X button = Cancel ALL remaining duplicates
- ✅ Progress bar: Show "Processing X of Y" if total > 1
- ✅ No going back to previous duplicates

### 3. Clone Details

- ✅ Copy EVERYTHING: name, display, description, certs (deep copy), user_keys, user_ids structure
- ✅ Add current user to owners array (don't replace)
- ✅ Set previous_id to original SV id
- ✅ Set immutable to false (clones are always mutable)

### 4. Delete Behavior (New Action)

- ✅ Immutable SV: **DO NOT TOUCH** - Leave completely unchanged
- ✅ Mutable SV: Delete ALL mutable SVs where user is owner
- ✅ User's choice ("sole ownership" = new) guides deletion of mutable SVs
- ✅ User's choice ("joint ownership" = clone) means no deletions
- ✅ No notification to other owners

### 5. Performance

- ✅ No pagination initially
- ✅ No caching initially
- ✅ Can optimize later if needed

### 6. Validation

- ✅ Frontend: Validate existing_sv_id belongs to boat_id
- ✅ Frontend: Filter out SVs where user is already owner
- ✅ Backend: Re-validate all checks

### 7. Error Handling

- ✅ Clone fails → Fallback to 'new' with warning toast
- ✅ Delete fails → Continue with creation, log warning
- ✅ Remove from owners fails → Continue with creation, log warning

### 8. Processing Order

- ✅ Process non-duplicates first (show success toasts)
- ✅ Then process duplicates sequentially (one modal at a time)
- ✅ Show progress bar if multiple duplicates

---

## Next Steps

1. **Review this plan** - Ensure all requirements are captured
2. **Answer final clarification questions** - Resolve remaining ambiguities
3. **Approve implementation** - Give explicit command to proceed
4. **Implement Phase 1** - Backend API changes
5. **Implement Phase 2** - Frontend modal
6. **Implement Phase 3** - Error handling
7. **Implement Phase 4** - UI polish
8. **Implement Phase 5** - Testing

---

**END OF IMPLEMENTATION PLAN**
