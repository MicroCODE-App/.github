# Ready for Implementation: Expand Edit Your Profile Dialog

## Confidence Rating: **99%**

## ✅ All Questions Answered - Plan Finalized

All decisions are finalized and the plan is ready for implementation.

---

## Final Answers Summary

1. **Entity Request**: Stub for now (new entity like feedback)
2. **SV user_ids**: Stay flexible with JSON object
3. **previous_id**: Expose in API (for undo/compare UI)
4. **immutable**: Expose in API (for padlock icon UI)
5. **Checkbox**: Row or checkbox click works, no select all
6. **Request Fields**:
   - BOAT: Brand, Model, Builder
   - ORG: Acronym, Name, Address
   - CLUB: Acronym, Name, Address

---

## Complete Implementation Specifications

### 1. Helper Function Update

**File**: `server/helper/mongo.js`

**Update `createOrdered()` function**:

```javascript
// Add after 'rev' handling, before schema defaults:

// Auto immutable (right after state)
if (key === "immutable") {
  doc.immutable = false; // Default to false
  return;
}

// Auto previous_id (right before created_at)
if (key === "previous_id") {
  doc.previous_id = null; // Default to null
  return;
}
```

### 2. Schema Updates (All Entities)

**Standard Schema Order** (apply to ALL entities):

```javascript
{
    id: String,
    key: String,
    rev: Number,
    type: String,
    state: String,
    immutable: Boolean,      // NEW - right after state
    previous_id: String,     // NEW - right before created_at
    created_at: Date,
    updated_at: Date,
    // ... entity-specific fields
}
```

**Specific Updates**:

- **sv.mongo.js**: Add `immutable`, `previous_id`, document `user_ids: { owners: [string], crew: [string], ... }`
- **org.mongo.js**: Rename `display` → `acronym`, add `immutable`, `previous_id`
- **club.mongo.js**: Rename `display` → `acronym`, add `immutable`, `previous_id`
- **boat.mongo.js**: Add `immutable`, `previous_id`
- **All other entities**: Add `immutable`, `previous_id`

### 3. Entity Request Stub

**Pattern**: Follow feedback entity structure

**CREATE**: `server/model/mongo/entity_request.mongo.js`

```javascript
const schema = new mongoose.Schema({
  // common entity fields
  id: String,
  rev: Number,
  type: {
    type: String,
    enum: ["undefined", "boat_request", "org_request", "club_request"],
    default: "boat_request",
  },
  state: {
    type: String,
    enum: ["undefined", "pending", "reviewed", "approved", "rejected"],
    default: "pending",
  },
  immutable: Boolean, // From createOrdered
  previous_id: String, // From createOrdered
  created_at: Date,
  updated_at: Date,

  // entity_request specific fields
  entity_type: {
    type: String,
    enum: ["boat", "org", "club"],
    required: true,
  },
  data: {
    type: Object,
    required: true,
    // For boat: { brand, model, builder }
    // For org: { acronym, name, address }
    // For club: { acronym, name, address }
  },
  user_id: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    enum: ["pending", "reviewed", "approved", "rejected"],
    default: "pending",
  },
});
```

**CREATE**: `server/controller/entity_request.controller.js`

```javascript
exports.create = async function (req, res) {
  // Stub implementation
  const requestData = await entityRequestModel.create({
    data: {
      entity_type: req.body.entity_type,
      data: req.body.data,
      status: "pending",
    },
    user_id: req.user,
  });

  return res.status(201).send({
    message: "Request submitted. Admin will review.",
    data: requestData,
  });
};
```

**CREATE**: `server/api/entity_request.route.js`

```javascript
api.post(
  "/api/entity_request",
  auth.verify("user"),
  use(entityRequestController.create)
);
```

### 4. SV Controller Implementation

**CREATE**: `server/controller/sv.controller.js`

**Key Functions**:

```javascript
// Duplicate check query
const existingSv = await Sv.findOne({
  boat_id: boat_id,
  "user_ids.owners": { $in: [userId] },
}).lean();

// Clone logic (when immutable)
const cloneData = {
  ...sv,
  id: undefined, // Will be generated
  previous_id: sv.id,
  immutable: false,
  created_at: new Date(),
  updated_at: null,
  rev: 0,
};
delete cloneData.id;
const clonedSv = await svModel.create(cloneData);
```

### 5. Frontend Entity Request Dialog

**Request Form Fields**:

**BOAT Request**:

