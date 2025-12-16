# Final Plan Review: Expand Edit Your Profile Dialog

## Confidence Rating: **92%**

## All Answers Integrated

Based on your comprehensive answers, I've integrated all decisions into the plan:

### ✅ Final Confirmed Decisions

1. **API Endpoints**: `/api/{entityname}` pattern - all routes need to be created

   - `/api/org` - GET (list organizations)
   - `/api/club` - GET (list clubs, searchable)
   - `/api/boat` - GET (list boats, searchable)
   - `/api/sv` - POST, GET, PATCH, DELETE (full CRUD)

2. **SV Creation**: Link existing BOAT and USER

   - POST `/api/sv` with `boat_id` and current `user.id`
   - Auto-generate `name`: "SV {BOAT.name}"
   - `description` required (user-provided or default)

3. **SV Owners Structure**: Keep `user_ids` as Object

   - Structure: `{ owners: [user_id1, user_id2, ...] }` (array of owner IDs)
   - When creating SV, add current user to `user_ids.owners` array
   - When removing SV, remove user from `user_ids.owners` array

4. **SV Removal**: Use PATCH `/api/sv/:id` endpoint

   - Remove user from `SV.user_ids.owners` array
   - Remove `sv_id` from `user.sv_ids` array
   - Handle in user controller when updating `user.sv_ids`

5. **SV Display Data**: Create GET `/api/user/svs` endpoint

   - Returns SVs with populated boat data
   - Format: `Array<{ sv: SV, boat: BOAT }>`
   - Includes boat name, hin, sail_no for display

6. **Boat Dropdown**: Show 'Sail No' then 'Boat Name'

   - Format: "{sail_no} - {boat.name}"
   - Searchable/filterable (long lists)
   - Filter out boats user already owns

7. **ID Validation**: Validate each ID exists in database

   - Query database for each ID (typically < 3 per type)
   - Remove invalid IDs, log: "Invalid reference to {Entity} was removed"
   - Continue with valid IDs

8. **Loading Indicator**: Spinner in button

   - Show spinner when fetching/loading
   - Disable button during operations

9. **Search Functionality**: Searchable dropdowns

   - CLUBs and BOATs dropdowns are searchable
   - Organizations can be simple list (or searchable if needed)

10. **Empty States**: "Select {Entity}..." placeholder text

11. **Multiple Selection**: Users can select multiple items at once

    - For organizations/clubs: select multiple, add all at once
    - For boats: select multiple, create multiple SVs

12. **Error Messages**:

    - Invalid ID: "Invalid reference to {Entity} was removed"
    - SV creation failure: "Failed to define a complete Sailing Vessel"
    - Boat not found: "Boat not found, check selection"

13. **Component Extension**: Extend `CollapsibleSettingRow` with `labelPosition` prop
    - **CRITICAL**: Maintain backward compatibility (default: 'left')
    - Test existing usage still works

---

## Final API Specifications

### GET /api/org

**Purpose**: List available organizations
**Auth**: `auth.verify('user')`
**Response**:

```json
{
  "data": [
    { "id": "org_123", "name": "Organization Name", "description": "..." },
    ...
  ]
}
```

### GET /api/club

**Purpose**: List available clubs (searchable)
**Auth**: `auth.verify('user')`
**Query Params**: `?search=term` (optional)
**Response**:

```json
{
  "data": [
    { "id": "club_123", "name": "Club Name", "description": "..." },
    ...
  ]
}
```

### GET /api/boat

**Purpose**: List available boats (searchable)
**Auth**: `auth.verify('user')`
**Query Params**: `?search=term` (optional)
**Response**:

```json
{
  "data": [
    {
      "id": "boat_123",
      "name": "Boat Name",
      "hin": "HULL123",
      "sail_no": "SAIL456",
      "sail_cc": "US",
      ...
    },
    ...
  ]
}
```

### POST /api/sv

**Purpose**: Create SV linking BOAT and USER
**Auth**: `auth.verify('user')`
**Request**:

```json
{
  "boat_id": "boat_123",
  "boat_key": "boat_key_value",
  "description": "SV description" // Required
}
```

**Response**:

```json
{
  "data": {
    "id": "sv_123",
    "boat_id": "boat_123",
    "boat_key": "boat_key_value",
    "name": "SV Boat Name",  // Auto-generated
    "description": "SV description",
    "user_ids": {
      "owners": ["user_456"]  // Current user added
    },
    ...
  }
}
```

**Implementation Logic**:

