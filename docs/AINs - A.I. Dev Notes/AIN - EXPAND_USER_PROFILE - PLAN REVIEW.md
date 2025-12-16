# Plan Review: Expand Edit Your Profile Dialog

## Confidence Rating: **85%**

## Answers Integrated

Based on your answers, I've updated the plan with the following:

### ✅ Confirmed Decisions

1. **API Endpoints**: Use `/api/{entityname}` pattern

   - `/api/org` - Get available organizations
   - `/api/club` - Get available clubs
   - `/api/boat` - Get available boats
   - `/api/sv` - Create/read/update/delete SVs

2. **SV Creation API**: Needs to be designed (see questions below)

3. **SV Display**: Show 'Boat Name', 'Hull Number', 'Sail Number'

   - Boat Name: From `BOAT.name` (via `SV.boat_id`)
   - Hull Number: From `BOAT.hin` (via `SV.boat_id`)
   - Sail Number: From `BOAT.sail_no` (via `SV.boat_id`)

4. **SV Removal**:

   - Remove from `user.sv_ids` array
   - Remove user from `SV.user_ids` (owners array) - **NEEDS SCHEMA UPDATE**

5. **Dropdown Component**: Use Radix UI Popover with custom content

   - Popover component exists: `Popover`, `PopoverTrigger`, `PopoverContent`
   - Can contain a searchable list or Select component inside

6. **Address Requirement**: Required for all users (frontend + backend validation)

7. **Component Approach**: Extend `CollapsibleSettingRow` with `labelPosition` prop

   - `labelPosition: 'above' | 'left'` (default: 'left')
   - Reuse existing component logic

8. **Backend Validation**: Validate IDs exist in respective collections

   - Remove invalid IDs, log error, continue with valid ones

9. **Error Handling**: Remove invalid IDs, log and continue

10. **Loading States**: Show subtle loading indicators during fetches

---

## Updated Implementation Details

### Component Changes

#### CollapsibleSettingRow Extension

**File**: `client/src/components/form/collapsible-setting-row/collapsible-setting-row.jsx` (MODIFY)

**New Prop**:

```typescript
labelPosition?: 'above' | 'left'  // Default: 'left'
```

**Behavior**:

- When `labelPosition === 'above'`:
  - Label renders above display field
  - Display field is full width
  - Detail fields still use horizontal layout (label left, input right)
- When `labelPosition === 'left'` (default):
  - Current behavior (label left, display field right)

#### Profile Page Usage

**File**: `client/src/views/account/profile.jsx` (MODIFY)

```jsx
<CollapsibleSettingRow
  labelPosition="above"  // NEW PROP
  control={control}
  displayField={{...}}
  detailFields={[...]}
  // ... other props
/>
```

### API Endpoints

#### GET /api/org

**Purpose**: Fetch available organizations
**Response**: `{ data: Array<{ id, name, description, ... }> }`

#### GET /api/club

**Purpose**: Fetch available clubs
**Response**: `{ data: Array<{ id, name, description, ... }> }`

#### GET /api/boat

**Purpose**: Fetch available boats
**Response**: `{ data: Array<{ id, name, hin, sail_no, sail_cc, ... }> }`

#### POST /api/sv (TO BE DESIGNED)

**Purpose**: Create SV when user claims boat ownership
**Request**:

```typescript
{
  boat_id: string;        // Required
  boat_key: string;       // Required
  name: string;           // Required (SV name, could be boat name)
  description: string;    // Required
  user_ids?: {            // Optional - will add current user as owner
    owner?: string;       // Current user ID
  }
}
```

**Response**: `{ data: { id, boat_id, name, user_ids, ... } }`

#### PATCH /api/sv/:id (TO BE DESIGNED)

**Purpose**: Update SV (e.g., remove owner)
**Request**:

```typescript
{
  user_ids?: object;      // Updated owners object
  // ... other SV fields
}
```

### SV Schema Update Required

**File**: `server/model/mongo/sv.mongo.js` (MODIFY)

**Current**: `user_ids: { type: Object }`
**Needed**: Clarify structure - should it be:

- Option A: `{ owners: [user_id1, user_id2, ...] }` (array of owner IDs)
- Option B: `{ owner: user_id, co_owner: user_id2, ... }` (object with roles)
- Option C: Keep as Object but document structure

**Recommendation**: Option A - `{ owners: [string] }` array for simplicity

### Dropdown Implementation

**Component**: Popover with searchable list inside

**Structure**:

```jsx
<Popover>
  <PopoverTrigger asChild>
    <Button>+</Button>
  </PopoverTrigger>
  <PopoverContent>
    <Input placeholder="Search..." /> {/* Optional search */}
    <div className="max-h-60 overflow-y-auto">
      {availableItems.map((item) => (
        <div
          key={item.id}
          onClick={() => handleAdd(item.id)}
          className="cursor-pointer hover:bg-slate-100"
        >
          {item.name}
        </div>
      ))}
    </div>
  </PopoverContent>
</Popover>
```