```javascript
inputs={{
    brand: { label: 'Brand', type: 'text', required: true },
    model: { label: 'Model', type: 'text', required: true },
    builder: { label: 'Builder', type: 'text', required: true }
}}
```

**ORG Request**:

```javascript
inputs={{
    acronym: { label: 'Acronym', type: 'text', required: true },
    name: { label: 'Name', type: 'text', required: true },
    address: { label: 'Address', type: 'textarea', required: true }
}}
```

**CLUB Request**:

```javascript
inputs={{
    acronym: { label: 'Acronym', type: 'text', required: true },
    name: { label: 'Name', type: 'text', required: true },
    address: { label: 'Address', type: 'textarea', required: true }
}}
```

### 6. Multiple Selection UI

**Checkbox Interaction**:

- Clicking row OR checkbox toggles selection
- Visual feedback for selected items
- "Add Selected" button appears when items selected
- No "Select All" checkbox

**Implementation**:

```jsx
<div
  onClick={() => handleToggleSelection(item.id)}
  className="flex items-center p-2 hover:bg-slate-100 cursor-pointer"
>
  <Checkbox
    checked={selectedIds.includes(item.id)}
    onCheckedChange={() => handleToggleSelection(item.id)}
  />
  <span className="ml-2">{item.name}</span>
</div>
```

### 7. API Response Fields

**All API responses should include**:

- `immutable: boolean` - For padlock icon display
- `previous_id: string | null` - For undo/compare features

**Example SV Response**:

```json
{
  "data": {
    "id": "sv_123",
    "boat_id": "boat_123",
    "immutable": false,
    "previous_id": null,
    "user_ids": {
      "owners": ["user_456"],
      "crew": []
    },
    ...
  }
}
```

---

## Complete File List (Final)

### Helper Files (1)

1. **MODIFY**: `server/helper/mongo.js` - Update createOrdered()

### Schema Files (All Entities)

2. **MODIFY**: `server/model/mongo/sv.mongo.js`
3. **MODIFY**: `server/model/mongo/org.mongo.js`
4. **MODIFY**: `server/model/mongo/club.mongo.js`
5. **MODIFY**: `server/model/mongo/boat.mongo.js`
6. **MODIFY**: All other entity models in `server/model/mongo/`

### Backend Controllers (4)

7. **CREATE**: `server/controller/sv.controller.js`
8. **CREATE**: `server/controller/org.controller.js`
9. **CREATE**: `server/controller/club.controller.js`
10. **CREATE**: `server/controller/boat.controller.js`

### Backend Routes (4)

11. **CREATE**: `server/api/sv.route.js`
12. **CREATE**: `server/api/org.route.js`
13. **CREATE**: `server/api/club.route.js`
14. **CREATE**: `server/api/boat.route.js`

### Entity Request Stub (3)

15. **CREATE**: `server/model/mongo/entity_request.mongo.js`
16. **CREATE**: `server/controller/entity_request.controller.js`
17. **CREATE**: `server/api/entity_request.route.js`

### Backend Modifications (2)

18. **MODIFY**: `server/controller/user.controller.js`
19. **MODIFY**: `server/api/user.route.js` - Add GET /api/user/svs

### Frontend Components (1)

20. **MODIFY**: `client/src/components/form/collapsible-setting-row/collapsible-setting-row.jsx`

### Frontend Pages (4)

21. **MODIFY**: `client/src/views/account/profile.jsx`
22. **CREATE**: `client/src/views/account/organizations.jsx`
23. **CREATE**: `client/src/views/account/clubs.jsx`
24. **CREATE**: `client/src/views/account/svs.jsx`

### Frontend Routes & Navigation (3)

25. **MODIFY**: `client/src/routes/account.js`
26. **MODIFY**: `client/src/components/layout/account/account.jsx`
27. **MODIFY**: `client/src/views/account/index.jsx`

### Locale Files (5)

28. **MODIFY**: `client/src/locales/en/account/en_profile.json`
29. **CREATE**: `client/src/locales/en/account/en_organizations.json`
30. **CREATE**: `client/src/locales/en/account/en_clubs.json`
31. **CREATE**: `client/src/locales/en/account/en_svs.json`
32. **MODIFY**: `client/src/locales/en/en_nav.json`

**Total: 32 files** (1 helper, 6+ schemas, 7 controllers, 5 routes, 1 component, 4 pages, 3 navigation, 5 locales)

---