1. Verify boat exists (GET boat by ID)
2. Check if SV already exists for this user+boat (prevent duplicates)
3. Generate name: `"SV ${boat.name}"`
4. Create SV with `user_ids: { owners: [req.user] }`
5. Return created SV

### GET /api/user/svs

**Purpose**: Get user's SVs with populated boat data
**Auth**: `auth.verify('user')`
**Response**:

```json
{
  "data": [
    {
      "sv": {
        "id": "sv_123",
        "boat_id": "boat_123",
        "name": "SV Boat Name",
        "user_ids": { "owners": ["user_456"] },
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

### PATCH /api/sv/:id

**Purpose**: Update SV (remove owner)
**Auth**: `auth.verify('user')`
**Request**:

```json
{
  "user_ids": {
    "owners": ["user_789"] // Updated owners array (removed current user)
  }
}
```

**Response**: Updated SV object

### GET /api/sv/:id

**Purpose**: Get single SV
**Auth**: `auth.verify('user')`
**Response**: SV object

### DELETE /api/sv/:id

**Purpose**: Delete SV
**Auth**: `auth.verify('user')`
**Response**: Deleted SV object

---

## Updated Component Specifications

### CollapsibleSettingRow Extension

**File**: `client/src/components/form/collapsible-setting-row/collapsible-setting-row.jsx`

**New Prop**:

```typescript
labelPosition?: 'above' | 'left'  // Default: 'left' (backward compatible)
```

**Implementation**:

- Add prop with default value `'left'`
- When `labelPosition === 'above'`:
  - Render label above display field
  - Display field full width
  - Detail fields still horizontal (label left, input right)
- When `labelPosition === 'left'` (default):
  - Current behavior unchanged
- **CRITICAL**: Test all existing usages still work

### Profile Page Usage

```jsx
<CollapsibleSettingRow
  labelPosition="above"  // NEW PROP
  control={control}
  displayField={{
    name: 'name',
    labelKey: 'account.profile.form.name.label',
    required: true
  }}
  detailFields={[...]}
  // ... other props
/>
```

### Dropdown Component (Popover with Search)

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
          onClick={() => handleSelect(item)}
          className="cursor-pointer hover:bg-slate-100 p-2"
        >
          {/* Format based on entity type */}
          {entityType === "boat" ? `${item.sail_no} - ${item.name}` : item.name}
        </div>
      ))}
    </div>
  </PopoverContent>
</Popover>
```

**Multiple Selection**:

- For organizations/clubs: Use checkboxes, "Add Selected" button
- For boats: Use checkboxes, "Add Selected" button (creates multiple SVs)

---

## Updated File List with Implementation Details

### Frontend Files

1. **MODIFY**: `client/src/components/form/collapsible-setting-row/collapsible-setting-row.jsx`

   - Add `labelPosition` prop (default: 'left')
   - Implement label-above layout when `labelPosition === 'above'`
   - **CRITICAL**: Ensure backward compatibility
   - Test existing usages

2. **MODIFY**: `client/src/views/account/profile.jsx`

   - Use `CollapsibleSettingRow` with `labelPosition="above"`
   - Add address required validation
   - Update email/phone click handlers (open accordion, not mailto/tel)
   - Implement form submission

3. **CREATE**: `client/src/views/account/organizations.jsx`

   - Popover with "+" button (spinner when loading)
   - Searchable list (optional, can be simple)
   - Multiple selection with checkboxes
   - "Add Selected" button
   - List of user's organizations with remove buttons
   - Empty state: "Select Organization..."

4. **CREATE**: `client/src/views/account/clubs.jsx`

   - Same as organizations
   - **Searchable** dropdown (long lists)
   - Empty state: "Select Club..."

5. **CREATE**: `client/src/views/account/svs.jsx`

   - Popover with "+" button showing boats
   - **Searchable** dropdown (long lists)
   - Format: "{sail_no} - {boat.name}"
   - Multiple selection with checkboxes
   - "Add Selected" button creates multiple SVs
   - Display: Boat Name, Hull Number, Sail Number
   - Remove SV functionality
   - Empty state: "Select Boat..."

6. **MODIFY**: `client/src/routes/account.js`

   - Import Organizations, Clubs, SVs components
   - Add three route objects

7. **MODIFY**: `client/src/components/layout/account/account.jsx`

   - Add three nav items to subnav array

8. **MODIFY**: `client/src/views/account/index.jsx`
   - Add three Card components

### Backend Files

9. **CREATE**: `server/api/org.route.js`

   - GET `/api/org` - List organizations
   - Use template pattern from `server/template/api.js`
   - Auth: `auth.verify('user')`

10. **CREATE**: `server/api/club.route.js`

    - GET `/api/club` - List clubs (with search query param)
    - Auth: `auth.verify('user')`

