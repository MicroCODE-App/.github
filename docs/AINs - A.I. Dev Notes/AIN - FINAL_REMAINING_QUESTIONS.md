# Final Remaining Questions for 95%+ Confidence

## Current Confidence: **94%**

All major design decisions are resolved. Remaining questions are technical implementation details that can be answered or have reasonable defaults.

---

## Critical Questions (Answer Before Implementation)

### Q1: New "Get Owners" Endpoint Details

**Answer Provided**: New API endpoint 'get owners' of an 'sv'

**Remaining Clarifications**:

1. **Q1a**: What's the exact endpoint path?

   - Option A: `GET /api/sv/:id/owners` (RESTful, follows existing pattern)
   - Option B: `GET /api/sv/owners/:sv_id` (alternative RESTful)
   - Option C: `GET /api/sv/:id/owners` with query param `?sv_id=...`

2. **Q1b**: What's the response format?

   ```json
   {
     "owners": [
       { "id": "user_123", "name": "John Doe" },
       { "id": "user_456", "name": "Jane Smith" }
     ]
   }
   ```

   Or should it include more user data?

3. **Q1c**: Should backend populate names, or return IDs for frontend to populate?

   - **Recommendation**: Backend populates names (simpler frontend, consistent with other endpoints)

4. **Q1d**: Should we support batch lookup (get owners for multiple SVs)?
   - **Recommendation**: Start with single SV lookup, can add batch later if needed
   - Frontend can use `Promise.all()` to fetch owners for multiple SVs in parallel

**Impact**: Medium - Affects API design
**Confidence Impact**: +1.5% if answered

---

## Important Questions (Can Resolve During Implementation)

### Q2: Progress Bar Visibility

**Answer Provided**: Initial parallel + sequential to be stepped through

**Remaining Clarifications**:

1. **Q2a**: Should progress bar be visible during initial parallel batch?

   - **Recommendation**: Show progress bar immediately when "Add Selected" clicked
   - Display: "Processing 0 of 5" → "Processing 2 of 5" (as parallel completes) → "Processing 3 of 5" (duplicates start)

2. **Q2b**: How do we update progress during parallel batch?
   - **Recommendation**: Update after each Promise.allSettled result processes
   - Show: "Processing X of Y" where X increments as each result is processed

**Impact**: Low-Medium - Affects UX polish
**Confidence Impact**: +0.5% if answered

---

### Q4: Clone Fallback Response Flag

**Answer Provided**: Warning Toast

**Remaining Clarifications**:

1. **Q4a**: Should backend return explicit flag `{ cloned: false, fallback: true }`?

   - **Recommendation**: Yes, return flag so frontend can show appropriate toast
   - Response format:
     ```json
     {
       "message": "sv.create.new_success",
       "data": {
         /* new SV data */
       },
       "cloned": false,
       "fallback": true
     }
     ```

2. **Q4b**: What's the exact toast message?
   - **Recommendation**: Use translation key: `account.svs.duplicate.clone_fallback_warning`
   - Message: "Clone failed, created new SV instead"

**Impact**: Low - Affects error communication polish
**Confidence Impact**: +0.5% if answered

---

### Q5: Radio Button Display Logic

**Answer Provided**: Radio Buttons

**Remaining Clarifications**:

1. **Q5a**: Should radio buttons be shown always, or only when action='clone'?

   - **Recommendation**: Only show when action='clone' (conditional display)
   - Hide when action='new' or action='cancel'

2. **Q5b**: Should immutable SVs be selectable in radio buttons, or disabled?

   - **Recommendation**: Selectable (user can clone immutable SV)
   - Show visual indicator (badge) but allow selection

3. **Q5c**: Should we show radio buttons even if only one SV exists (pre-selected)?
   - **Recommendation**: Yes, show radio button but pre-select it
   - User can still see which SV they're cloning

**Impact**: Low - Affects UI polish
**Confidence Impact**: +0.5% if answered

---

### Q6: Delete Failure Error Toast

**Answer Provided**: Log + Error Toast

**Remaining Clarifications**:

1. **Q6a**: Should error toast prevent new SV creation, or just warn but continue?

   - **Recommendation**: Just warn but continue (don't block new SV creation)
   - Error toast: "Failed to delete existing SV, but new SV was created"

2. **Q6b**: What's the exact error message?
   - **Recommendation**: Use translation key: `account.svs.create.delete_failed`
   - Message: "Failed to delete existing SV, but new SV was created"

**Impact**: Low - Edge case handling
**Confidence Impact**: +0.5% if answered

---

## Summary

### Questions Answered ✅

- Q3: Immutable-only SVs → Show in modal, allow "new"
- Q7: Boat data → Handle missing gracefully

### Questions Needing Clarification

- **Critical**: Q1a-Q1d (API endpoint details) → +1.5%
- **Important**: Q2a-Q2b, Q4a-Q4b, Q5a-Q5c, Q6a-Q6b → +2%

### Recommended Approach

**Option A: Answer Q1a-Q1d Now** → **95.5% confidence** → Proceed

- Get API endpoint details confirmed
- Resolve remaining questions during implementation with reasonable defaults

**Option B: Answer All Questions** → **96%+ confidence** → Proceed

- Fully resolve all technical details
- Smoother implementation, fewer decisions during coding

**Option C: Proceed with Defaults** → **94% confidence** → Proceed

- Use reasonable defaults for all questions
- Adjust during implementation if needed

---

## Recommended Defaults (If Questions Not Answered)

1. **Q1**: Use `GET /api/sv/:id/owners`, backend populates names, frontend uses Promise.all for batch
2. **Q2**: Show progress bar immediately, update after each operation completes
3. **Q4**: Backend returns `{ cloned: false, fallback: true }`, frontend shows warning toast
4. **Q5**: Radio buttons only when action='clone', immutable SVs selectable, show even if one SV
5. **Q6**: Error toast warns but continues, use translation key

---

**Recommendation**: Answer Q1a-Q1d to reach **95.5%+ confidence**, then proceed. All other questions have reasonable defaults that can be refined during implementation.