## Implementation Order (Final)

### Phase 1: Foundation - Helper & Schemas

1. Update `createOrdered()` helper
2. Update all entity schemas (immutable, previous_id)
3. Rename display → acronym in org/club
4. Test schema updates

### Phase 2: Backend APIs

5. Create org/club/boat/sv controllers
6. Create org/club/boat/sv routes
7. Create entity_request stub
8. Implement search logic
9. Implement SV CRUD with duplicate check
10. Implement SV immutable clone logic
11. Create GET /api/user/svs endpoint
12. Test all APIs

### Phase 3: Backend Validation

13. Update user controller validation
14. Implement ID validation and cleanup
15. Implement SV owner removal

### Phase 4: Frontend Component

16. Extend CollapsibleSettingRow
17. Test backward compatibility

### Phase 5: Profile Page

18. Refactor Profile page
19. Test accordion behavior

### Phase 6: Organizations Page

20. Create page
21. Implement searchable dropdown
22. Implement multiple selection
23. Implement request dialog
24. Test

### Phase 7: Clubs Page

25. Create page (copy organizations)
26. Test

### Phase 8: SVs Page

27. Create page
28. Implement boat dropdown
29. Implement parallel SV creation
30. Implement request dialog
31. Test

### Phase 9: Routes & Navigation

32. Add routes
33. Add nav items
34. Add index cards

### Phase 10: Locales

35. Update/create locale files

### Phase 11: Final Testing

36. End-to-end testing
37. Backward compatibility verification

---

## Success Criteria (Final Checklist)

- [ ] `createOrdered()` helper sets `immutable: false` and `previous_id: null`
- [ ] All entity schemas have `immutable` and `previous_id` fields
- [ ] Org/club schemas renamed `display` → `acronym`
- [ ] SV schema documents `user_ids` structure
- [ ] All API endpoints created and working
- [ ] Search works: Boat (name, sail_no), Org/Club (acronym, name)
- [ ] SV creation checks duplicates (boat_id + owners)
- [ ] SV update clones if immutable (doesn't fail)
- [ ] SV responses include `immutable` and `previous_id`
- [ ] Profile page uses accordion with label-above layout
- [ ] Email/phone clicks open accordion (not mailto/tel)
- [ ] Address field required with error
- [ ] Organizations page: searchable dropdown, multiple selection, request dialog
- [ ] Clubs page: searchable dropdown, multiple selection, request dialog
- [ ] SVs page: searchable dropdown, multiple selection, parallel creation, request dialog
- [ ] Multiple selection: row or checkbox click works
- [ ] Toast alerts show for each SV creation result
- [ ] Entity request dialogs collect correct fields
- [ ] CollapsibleSettingRow backward compatibility maintained
- [ ] Navigation works (cards and menu items)
- [ ] All locales updated/created

---

## Final Confidence Assessment

### Current Confidence: **99%**

### High Confidence Areas ✅

- ✅ Component extension (backward compatible, user testing)
- ✅ API endpoint patterns (follow existing structure)
- ✅ Frontend implementations (clear patterns)
- ✅ SV creation flow (duplicate prevention defined)
- ✅ Search implementation (straightforward queries)
- ✅ Multiple SV creation (parallel with toasts)
- ✅ Validation logic (straightforward)
- ✅ createOrdered helper update (clear implementation)
- ✅ Schema updates (systematic approach)
- ✅ SV immutable clone logic (well-defined)
- ✅ Entity request stub (follow feedback pattern)
- ✅ SV user_ids extensibility (flexible JSON)
- ✅ previous_id exposure (for undo/compare)
- ✅ immutable exposure (for padlock icon)
- ✅ Multiple selection UX (row or checkbox)
- ✅ Entity request form fields (all specified)

### Remaining 1%

The remaining 1% represents minor implementation details that will be resolved during coding:

- Exact UI styling for padlock icon
- Exact UI styling for undo/compare buttons (future features)
- Exact form field layouts and validation in request dialogs
- Minor edge cases in error handling

**All critical technical decisions are finalized.**

---

## Ready for Implementation

**✅ PLAN IS 99% COMPLETE AND READY FOR IMPLEMENTATION**

**Current Confidence: 99%**
**Target Confidence: 95%+ (EXCEEDED)**

**All questions answered. All technical decisions finalized.**

**Awaiting explicit command to proceed with implementation.**

---

**END OF READY FOR IMPLEMENTATION DOCUMENT**