11. **CREATE**: `server/api/boat.route.js`

    - GET `/api/boat` - List boats (with search query param)
    - Auth: `auth.verify('user')`

12. **CREATE**: `server/api/sv.route.js`

    - POST `/api/sv` - Create SV
    - GET `/api/sv/:id` - Get SV
    - PATCH `/api/sv/:id` - Update SV
    - DELETE `/api/sv/:id` - Delete SV
    - Auth: `auth.verify('user')`

13. **CREATE**: `server/controller/org.controller.js`

    - `exports.list` - Get all organizations
    - Filter/search logic

14. **CREATE**: `server/controller/club.controller.js`

    - `exports.list` - Get all clubs
    - Filter/search logic

15. **CREATE**: `server/controller/boat.controller.js`

    - `exports.list` - Get all boats
    - Filter/search logic

16. **CREATE**: `server/controller/sv.controller.js`

    - `exports.create` - Create SV, link BOAT + USER
    - `exports.get` - Get SV by ID
    - `exports.update` - Update SV (remove owner)
    - `exports.delete` - Delete SV
    - `exports.list` - Get user's SVs with boat data (for GET /api/user/svs)

17. **MODIFY**: `server/model/mongo/sv.mongo.js`

    - Document `user_ids` structure: `{ owners: [string] }`
    - Add helper methods if needed:
      - `addOwner(userId)`
      - `removeOwner(userId)`

18. **MODIFY**: `server/controller/user.controller.js`

    - Add validation for `org_ids`, `club_ids`, `sv_ids` arrays
    - Validate each ID exists in respective collection
    - Remove invalid IDs, log: "Invalid reference to {Entity} was removed"
    - When removing from `sv_ids`, also remove user from SV's `user_ids.owners`
    - Handle SV owner removal via PATCH `/api/sv/:id`

19. **CREATE/MODIFY**: `server/api/user.route.js` (add new endpoint)
    - GET `/api/user/svs` - Get user's SVs with populated boat data
    - Calls `sv.controller.list` with user context

### Locale Files

20. **MODIFY**: `client/src/locales/en/account/en_profile.json`

    - Add sections, address error message

21. **CREATE**: `client/src/locales/en/account/en_organizations.json`

    - Title, description, button, help text, empty state

22. **CREATE**: `client/src/locales/en/account/en_clubs.json`

    - Title, description, button, help text, empty state

23. **CREATE**: `client/src/locales/en/account/en_svs.json`

    - Title, description, button, help text, empty state
    - Error messages: SV creation failure, boat not found

24. **MODIFY**: `client/src/locales/en/en_nav.json`
    - Add nav items for organizations, clubs, svs

---

## Implementation Order (Updated)

### Phase 1: Component Extension (Foundation - CRITICAL)

1. Extend `CollapsibleSettingRow` with `labelPosition` prop
2. **Test backward compatibility** - verify all existing usages still work
3. Test label-above layout
4. Refactor Profile page to use new prop

### Phase 2: Backend API Creation

5. Create org/club/boat/sv controllers
6. Create org/club/boat/sv routes
7. Implement GET endpoints (list with search for club/boat)
8. Implement SV CRUD operations
9. Create GET `/api/user/svs` endpoint
10. Test all API endpoints

### Phase 3: Backend Validation

11. Update user controller validation
12. Add ID existence validation
13. Implement invalid ID removal with logging
14. Implement SV owner removal logic
15. Test validation

### Phase 4: Profile Page

16. Implement Profile page with accordion fields
17. Add address required validation
18. Update email/phone click handlers
19. Test form submission

### Phase 5: Organizations Page

20. Create Organizations page
21. Implement Popover dropdown (simple list, optional search)
22. Implement multiple selection
23. Implement add/remove logic
24. Test

### Phase 6: Clubs Page

25. Create Clubs page
26. Implement **searchable** Popover dropdown
27. Implement multiple selection
28. Test

### Phase 7: SVs Page (Most Complex)

29. Create SVs page
30. Implement **searchable** boat dropdown (format: "{sail_no} - {name}")
31. Implement multiple boat selection
32. Implement SV creation flow (POST /api/sv)
33. Implement SV display (GET /api/user/svs)
34. Implement SV removal (remove from array + remove owner)
35. Test

### Phase 8: Polish

36. Add loading spinners in buttons
37. Add error handling with specific messages
38. Add empty states ("Select {Entity}...")
39. Final testing

---

## Remaining Questions (To Reach 95%+)

### Minor Clarifications