### SV Display Implementation

**File**: `client/src/views/account/svs.jsx`

**Data Fetching**:

1. Fetch user with `sv_ids`: `GET /api/user`
2. For each `sv_id`, fetch SV: `GET /api/sv/:id` (or batch endpoint)
3. For each SV, fetch BOAT: `GET /api/boat/:id` (or join in backend)

**Display**:

```jsx
{
  svs.map((sv) => (
    <SettingRow key={sv.id}>
      <div>
        <div>{sv.boat.name}</div> {/* Boat Name */}
        <div>Hull: {sv.boat.hin}</div> {/* Hull Number */}
        <div>Sail: {sv.boat.sail_no}</div> {/* Sail Number */}
      </div>
      <Button onClick={() => handleRemove(sv.id)}>Remove</Button>
    </SettingRow>
  ));
}
```

**Optimization**: Consider backend endpoint that returns SVs with populated boat data:

- `GET /api/user/svs` → Returns `Array<{ sv: SV, boat: BOAT }>`

---

## Remaining Questions (To Reach 95%+ Confidence)

### Critical Questions (Must Answer)

1. **SV Creation API Design**:

   - What fields are required when creating SV?
   - Should `name` be auto-generated from boat name, or user-provided?
   - Should `description` be required, or can it be optional/auto-generated?
   - What should happen if SV already exists for this user+boat combination?

2. **SV Owners Array Structure**:

   - Should `user_ids` be changed to `owners: [string]` array?
   - Or keep as Object with structure like `{ owners: [user_id1, user_id2] }`?
   - Do we need to track roles (owner, co_owner) or just list of owner IDs?

3. **SV Removal API**:

   - Should we create `PATCH /api/sv/:id` endpoint to remove owner?
   - Or handle it in user controller when updating `user.sv_ids`?
   - What if removing last owner - delete SV entirely or keep it?

4. **SV Display Data Fetching**:

   - Should we create a batch endpoint `GET /api/user/svs` that returns SVs with populated boat data?
   - Or fetch SVs individually and then fetch boats?
   - Or join in backend and return complete data?

5. **Boat Selection in Dropdown**:

   - Should dropdown show boat name only, or name + hin + sail_no?
   - Should it be searchable/filterable?
   - Should it show boats user already owns (filter them out)?

6. **Invalid ID Handling**:

   - When validating `org_ids`, `club_ids`, `sv_ids` arrays:
     - Should we query database for each ID to verify existence?
     - Or just validate format (UUID/string pattern)?
     - What's the performance consideration if user has many IDs?

7. **Loading Indicator Style**:
   - What constitutes "subtle" loading indicator?
   - Should it be:
     - Skeleton loaders?
     - Spinner in button?
     - Progress bar?
     - Disabled state with text?

### Nice-to-Have Questions (Can Be Decided During Implementation)

8. **Search Functionality**:

   - Should dropdowns be searchable for organizations/clubs/boats?
   - Or simple scrollable list?

9. **Empty States**:

   - What should display when user has no organizations/clubs/SVs?
   - Should there be a call-to-action?

10. **Bulk Operations**:

    - Can users add multiple items at once, or one at a time?

11. **SV Name Generation**:

    - If SV name is auto-generated, what format?
    - `"{boat.name} - {user.name}"` or just `"{boat.name}"`?

12. **Error Messages**:
    - What specific error messages for:
      - Invalid ID in array
      - SV creation failure
      - Boat not found

---

## Updated File List

### Frontend Files

1. **MODIFY**: `client/src/components/form/collapsible-setting-row/collapsible-setting-row.jsx`

   - Add `labelPosition` prop
   - Implement label-above layout

2. **MODIFY**: `client/src/views/account/profile.jsx`

   - Use `CollapsibleSettingRow` with `labelPosition="above"`
   - Add address required validation
   - Update email/phone click handlers

3. **CREATE**: `client/src/views/account/organizations.jsx`

   - Popover with "+" button
   - List of user's organizations
   - Add/remove functionality

4. **CREATE**: `client/src/views/account/clubs.jsx`

   - Same as organizations

5. **CREATE**: `client/src/views/account/svs.jsx`

   - Popover with "+" button (shows boats)
   - SV creation on boat selection
   - Display boat name, hin, sail_no
   - Remove SV functionality

6. **MODIFY**: `client/src/routes/account.js`

   - Add three new routes

7. **MODIFY**: `client/src/components/layout/account/account.jsx`

   - Add three nav items

8. **MODIFY**: `client/src/views/account/index.jsx`
   - Add three cards

### Backend Files

9. **MODIFY**: `server/model/mongo/sv.mongo.js`

   - Update `user_ids` structure (or document it)
   - Add helper methods for owner management

