# Final Approved Implementation Plan: Expand Edit Your Profile Dialog

## Confidence Rating: **98%**

## All Answers Integrated - Plan Finalized

Based on your comprehensive answers, all decisions are finalized and the plan is ready for implementation:

### ✅ Final Confirmed Decisions

1. **SV Description**: Optional field (not required)

2. **SV user_ids Structure**: Extensible object with multiple arrays

   - Structure: `{ owners: [string], crew: [string], sailmakers: [string], mechanics: [string], ... }`
   - Future-proof for additional role types
   - When creating SV, add current user to `user_ids.owners` array

3. **SV Duplicate Prevention**:

   - Unique SV = `boat_id` + `user_ids.owners` array combination
   - Can have multiple SVs for one physical BOAT with different owner combinations
   - Check: `boat_id` matches AND `user_ids.owners` contains current user
   - If duplicate: Return existing SV (don't create)

4. **Multiple SV Creation**:

   - Create all SVs in parallel (Promise.all)
   - Continue on failure (don't stop)
   - Simple toast alert for each result (success/failure)
   - Toast system handles stacking automatically

5. **SV Owner Removal**:

   - Handle in user controller when updating `user.sv_ids`
   - Remove user from `SV.user_ids.owners` array

6. **SV Immutable Flag**:

   - **CRITICAL**: Add `immutable` field to ALL entities (not just SV)
   - Add in `server/helper/mongo.js` `createOrdered()` function
   - Set default to `false` in helper
   - Add to all schema models right after `state` field
   - When season starts: Set via admin/console "Start New Season" feature (future)
   - When cloning immutable SV:
     - Copy all fields
     - Set `created_at` to now
     - Set `immutable` to `false`
     - Set `updated_at` to `null`
     - Set `previous_id` to original SV's ID

7. **previous_id Field**:

   - Add to ALL entities
   - Add in `server/helper/mongo.js` `createOrdered()` function
   - Add to all schema models right before `created_at` field
   - Links to previous version when cloning

8. **PATCH Immutable Record**:

   - Should NOT fail
   - Create NEW clone of object
   - Return status indicating clone was created
   - Clone gets new ID, `previous_id` links to original

9. **Search Implementation**:

   - **Boat**: Search by Name AND Sail No (case-insensitive)
   - **Org**: Search by Acronym (renamed from display) AND full Name (case-insensitive)
   - **Club**: Search by Acronym (renamed from display) AND full Name (case-insensitive)

10. **Schema Updates**:

    - Rename `display` → `acronym` in org and club models
    - **No migration needed** (clean slate - import code updated separately)
    - Add `immutable` field to all schemas (after `state`)
    - Add `previous_id` field to all schemas (before `created_at`)

11. **{prefix}\_key Properties**:

    - IMPORT ONLY - do not add to internal workings/APIs
    - Used only for data import/seeding
    - Not exposed in API responses

12. **Empty State Behavior**:

    - Show "Request to add {Entity}" button
    - Opens dialog with form fields
    - Collect as much information as possible
    - Submit request to admin (via API endpoint)
    - Admin reviews/edits/approves/rejects in admin/console (future)
    - User gets message on status (future)

13. **Multiple Selection UI**:

    - Checkboxes in Popover dropdown for selection
    - UI indication of multiple selections (visual feedback)
    - "Add Selected" [+] button to add selected items to user account
    - Button can be inside or outside Popover (design decision)

14. **Toast Alerts**:

    - Simple toast per result
    - Toast system handles stacking automatically
    - No need for manual queuing or delays

15. **Testing**: User will handle UI testing for CollapsibleSettingRow

---

## Updated Helper Function: createOrdered

**File**: `server/helper/mongo.js` (MODIFY)

**Current Function**: Sets `id`, `created_at`, `updated_at`, `rev`

**Updated Function**: Also sets `immutable` and `previous_id`

```javascript
async function createOrdered(idKey, Model, data) {
  // ... existing validation ...

  // Apply automatic values in schema order
  Object.keys(schemaPaths).forEach((key) => {
    // ... existing logic ...

    // Auto immutable (new)
    if (key === "immutable") {
      doc.immutable = false; // Default to false
      return;
    }

    // Auto previous_id (new)
    if (key === "previous_id") {
      doc.previous_id = null; // Default to null
      return;
    }

    // ... rest of existing logic ...
  });

  // ... rest of function ...
}
```

---

## Updated Schema Structure (All Entities)

**Standard Schema Order** (for all entities):

```javascript
{
    // Common entity fields
    id: String,
    key: String,
    rev: Number,
    type: String,
    state: String,
    immutable: Boolean,      // NEW - right after state
    previous_id: String,     // NEW - right before created_at
    created_at: Date,
    updated_at: Date,

    // Entity-specific fields
    ...
}
```

---

## Updated SV Schema

**File**: `server/model/mongo/sv.mongo.js` (MODIFY)

**user_ids Structure**:

```javascript
user_ids: {
    type: Object,
    required: false,
    // Structure: {
    //   owners: [user_id1, user_id2, ...],
    //   crew: [user_id3, user_id4, ...],
    //   sailmakers: [user_id5, ...],
    //   mechanics: [user_id6, ...],
    //   ... (extensible for future roles)
    // }
}
```

**Add Fields**:

```javascript
immutable: {
    type: Boolean,
    required: true,
    default: false
},
previous_id: {
    type: String,
    required: false
}
```

---

## Updated API Specifications

### POST /api/sv

**Request**:

```json
{
  "boat_id": "boat_123",
  "boat_key": "boat_key_value", // IMPORT ONLY, not used internally
  "description": "SV description" // Optional
}
```

**Implementation Logic**:

1. Verify boat exists
2. Check for duplicate SV: `boat_id` matches AND `user_ids.owners` contains current user
3. If duplicate: Return existing SV (status 200, don't create)
4. Generate name: `"SV ${boat.name}"`
5. Create SV with:
   - `user_ids: { owners: [req.user] }`
   - `immutable: false` (set by createOrdered)
   - `previous_id: null` (set by createOrdered)
6. Return created SV (status 201)

### PATCH /api/sv/:id

**Important**: Check `immutable` flag before allowing updates

**If `immutable === false`**:

- Allow normal update
- Return updated SV

**If `immutable === true`**:

- **DO NOT FAIL** - Create clone instead
- Clone all fields from original SV
- Set `created_at` to now
- Set `immutable` to `false`
- Set `updated_at` to `null`
- Set `previous_id` to original SV's ID
- Generate new `id` for clone
- Return cloned SV with status indicating clone was created

**Request**:

```json
{
  "user_ids": {
    "owners": ["user_789"],
    "crew": ["user_101"] // Can add crew, etc.
  }
}
```

**Response (if cloned)**:

```json
{
  "data": {
    "id": "sv_456",  // New ID
    "previous_id": "sv_123",  // Original SV ID
    "immutable": false,
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": null,
    ...
  },
  "cloned": true,  // Indicates clone was created
  "original_id": "sv_123"
}
```

### GET /api/user/svs

**Purpose**: Get user's SVs with populated boat data
**Response**:

```json
{
  "data": [
    {
      "sv": {
        "id": "sv_123",
        "boat_id": "boat_123",
        "name": "SV Boat Name",
        "user_ids": {
          "owners": ["user_456"],
          "crew": ["user_789"]
        },
        "immutable": false,
        "previous_id": null,
        ...
      },
      "boat": {
        "id": "boat_123",
        "name": "Boat Name",
        "hin": "HULL123",
        "sail_no": "SAIL456",
        ...
      }
    },
    ...
  ]
}
```

---

## Updated Search Specifications

### GET /api/boat

**Search Logic**:

- Search in `name` field (case-insensitive)
- Search in `sail_no` field (case-insensitive)
- Return boats matching either field

### GET /api/org

**Search Logic**:

- Search in `acronym` field (renamed from `display`) (case-insensitive)
- Search in `name` field (full name) (case-insensitive)
- Return orgs matching either field

### GET /api/club

**Search Logic**:

- Search in `acronym` field (renamed from `display`) (case-insensitive)
- Search in `name` field (full name) (case-insensitive)
- Return clubs matching either field

---

## Updated Component Specifications

### Entity Request Dialog

**Structure**:

```jsx
<Dialog open={requestDialogOpen} onOpenChange={setRequestDialogOpen}>
  <DialogContent>
    <DialogTitle>Request to add {entityName}</DialogTitle>
    <Form
      inputs={{
        name: {
          label: `${entityName} Name`,
          type: "text",
          required: true,
        },
        ...(entityType === "org" || entityType === "club"
          ? {
              acronym: {
                label: "Acronym",
                type: "text",
                required: false,
              },
            }
          : {}),
        description: {
          label: "Description",
          type: "textarea",
          required: false,
        },
        // ... other fields based on entity type
      }}
      url={`/api/${entityType}/request`}
      method="POST"
      callback={(res) => {
        viewContext.notification({
          description: "Request submitted. Admin will review.",
          variant: "success",
        });
        setRequestDialogOpen(false);
      }}
    />
  </DialogContent>
</Dialog>
```

### Multiple Selection UI

**Structure**:

```jsx
<Popover open={isOpen} onOpenChange={setIsOpen}>
  <PopoverTrigger asChild>
    <Button disabled={loading}>{loading ? <Spinner /> : "+"}</Button>
  </PopoverTrigger>
  <PopoverContent className="w-80">
    <Input
      placeholder="Search..."
      value={searchTerm}
      onChange={(e) => setSearchTerm(e.target.value)}
    />
    <div className="max-h-60 overflow-y-auto mt-2">
      {filteredItems.map((item) => (
        <div
          key={item.id}
          className="flex items-center p-2 hover:bg-slate-100 cursor-pointer"
          onClick={() => handleToggleSelection(item.id)}
        >
          <Checkbox
            checked={selectedIds.includes(item.id)}
            onCheckedChange={() => handleToggleSelection(item.id)}
          />
          <span className="ml-2">
            {entityType === "boat"
              ? `${item.sail_no} - ${item.name}`
              : item.name}
          </span>
        </div>
      ))}
      {filteredItems.length === 0 && (
        <div className="p-4 text-center">
          <p className="text-slate-500 mb-2">No {entity} found</p>
          <Button variant="outline" onClick={() => setRequestDialogOpen(true)}>
            Request to add {entity}
          </Button>
        </div>
      )}
    </div>
    {selectedIds.length > 0 && (
      <div className="border-t p-2 flex justify-between items-center">
        <span className="text-sm text-slate-500">
          {selectedIds.length} selected
        </span>
        <Button onClick={handleAddSelected} disabled={loading}>
          Add Selected
        </Button>
      </div>
    )}
  </PopoverContent>
</Popover>
```

---

## Updated File List

### Helper Files

1. **MODIFY**: `server/helper/mongo.js`
   - Update `createOrdered()` function
   - Add `immutable: false` default (right after `state` handling)
   - Add `previous_id: null` default (right before `created_at` handling)

### Schema Files (All Entities)

2. **MODIFY**: `server/model/mongo/sv.mongo.js`

   - Add `immutable` field (after `state`)
   - Add `previous_id` field (before `created_at`)
   - Document `user_ids` structure: `{ owners: [string], crew: [string], ... }`

3. **MODIFY**: `server/model/mongo/org.mongo.js`

   - Rename `display` → `acronym`
   - Add `immutable` field (after `state`)
   - Add `previous_id` field (before `created_at`)

4. **MODIFY**: `server/model/mongo/club.mongo.js`

   - Rename `display` → `acronym`
   - Add `immutable` field (after `state`)
   - Add `previous_id` field (before `created_at`)

5. **MODIFY**: `server/model/mongo/boat.mongo.js`

   - Add `immutable` field (after `state`)
   - Add `previous_id` field (before `created_at`)

6. **MODIFY**: All other entity models in `server/model/mongo/`
   - Add `immutable` field (after `state`)
   - Add `previous_id` field (before `created_at`)

### Backend Files

7. **CREATE**: `server/controller/sv.controller.js`

   - `exports.create` - Check duplicates (boat_id + owners), create SV
   - `exports.update` - Check immutable, clone if needed (don't fail)
   - `exports.get` - Get SV by ID
   - `exports.delete` - Delete SV (if not immutable)
   - `exports.list` - Get user's SVs with boat data

8. **CREATE**: `server/controller/org.controller.js`

   - `exports.list` - Search by `acronym` and `name`

9. **CREATE**: `server/controller/club.controller.js`

   - `exports.list` - Search by `acronym` and `name`

10. **CREATE**: `server/controller/boat.controller.js`

    - `exports.list` - Search by `name` and `sail_no`

11. **CREATE**: `server/controller/org.controller.js` (if request endpoint needed)

    - `exports.request` - Submit organization creation request

12. **CREATE**: `server/controller/club.controller.js` (if request endpoint needed)

    - `exports.request` - Submit club creation request

13. **CREATE**: `server/controller/boat.controller.js` (if request endpoint needed)

    - `exports.request` - Submit boat creation request

14. **MODIFY**: `server/controller/user.controller.js`

    - Add validation for `org_ids`, `club_ids`, `sv_ids`
    - Validate each ID exists
    - Remove invalid IDs, log: "Invalid reference to {Entity} was removed"
    - When removing from `sv_ids`, remove user from SV's `user_ids.owners`
    - Handle SV owner removal (check immutable flag)

15. **CREATE**: `server/api/org.route.js`

    - GET `/api/org` - List organizations
    - POST `/api/org/request` - Submit organization request (optional)

16. **CREATE**: `server/api/club.route.js`

    - GET `/api/club` - List clubs
    - POST `/api/club/request` - Submit club request (optional)

17. **CREATE**: `server/api/boat.route.js`

    - GET `/api/boat` - List boats
    - POST `/api/boat/request` - Submit boat request (optional)

18. **CREATE**: `server/api/sv.route.js`

    - POST `/api/sv` - Create SV
    - GET `/api/sv/:id` - Get SV
    - PATCH `/api/sv/:id` - Update SV (clone if immutable)
    - DELETE `/api/sv/:id` - Delete SV

19. **MODIFY**: `server/api/user.route.js`
    - GET `/api/user/svs` - Get user's SVs with boat data

### Frontend Files

20. **MODIFY**: `client/src/components/form/collapsible-setting-row/collapsible-setting-row.jsx`

    - Add `labelPosition` prop (default: 'left')
    - Implement label-above layout
    - **CRITICAL**: Maintain backward compatibility

21. **MODIFY**: `client/src/views/account/profile.jsx`

    - Use `CollapsibleSettingRow` with `labelPosition="above"`
    - Add address required validation
    - Update email/phone click handlers

22. **CREATE**: `client/src/views/account/organizations.jsx`

    - Searchable dropdown (by acronym and name)
    - Multiple selection with checkboxes
    - "Add Selected" button
    - Empty state with request dialog
    - Toast alerts

23. **CREATE**: `client/src/views/account/clubs.jsx`

    - Same as organizations

24. **CREATE**: `client/src/views/account/svs.jsx`

    - Searchable dropdown (by name and sail_no)
    - Format: "{sail_no} - {boat.name}"
    - Multiple selection with checkboxes
    - Parallel SV creation (Promise.all)
    - Toast alert for each result
    - Handle duplicate SV (return existing)
    - Empty state with request dialog

25. **MODIFY**: `client/src/routes/account.js`

    - Add three routes

26. **MODIFY**: `client/src/components/layout/account/account.jsx`

    - Add three nav items

27. **MODIFY**: `client/src/views/account/index.jsx`
    - Add three cards

### Locale Files

28. **MODIFY**: `client/src/locales/en/account/en_profile.json`

    - Add sections, address error

29. **CREATE**: `client/src/locales/en/account/en_organizations.json`

30. **CREATE**: `client/src/locales/en/account/en_clubs.json`

31. **CREATE**: `client/src/locales/en/account/en_svs.json`

32. **MODIFY**: `client/src/locales/en/en_nav.json`
    - Add nav items

---

## Updated Implementation Logic

### SV Creation with Duplicate Check

```javascript
// In sv.controller.js exports.create
async function create(req, res) {
  const { boat_id, boat_key, description } = req.body;
  const userId = req.user;

  // 1. Verify boat exists
  const boat = await boatModel.get({ id: boat_id });
  if (!boat) {
    throw { message: "Boat not found, check selection" };
  }

  // 2. Check for duplicate SV
  // Unique SV = boat_id + user_ids.owners contains current user
  const existingSv = await Sv.findOne({
    boat_id: boat_id,
    "user_ids.owners": { $in: [userId] },
  }).lean();

  if (existingSv) {
    // Return existing SV (don't create duplicate)
    return res.status(200).send({ data: existingSv });
  }

  // 3. Create new SV
  const svData = {
    boat_id: boat_id,
    boat_key: boat_key, // IMPORT ONLY, not used internally
    name: `SV ${boat.name}`,
    description: description || "", // Optional
    user_ids: { owners: [userId] }, // Start with owners array
  };

  // immutable and previous_id set by createOrdered helper
  const sv = await svModel.create(svData);
  return res.status(201).send({ data: sv });
}
```

### SV Update with Immutable Clone

```javascript
// In sv.controller.js exports.update
async function update(req, res) {
  const { id } = req.params;
  const updateData = req.body;

  // Get existing SV
  const sv = await svModel.get({ id });
  if (!sv) {
    throw { message: "SV not found" };
  }

  // Check immutable flag
  if (sv.immutable === true) {
    // Clone instead of failing
    const cloneData = {
      ...sv, // Copy all fields
      id: undefined, // Will be generated by createOrdered
      previous_id: sv.id, // Link to original
      immutable: false, // New clone is mutable
      created_at: new Date(), // New timestamp
      updated_at: null, // Reset
      rev: 0, // Reset revision
    };

    // Remove original id so createOrdered generates new one
    delete cloneData.id;

    // Create clone
    const clonedSv = await svModel.create(cloneData);

    return res.status(201).send({
      data: clonedSv,
      cloned: true,
      original_id: sv.id,
    });
  }

  // Normal update (immutable === false)
  const updated = await svModel.update({ id, data: updateData });
  return res.status(200).send({ data: updated });
}
```

### Multiple SV Creation (Frontend)

```javascript
// In svs.jsx
const handleAddSelected = async () => {
  const selectedBoats = boats.filter((b) => selectedBoatIds.includes(b.id));

  // Create all SVs in parallel
  const promises = selectedBoats.map((boat) =>
    axios
      .post("/api/sv", {
        boat_id: boat.id,
        boat_key: boat.key,
        description: "",
      })
      .then((res) => {
        // Check if duplicate was returned
        const isDuplicate = res.status === 200 && res.data.data.id;
        return {
          success: true,
          boat: boat.name,
          sv: res.data.data,
          duplicate: isDuplicate,
        };
      })
      .catch((err) => ({
        success: false,
        boat: boat.name,
        error: err.response?.data?.message || err.message,
      }))
  );

  const svResults = await Promise.all(promises);

  // Toast alert for each result (system handles stacking)
  svResults.forEach((result) => {
    if (result.success) {
      if (result.duplicate) {
        viewContext.notification({
          description: `SV already exists for ${result.boat}`,
          variant: "info",
        });
      } else {
        viewContext.notification({
          description: `SV created for ${result.boat}`,
          variant: "success",
        });
      }
    } else {
      viewContext.notification({
        description: `Failed to create SV for ${result.boat}: ${result.error}`,
        variant: "error",
      });
    }
  });

  // Refresh SV list
  await fetchUserSvs();
  // Clear selections
  setSelectedBoatIds([]);
};
```

---

## Remaining Questions (To Reach 98%+)

### Final Minor Clarifications

1. **Entity Request API Endpoint**:

   - Should we create POST `/api/{entity}/request` endpoints now?
   - Or defer until admin/console review feature is built?
   - What's the request data structure/storage?

2. **SV user_ids Extensibility**:

   - When adding crew/sailmakers/mechanics in future:
     - Should we add them via PATCH `/api/sv/:id` with updated `user_ids` object?
     - Or create separate endpoints like POST `/api/sv/:id/crew`?

3. **previous_id Usage**:

   - Should `previous_id` be exposed in API responses?
   - Should there be a GET endpoint to fetch previous version?
   - Or is it just for internal tracking?

4. **Immutable Field Visibility**:

   - Should `immutable` field be exposed in API responses?
   - Should users see if their SV is immutable?
   - Or is it admin-only information?

5. **Multiple Selection Checkbox Behavior**:

   - Should clicking the row toggle the checkbox?
   - Or only clicking the checkbox itself?
   - Should there be a "Select All" checkbox?

6. **Entity Request Form Fields**:
   - For Boat request: What fields should be collected? (name, hin, sail_no, sail_cc, description?)
   - For Org request: What fields? (name, acronym, description, email, phone, address?)
   - For Club request: What fields? (name, acronym, description, email, phone, address?)

---

## Updated Risk Assessment

### High Risk ⚠️

1. **createOrdered Helper Update**:

   - Adding `immutable` and `previous_id` affects ALL entities
   - Must ensure all schemas have these fields
   - **Mitigation**: Update helper first, then update schemas systematically

2. **Schema Updates Across All Entities**:

   - Adding `immutable` and `previous_id` to all schemas
   - Renaming `display` → `acronym` in org/club
   - **Mitigation**: Systematic update, test each entity

3. **SV Immutable Clone Logic**:

   - Complex cloning with field copying
   - Must preserve all fields correctly
   - **Mitigation**: Thorough testing, clear documentation

4. **CollapsibleSettingRow Extension**:
   - Must maintain backward compatibility
   - **Mitigation**: Default prop, user will handle testing

### Medium Risk

1. **Multiple SV Creation**:

   - Parallel creation with error handling
   - Toast management (handled by system)
   - **Mitigation**: Clear error handling

2. **Entity Request Feature**:
   - Need to design request flow
   - May need API endpoints
   - **Mitigation**: Simple request form, can defer admin review UI

### Low Risk ✅

1. **Search Implementation**: Straightforward MongoDB queries
2. **Profile Page Refactor**: Well-defined pattern
3. **Organizations/Clubs Pages**: Similar patterns

---

## Success Criteria (Final)

1. ✅ Profile page uses accordion with label-above, full-width display
2. ✅ Email/phone clicks open accordion (not mailto/tel)
3. ✅ Address field required with error message
4. ✅ Organizations page allows add/remove via searchable Popover dropdown
5. ✅ Clubs page allows add/remove via searchable Popover dropdown
6. ✅ SVs page allows claiming boat ownership (creates SV)
7. ✅ Boat dropdown shows "{sail_no} - {boat.name}" format
8. ✅ Search works: Boat (name, sail_no), Org/Club (acronym, name)
9. ✅ SV display shows boat name, hull number, hull number, sail number
10. ✅ SV removal removes from array AND removes owner from SV
11. ✅ SV duplicate prevention (boat_id + owners = unique)
12. ✅ Multiple SV creation in parallel with toast alerts
13. ✅ SV immutable flag added to schema (and all entities)
14. ✅ previous_id field added to all entities
15. ✅ PATCH immutable record creates clone (doesn't fail)
16. ✅ createOrdered helper sets immutable and previous_id
17. ✅ Backend validates IDs exist, removes invalid ones
18. ✅ Loading spinners show in buttons
19. ✅ Empty states show "Request to add {Entity}" dialog
20. ✅ Multiple selection UI with checkboxes and "Add Selected"Add Selected" button
21. ✅ CollapsibleSettingRow backward compatibility maintained
22. ✅ Schema updated: `display` → `acronym` for org/club
23. ✅ Navigation works (cards and menu items)

---

## Final Confidence Assessment

### Current Confidence: **99%**

### High Confidence Areas ✅

- Component extension approach (backward compatible, user testing)
- API endpoint patterns (follow existing structure)
- Frontend page implementations (clear patterns)
- SV creation flow (duplicate prevention well-defined)
- Search implementation (straightforward queries)
- Multiple SV creation (parallel with toasts)
- Validation logic (straightforward)
- createOrdered helper update (clear implementation)
- Schema updates (systematic approach)
- SV immutable clone logic (well-defined)
- Entity request stub (follow feedback pattern)
- SV user_ids extensibility (flexible JSON object)
- previous_id exposure (for undo/compare features)
- immutable field exposure (for padlock icon)
- Multiple selection UX (row or checkbox click)
- Entity request form fields (all specified)

### Medium Confidence Areas ⚠️

- None remaining

### Low Confidence Areas ❓

- None remaining

### All Questions Answered ✅

1. ✅ Entity Request: Stub for now (new entity like feedback)
2. ✅ SV user_ids: Stay flexible with JSON object
3. ✅ previous_id: Expose in API (for undo/compare UI)
4. ✅ immutable: Expose in API (for padlock icon UI)
5. ✅ Checkbox: Row or checkbox click works, no select all
6. ✅ Request Fields: BOAT (Brand, Model, Builder), ORG (Acronym, Name, Address), CLUB (Acronym, Name, Address)

---

## Implementation Readiness

**✅ READY FOR IMPLEMENTATION with 99% confidence.**

All questions answered. All technical decisions finalized.

The remaining 1% represents implementation details that will be resolved during coding:

- Exact UI styling for padlock icon
- Exact UI styling for undo/compare buttons (future)
- Exact form field layouts in request dialogs

**All critical technical decisions are finalized.**

---

## Entity Request Stub Implementation

**Pattern**: Follow feedback entity structure

**Files to Create** (stub for now):

1. **CREATE**: `server/model/mongo/entity_request.mongo.js`

   - Schema with: `id`, `rev`, `type` (boat_request, org_request, club_request), `state`, `immutable`, `previous_id`, `created_at`, `updated_at`
   - Fields: `entity_type` (boat/org/club), `data` (JSON object with request fields), `user_id`, `status` (pending/reviewed/approved/rejected)

2. **CREATE**: `server/controller/entity_request.controller.js`

   - `exports.create` - Create request (stub)
   - `exports.get` - Get requests (for admin, future)
   - `exports.update` - Update request status (for admin, future)

3. **CREATE**: `server/api/entity_request.route.js`
   - POST `/api/entity_request` - Submit request (stub)

**Request Data Structure**:

```javascript
{
  entity_type: 'boat' | 'org' | 'club',
  data: {
    // For boat: { brand, model, builder }
    // For org: { acronym, name, address }
    // For club: { acronym, name, address }
  }
}
```

---

## Final Implementation Checklist

### Phase 1: Helper & Schema Updates ✅

- [ ] Update `createOrdered()` helper (immutable, previous_id)
- [ ] Add `immutable` to all schemas (after `state`)
- [ ] Add `previous_id` to all schemas (before `created_at`)
- [ ] Rename `display` → `acronym` in org/club schemas

### Phase 2: Backend API Creation ✅

- [ ] Create org/club/boat/sv controllers
- [ ] Create org/club/boat/sv routes
- [ ] Implement search logic (boat: name/sail_no, org/club: acronym/name)
- [ ] Implement SV CRUD with duplicate check
- [ ] Implement SV immutable clone logic
- [ ] Create GET `/api/user/svs` endpoint
- [ ] Create entity_request stub (model/controller/route)

### Phase 3: Backend Validation ✅

- [ ] Update user controller validation
- [ ] Add ID existence validation
- [ ] Implement invalid ID removal with logging
- [ ] Implement SV owner removal logic

### Phase 4: Frontend Component Extension ✅

- [ ] Extend CollapsibleSettingRow with `labelPosition` prop
- [ ] Test backward compatibility

### Phase 5: Profile Page ✅

- [ ] Implement Profile page with accordion fields
- [ ] Add address required validation
- [ ] Update email/phone click handlers

### Phase 6: Organizations Page ✅

- [ ] Create page with searchable dropdown
- [ ] Implement multiple selection
- [ ] Implement request dialog (stub)
- [ ] Implement add/remove logic

### Phase 7: Clubs Page ✅

- [ ] Create page (same as organizations)

### Phase 8: SVs Page ✅

- [ ] Create page with searchable boat dropdown
- [ ] Implement multiple selection
- [ ] Implement parallel SV creation
- [ ] Implement request dialog (stub)
- [ ] Handle duplicate SV
- [ ] Display boat name, hin, sail_no

### Phase 9: Routes & Navigation ✅

- [ ] Add routes
- [ ] Add nav items
- [ ] Add index cards

### Phase 10: Locales ✅

- [ ] Update/create all locale files

---

## Next Steps

**✅ PLAN IS 99% COMPLETE AND READY FOR IMPLEMENTATION**

**Current Confidence: 99%**
**Target Confidence: 95%+ (EXCEEDED)**

**✅ ALL QUESTIONS ANSWERED**
**✅ ALL TECHNICAL DECISIONS FINALIZED**
**✅ PLAN READY FOR IMPLEMENTATION**

**Awaiting explicit command to proceed with implementation.**

---

**END OF FINAL APPROVED PLAN**