1. **SV Description Field**:

   - Is `description` required when creating SV?
   - If required, should it be user-provided or can we auto-generate a default?
   - What should the default description be if auto-generated?

2. **SV Duplicate Prevention**:

   - When checking if SV already exists for user+boat:
     - Should we check by `user_ids.owners` contains user AND `boat_id` matches?
     - Or is there a unique constraint?
   - What should happen if duplicate detected? Show error or return existing SV?

3. **Multiple SV Creation**:

   - When user selects multiple boats and clicks "Add Selected":
     - Should we create all SVs in parallel (Promise.all)?
     - Or sequentially (one at a time)?
     - What if one fails - continue with others or stop?

4. **SV Owner Removal**:

   - When removing user from `sv_ids`:
     - Should we call PATCH `/api/sv/:id` to remove owner?
     - Or handle it directly in user controller?
     - What if user is the only owner - delete SV or keep it?

5. **Search Implementation**:

   - For searchable dropdowns (clubs/boats):
     - Should search filter by name only, or name + description?
     - Case-sensitive or case-insensitive?
     - Should it search across all fields or specific ones?

6. **Empty State Behavior**:

   - When dropdown is empty (no items match search):
     - Show "No {Entity} found" message?
     - Or just empty list?

7. **CollapsibleSettingRow Testing**:
   - Should I test all existing usages manually, or is there a test suite?
   - Are there specific files/views I should verify still work?

---

## Risk Assessment (Updated)

### High Risk ⚠️

1. **CollapsibleSettingRow Extension**:

   - **CRITICAL**: Must maintain backward compatibility
   - Existing UI relies on this component
   - **Mitigation**: Default prop value, thorough testing

2. **API Route Creation**:

   - All 4 routes need to be created (org, club, boat, sv)
   - Must follow existing patterns
   - **Mitigation**: Use template, follow existing route patterns

3. **SV Creation Flow**:
   - Complex entity relationship
   - Duplicate prevention logic
   - **Mitigation**: Clear API design, error handling

### Medium Risk

1. **Backend Validation Performance**:

   - Validating IDs exists (though < 3 per type, should be fine)
   - **Mitigation**: Batch queries if needed

2. **Multiple SV Creation**:
   - Handling partial failures
   - **Mitigation**: Clear error handling, user feedback

### Low Risk ✅

1. **Profile Page Refactor**: Well-defined pattern exists
2. **Organizations/Clubs Pages**: Straightforward implementation
3. **Routes/Navigation**: Simple additions

---

## Success Criteria (Updated)

1. ✅ Profile page uses accordion with label-above, full-width display
2. ✅ Email/phone clicks open accordion (not mailto/tel)
3. ✅ Address field required with error message
4. ✅ Organizations page allows add/remove via Popover dropdown
5. ✅ Clubs page allows add/remove via **searchable** Popover dropdown
6. ✅ SVs page allows claiming boat ownership (creates SV)
7. ✅ Boat dropdown shows "{sail_no} - {boat.name}" format
8. ✅ SV display shows boat name, hull number, sail number
9. ✅ SV removal removes from array AND removes owner from SV
10. ✅ Backend validates IDs exist, removes invalid ones with logging
11. ✅ Loading spinners show in buttons during operations
12. ✅ Error messages are specific and helpful
13. ✅ Empty states show "Select {Entity}..." placeholder
14. ✅ Multiple selection works for all entity types
15. ✅ **CollapsibleSettingRow backward compatibility maintained**
16. ✅ Navigation works (cards and menu items)

---

## Final Confidence Assessment

### Current Confidence: **92%**

### High Confidence Areas ✅

- Component extension approach (backward compatible)
- API endpoint patterns (follow existing structure)
- Frontend page implementations (clear patterns)
- SV creation flow (well-defined)
- Validation logic (straightforward)

### Medium Confidence Areas ⚠️

- SV duplicate prevention (needs clarification Q2)
- Multiple SV creation error handling (needs clarification Q3)
- Search implementation details (needs clarification Q5)

### Low Confidence Areas ❓

- SV description requirement (needs clarification Q1)
- Empty state behavior (needs clarification Q6)
- Testing approach for CollapsibleSettingRow (needs clarification Q7)

---

## Next Steps

**To reach 95%+ confidence, please answer or waive the 7 Minor Clarification Questions above.**

Once answered/waived, I will:

1. Finalize all API implementations
2. Complete component specifications
3. Provide detailed code implementation steps
4. Update confidence rating to 95%+
5. **Ready for implementation**

**Current Confidence: 92%**
**Target Confidence: 95%+**

---

**END OF FINAL REVIEW**