10. **CREATE**: `server/api/sv.route.js` (if doesn't exist)

    - POST `/api/sv` - Create SV
    - GET `/api/sv/:id` - Get SV
    - PATCH `/api/sv/:id` - Update SV (remove owner)
    - DELETE `/api/sv/:id` - Delete SV

11. **CREATE**: `server/controller/sv.controller.js` (if doesn't exist)

    - Implement CRUD operations
    - Handle owner management

12. **MODIFY**: `server/controller/user.controller.js`

    - Add validation for `org_ids`, `club_ids`, `sv_ids`
    - Validate IDs exist in collections
    - Remove invalid IDs, log errors
    - Handle SV owner removal when removing from `sv_ids`

13. **CREATE/VERIFY**: `server/api/org.route.js` (if doesn't exist)

    - GET `/api/org` - List organizations

14. **CREATE/VERIFY**: `server/api/club.route.js` (if doesn't exist)

    - GET `/api/club` - List clubs

15. **CREATE/VERIFY**: `server/api/boat.route.js` (if doesn't exist)
    - GET `/api/boat` - List boats

### Locale Files

16. **MODIFY**: `client/src/locales/en/account/en_profile.json`

    - Add sections, address error

17. **CREATE**: `client/src/locales/en/account/en_organizations.json`

18. **CREATE**: `client/src/locales/en/account/en_clubs.json`

19. **CREATE**: `client/src/locales/en/account/en_svs.json`

20. **MODIFY**: `client/src/locales/en/en_nav.json`
    - Add nav items

---

## Implementation Risks

### High Risk

1. **SV Creation Flow**: Complex entity relationship needs careful design
2. **API Endpoint Creation**: May need to create org/club/boat/sv routes if they don't exist
3. **SV Schema Update**: Changing `user_ids` structure may require migration

### Medium Risk

1. **CollapsibleSettingRow Extension**: Need to ensure backward compatibility
2. **Backend Validation**: Performance consideration for validating many IDs
3. **Data Fetching**: SV display may need optimized endpoint

### Low Risk

1. **Profile Page Refactor**: Well-defined pattern exists
2. **Organizations/Clubs Pages**: Straightforward implementation
3. **Routes/Navigation**: Simple additions

---

## Updated Implementation Order

### Phase 1: Component Extension (Foundation)

1. Extend `CollapsibleSettingRow` with `labelPosition` prop
2. Test both label positions work correctly
3. Refactor Profile page to use new prop

### Phase 2: Backend Schema & API Design

4. Design SV creation API (answer Q1)
5. Update SV schema for owners array (answer Q2)
6. Create/verify API routes for org/club/boat/sv
7. Update user controller validation

### Phase 3: Profile Page

8. Implement Profile page with accordion fields
9. Add address required validation
10. Update email/phone click handlers
11. Test form submission

### Phase 4: Organizations Page

12. Create Organizations page
13. Implement Popover dropdown
14. Implement add/remove logic
15. Test

### Phase 5: Clubs Page

16. Create Clubs page (copy Organizations)
17. Test

### Phase 6: SVs Page (Most Complex)

18. Design SV creation flow (based on Q1 answer)
19. Create SVs page
20. Implement boat selection → SV creation
21. Implement SV display with boat data
22. Implement SV removal (remove from array + remove owner)
23. Test

### Phase 7: Polish

24. Add loading indicators
25. Add error handling
26. Add empty states
27. Final testing

---

## Testing Strategy

### Unit Tests

- CollapsibleSettingRow with labelPosition prop
- Profile form validation (address required)
- SV creation logic
- ID validation logic

### Integration Tests

- Profile page form submission
- Organizations add/remove
- Clubs add/remove
- SV creation and removal
- Backend validation of ID arrays

### E2E Tests

- User edits profile with accordion fields
- User adds organization via dropdown
- User claims boat ownership (creates SV)
- User removes SV (removes from array and owners)

---

## Success Criteria

1. ✅ Profile page uses accordion with label-above, full-width display
2. ✅ Email/phone clicks open accordion (not mailto/tel)
3. ✅ Address field required with error message
4. ✅ Organizations page allows add/remove via Popover dropdown
5. ✅ Clubs page allows add/remove via Popover dropdown
6. ✅ SVs page allows claiming boat ownership (creates SV)
7. ✅ SV display shows boat name, hull number, sail number
8. ✅ SV removal removes from array AND removes owner from SV
9. ✅ Backend validates IDs exist, removes invalid ones
10. ✅ All pages save changes correctly
11. ✅ Loading indicators show during fetches
12. ✅ Navigation works (cards and menu items)

---

## Next Steps

**To reach 95%+ confidence, please answer the 7 Critical Questions above.**

Once answered, I will:

1. Update the implementation plan with specific API designs
2. Update SV schema structure
3. Finalize component interfaces
4. Provide detailed code implementation steps
5. Update confidence rating to 95%+

**Current Confidence: 85%**
**Target Confidence: 95%+**

---

**END OF PLAN REVIEW**
