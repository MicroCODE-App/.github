# PLAN - Fix Table Scrolling in Admin Console List Views

## Executive Summary

**Problem**: Table contents in admin console list views are not scrollable - no scrollbar appears and mouse wheel doesn't work when content overflows.

**Scope**: Fix scrolling ONLY in `admin/console/src/views/` for: Logs, Events, Accounts, Users, Boats, Orgs, Clubs, Active, Online, Offline, Onboarding, and Suspended views.

**Solution**: Update CSS in `list.css` to properly propagate flex height constraints through Card → CardContent → Table component chain, enabling the Table's `overflow-auto` container to scroll.

**Approach**: CSS-only changes to fix flex layout chain. No component API changes required.

**Files to Modify**:

1. `admin/console/src/views/list.css` - Add flex rules for scrolling
2. `admin/console/src/views/log/list.jsx` - Optionally restructure or add CSS
3. `admin/console/src/views/event/list.jsx` - Optionally restructure or add CSS

## Problem Statement

The searchable list/table views in `admin/console/` are not scrollable. The table contents cannot be scrolled when items overflow the viewport - no scrollbar appears and mouse wheel scrolling doesn't work.

### What's Working

- ✅ Layout structure: Fixed search bar outside table on app background
- ✅ Visual appearance: Margins, padding, headers, content all correct
- ✅ Table collapse: Table collapses to list contents only, revealing app background
- ✅ Search count and entity icon positioning

### What's Broken

- ❌ Table contents are not scrollable
- ❌ No scrollbar when items overflow screen
- ❌ Mouse wheel scrolling doesn't work

## Affected Views

All views in `admin/console/src/views/` that display search + table layout:

1. **Primary Views** (using `list-page-container` structure):

   - `accounts.jsx`
   - `users.jsx`
   - `boats.jsx`
   - `orgs.jsx`
   - `clubs.jsx`

2. **Filtered User Views** (wrap `Users` component):

   - `active.jsx` → uses `Users` with `mode="active"`
   - `online.jsx` → uses `Users` with `mode="online"`
   - `offline.jsx` → uses `Users` with `mode="offline"`
   - `onboarding.jsx` → uses `Users` with `mode="onboarding"`
   - `disabled.jsx` → uses `Users` with `mode="disabled"`

3. **Special Views** (different structure, need separate fix):
   - `log/list.jsx` - Uses `Row` + `Card` + `Table` (no `list-page-container`)
   - `event/list.jsx` - Uses `Row` + `Card` + `Table` (no `list-page-container`)

## Root Cause Analysis

### Current DOM Structure

**For list-page-container views (Users, Accounts, Boats, Orgs, Clubs):**

```
<div class="list-page-container">                    ← max-height: calc(100vh - 6rem)
  <div class="list-page-header">                    ← flex: 0 0 auto (fixed)
    <div>Search + Count + Icon</div>
  </div>
  <div class="list-page-body">                      ← flex: 1 1 auto, overflow: hidden
    <div class="list-page-card">                    ← flex: 1 1 auto, min-height: 0
      <Card>                                        ← Needs: flex: 1 1 auto, overflow: hidden
        <CardContent class="p-6">                   ← Needs: flex: 1 1 auto, overflow: hidden
          <Table>
            <div>                                   ← Table root wrapper
              <div class="overflow-hidden border">  ← Needs: flex: 1 1 auto, overflow: hidden
                <div class="overflow-auto">         ← THIS SHOULD SCROLL ← Needs: flex: 1 1 auto, overflow: auto
                  <table>
                    <thead>...</thead>
                    <tbody>...</tbody>
                  </table>
                </div>
              </div>
            </div>
          </Table>
        </CardContent>
      </Card>
    </div>
  </div>
</div>
```

**For Logs/Events views (different structure):**

```
<Fragment>
  <div>Search + Count + Icon</div>                 ← Not in list-page-container
  <Row>
    <Card>
      <CardContent>
        <Table>
          <div class="overflow-auto">               ← Should scroll but doesn't
            <table>...</table>
          </div>
        </Table>
      </CardContent>
    </Card>
  </Row>
  <Pagination />
</Fragment>
```

### Issues Identified

1. **CSS Mismatch**: `list.css` has rules for `.list-table-container` but views use `.list-page-container`
2. **Missing Flex Chain**: Height constraints aren't propagating through the flex chain:
   - `.list-page-card` → `Card` → `CardContent` → `Table root` → `Table overflow-hidden` → `Table overflow-auto`
3. **Card Component**: `Card` and `CardContent` don't participate in flex layout when inside `.list-page-card`
4. **Table Wrapper**: The Table's `overflow-auto` div doesn't get height from parent because the flex chain is broken
5. **Logs/Events**: These views use a different structure (`Row` + `Card`) and need separate CSS rules or structural changes

## Solution Design

### Approach: Fix CSS and Table Component Structure

The solution will:

1. Update `list.css` to properly handle scrolling for `list-page-container` structure
2. Ensure Card component doesn't interfere with flex layout
3. Make Table component's scroll wrapper properly constrained
4. Apply consistent fixes to Logs and Events views

### CSS Changes Required

**File**: `admin/console/src/views/list.css`

1. **Fix `.list-page-body` scrolling**:

   - Ensure it properly constrains height
   - Make `.list-page-card` participate in flex layout
   - Ensure Card content area can scroll

2. **Add rules for Card + Table combination**:

   - Make Card's content area flex-aware
   - Ensure Table's scroll wrapper gets proper height

3. **Fix Logs/Events views**:
   - Add alternative CSS classes for views using `Row` + `Card` structure

### Component Changes Required

**File**: `admin/console/src/components/card/card.jsx`

- Ensure `CardContent` doesn't interfere with flex layout when inside scrollable container
- May need to add conditional className based on context

**File**: `admin/console/src/components/table/table.jsx`

- Ensure the scroll wrapper (`div.overflow-auto`) gets proper height constraints
- May need to add height: 100% or similar to propagate flex height

## Implementation Plan

### Phase 1: CSS Fixes for list-page-container Views

**Step 1.1**: Update `list.css` for proper scrolling

- Fix `.list-page-body` to ensure proper height constraint
- Add rules for `.list-page-card` to participate in flex
- Add rules for Card inside `.list-page-card` to not interfere
- Add rules for Table scroll wrapper to get proper height

**Step 1.2**: Verify Card component compatibility

- Check if Card's `CardContent` needs flex-aware styling
- Ensure padding doesn't break scroll container

**Step 1.3**: Verify Table component scroll wrapper

- Ensure `div.overflow-auto` gets height from parent
- May need to add `height: 100%` or use flex

### Phase 2: Fix Logs and Events Views

**Step 2.1**: Update `log/list.jsx`

- Wrap search + table in `list-page-container` structure OR
- Add alternative CSS classes for Row-based layout
- Ensure scrolling works with pagination

**Step 2.2**: Update `event/list.jsx`

- Same approach as Logs
- Ensure scrolling works with pagination and chart

### Phase 3: Testing

**Step 3.1**: Test all affected views

- Verify scrollbar appears when content overflows
- Verify mouse wheel scrolling works
- Verify search bar stays fixed
- Verify table headers stay visible (if sticky)
- Verify empty state (table collapse) still works

**Step 3.2**: Cross-browser testing

- Chrome/Edge
- Firefox
- Safari (if applicable)

## Detailed File Changes

### File: `admin/console/src/views/list.css`

**Current Issues**:

- Rules target `.list-table-container` but views use `.list-page-container`
- Missing rules for Card + Table scroll interaction
- Missing height propagation through Card component

**Changes Needed**:

The key issue is that the Card component and Table component need to participate in the flex layout chain. The current CSS stops at `.list-page-card` but doesn't propagate height through Card → CardContent → Table.

```css
/* Ensure list-page-body creates scrollable area (already correct) */
.list-page-body {
  flex: 1 1 auto;
  min-height: 0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

/* Make card participate in flex (already correct, but need to add overflow) */
.list-page-body > .list-page-card {
  flex: 1 1 auto;
  min-height: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden; /* ADD THIS */
}

/* CRITICAL: Use child combinator (>) for launch safety - ensures rules ONLY apply to .list-page-card children */
/* This prevents affecting Card/Table components used elsewhere (dashboard, feedback, help, detail views) */

/* Make Card component flex-aware when inside list-page-card */
/* Card is the direct child of .list-page-card */
.list-page-card > div {
  flex: 1 1 auto;
  min-height: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* Make CardContent flex-aware */
/* CardContent is the direct child of Card */
.list-page-card > div > div {
  flex: 1 1 auto;
  min-height: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* Ensure Table's root div gets height */
/* Table component returns a div wrapper - direct child of CardContent */
.list-page-card > div > div > div {
  flex: 1 1 auto;
  min-height: 0;
  display: flex;
  flex-direction: column;
}

/* Table's outer wrapper with overflow-hidden */
/* This is: <div className='relative w-full overflow-hidden border rounded...'> */
/* Direct child of Table root */
.list-page-card > div > div > div > div {
  flex: 1 1 auto;
  min-height: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* Table's scroll container - THIS IS THE KEY FIX */
/* This is: <div className='w-full overflow-auto'> */
/* Direct child of overflow-hidden wrapper */
.list-page-card > div > div > div > div > div {
  flex: 1 1 auto;
  min-height: 0;
  overflow: auto;
  width: 100%;
}

/* Scrollbar styling - using child combinator for safety */
.list-page-card > div > div > div > div > div::-webkit-scrollbar {
  width: 9px;
}

/* Light mode scrollbar */
.list-page-card > div > div > div > div > div::-webkit-scrollbar-track {
  background: rgb(226 232 240); /* slate-200 */
}

.list-page-card > div > div > div > div > div::-webkit-scrollbar-thumb {
  background: rgb(139 139 200); /* lighter purple */
  border-radius: 4px;
}

.list-page-card > div > div > div > div > div::-webkit-scrollbar-thumb:hover {
  background: rgb(99 99 172); /* primary purple #6363ac */
}

/* Dark mode scrollbar */
.dark .list-page-card > div > div > div > div > div::-webkit-scrollbar-track {
  background: rgb(2 6 23); /* slate-950 */
}

.dark .list-page-card > div > div > div > div > div::-webkit-scrollbar-thumb {
  background: rgb(148 163 184); /* slate-400 */
  border-radius: 4px;
}

.dark
  .list-page-card
  > div
  > div
  > div
  > div
  > div::-webkit-scrollbar-thumb:hover {
  background: rgb(203 213 225); /* slate-300 */
}

/* Sticky header support */
.list-page-card table thead {
  position: sticky;
  top: 0;
  z-index: 10;
  background-color: white;
}

.dark .list-page-card table thead {
  background-color: rgb(15 23 42); /* slate-900 */
}
```

**Alternative Approach (More Specific)**:

If the above CSS selectors are too broad and might affect other components, we can use a more specific approach by adding a className to the Card when it's inside list-page-card, or by using a more specific selector chain.

**CRITICAL - Launch Safety (3 weeks to launch)**: Use MOST SPECIFIC selectors to avoid breaking other areas:

**Recommended Approach - Use Child Combinator Selectors**:

- `.list-page-card > div` (Card root) - needs flex: 1 1 auto, overflow: hidden
- `.list-page-card > div > div` (CardContent) - needs flex: 1 1 auto, overflow: hidden
- `.list-page-card > div > div > div` (Table root) - needs flex: 1 1 auto
- `.list-page-card > div > div > div > div` (Table overflow-hidden wrapper) - needs flex: 1 1 auto, overflow: hidden
- `.list-page-card > div > div > div > div > div` (Table overflow-auto scroll container) - needs flex: 1 1 auto, overflow: auto

**Why This Is Safe**:

- Child combinator (`>`) ensures rules ONLY apply to direct children of `.list-page-card`
- `.list-page-card` is ONLY used in the 12 affected list views
- Other Card usages (dashboard, feedback, help, detail views) are NOT inside `.list-page-card`
- No risk of affecting other areas of the app

**Fallback Strategy**:
If child combinator selectors don't work due to React component boundaries, add a specific className prop to Card when used inside `.list-page-card`:

- Add `data-scrollable-table="true"` attribute or `scrollable-table` className
- This requires minimal component changes but provides maximum safety

### File: `admin/console/src/components/card/card.jsx`

**Potential Changes**:

- May need to add conditional className to CardContent when inside scrollable container
- Or rely on CSS selectors in `list.css`

**Decision**:

- **Primary**: Use child combinator CSS selectors (`.list-page-card > div > div...`) - safest, no component changes
- **Fallback**: If CSS selectors don't work due to component boundaries, add `scrollable-table` className prop to Card when inside `.list-page-card`
- **Safety First**: Given 3-week launch timeline, prefer CSS-only approach that's scoped to `.list-page-card` only

### File: `admin/console/src/components/table/table.jsx`

**Current Structure** (lines 315-361):

```jsx
<div className="relative w-full overflow-hidden border rounded dark:border-slate-800">
  <div className="w-full overflow-auto">
    {hasData ? <table>...</table> : null}
  </div>
</div>
```

**Potential Changes**:

- May need to add `h-full` or flex classes to outer div
- Ensure inner `overflow-auto` div gets height from parent

**Decision**:

- **Primary**: Use child combinator CSS selectors to target Table's scroll wrapper
- **Fallback**: If needed, add `h-full` className to Table's outer wrapper div
- **Safety**: All selectors scoped to `.list-page-card` context only - won't affect other Table usages

### File: `admin/console/src/views/log/list.jsx`

**Current Structure**:

- Uses `Row` + `Card` + `Table` (no `list-page-container`)
- Has pagination below table
- **Visual appearance matches Users/Accounts views** - MUST PRESERVE

**Approach**:

- Wrap search bar + table in `list-page-container` structure to match other views
- Keep pagination outside the scroll container (below)
- Ensure visual appearance remains identical to Users view
- Scroll within current page results (10 items per page)

**Changes**:

```jsx
// Wrap search + table in list-page-container
<div className='list-page-container'>
  <div className='list-page-header'>
    {/* Search + Count + Icon */}
  </div>
  <div className='list-page-body'>
    <div className='list-page-card'>
      <Card>
        <Table />
      </Card>
    </div>
  </div>
</div>
<Pagination /> {/* Outside scroll container */}
```

### File: `admin/console/src/views/event/list.jsx`

**Current Structure**:

- Uses `Row` + `Card` + `Table` (no `list-page-container`)
- Has chart above table (in separate Row)
- Has pagination below table
- **Visual appearance matches Users/Accounts views** - MUST PRESERVE

**Approach**:

- Keep chart in separate Row (outside scroll container)
- Wrap search bar + table in `list-page-container` structure
- Keep pagination outside the scroll container
- Ensure visual appearance remains identical to Users view
- Scroll within current page results (25 items per page)

**Changes**:

```jsx
{/* Chart stays outside */}
<Row>
  <Card><Chart /></Card>
</Row>

{/* Wrap search + table in list-page-container */}
<div className='list-page-container'>
  <div className='list-page-header'>
    {/* Search + Count + Icon */}
  </div>
  <div className='list-page-body'>
    <div className='list-page-card'>
      <Card>
        <Table />
      </Card>
    </div>
  </div>
</div>
<Pagination /> {/* Outside scroll container */}
```

## Implementation Order

1. **First**: Fix CSS for existing `list-page-container` views

   - Update `list.css` with proper flex and overflow rules
   - Add sticky header support
   - Test with Users, Accounts, Boats, Orgs, Clubs
   - Verify empty state collapses correctly

2. **Second**: Fix Logs and Events views

   - Update structure to use `list-page-container` to match other views
   - Ensure visual appearance remains identical (no layout changes)
   - Keep pagination outside scroll container
   - Ensure scrolling works within current page results
   - Test with pagination

3. **Third**: Verify all views work correctly
   - Test scrolling, scrollbar, mouse wheel
   - Test sticky headers stay visible
   - Test empty states collapse completely
   - Test search functionality
   - Verify visual consistency across all views

## Testing Checklist

- [ ] Users view scrolls when > 20 users
- [ ] Accounts view scrolls when > 20 accounts
- [ ] Boats view scrolls when > 20 boats
- [ ] Orgs view scrolls when > 20 orgs
- [ ] Clubs view scrolls when > 20 clubs
- [ ] Active view scrolls (uses Users component)
- [ ] Online view scrolls (uses Users component)
- [ ] Offline view scrolls (uses Users component)
- [ ] Onboarding view scrolls (uses Users component)
- [ ] Suspended view scrolls (uses Users component)
- [ ] Logs view scrolls when > 10 logs
- [ ] Events view scrolls when > 25 events
- [ ] Scrollbar appears and is styled correctly
- [ ] Mouse wheel scrolling works
- [ ] Search bar stays fixed at top
- [ ] Table headers stay visible (if sticky)
- [ ] Empty state (no data) still shows app background
- [ ] Pagination still works in Logs/Events

## Questions to Clarify - ANSWERED

1. **Sticky Headers**: ✅ YES - Users want to see headers while scrolling through large data
2. **Pagination**: ✅ Scroll within current page results (pagination limits are off-screen, scroll within page is safest)
3. **Card Padding**: ✅ PRESERVE - Keep `p-6` padding as-is
4. **Empty State**: ✅ COLLAPSE COMPLETELY - Single line looks nice, shows app background
5. **Browser Support**: ✅ Modern browsers with flexbox support

## Important Constraint

**CRITICAL**: Do NOT change the visual appearance of list/tables. Even though Logs and Events use different structure (`Row` + `Card`), they must look identical to Users/Accounts/Boats/etc. The comparison images show they already look the same - we must preserve this visual consistency.

## Risk Assessment

**Low Risk**:

- CSS-only changes to `list.css`
- No breaking changes to component APIs
- Changes are scoped to admin/console

**Medium Risk**:

- Modifying Logs/Events view structure might affect pagination
- Card component changes might affect other views using Card

**Mitigation**:

- Test thoroughly before deployment
- Keep changes minimal and focused
- Use CSS selectors that are specific to list-page-container context

## Success Criteria

✅ Table contents scroll when items overflow viewport
✅ Scrollbar appears and is visible/styled correctly
✅ Mouse wheel scrolling works
✅ Search bar remains fixed outside scroll area
✅ Table headers remain visible (if sticky)
✅ Empty state still collapses to show app background
✅ All affected views work correctly
✅ No regressions in other views

## Notes

- This fix should ONLY affect views in `admin/console/`
- The layout structure (search bar, count, icon) should NOT change
- **CRITICAL**: Visual appearance must remain identical across all views
- Only scrolling behavior should be fixed
- Logs and Events must look visually identical to Users/Accounts/etc. even though they use different structure
- Empty state should collapse to single line showing app background

---

## REVIEW SECTION

### Confidence Rating: **96%** (Updated with Launch Safety Constraints)

### What Looks Good ✅

1. **Clear Problem Identification**: Root cause is well understood - broken flex layout chain
2. **Comprehensive Scope**: All affected views identified and categorized
3. **CSS-First Approach**: Starting with CSS-only changes minimizes risk
4. **Visual Consistency**: Plan addresses the requirement to keep all views looking identical
5. **Sticky Headers**: Plan includes sticky header support as requested
6. **Empty State**: Plan preserves collapse behavior
7. **Pagination Handling**: Clear approach for Logs/Events pagination
8. **Launch Safety**: Plan uses child combinator selectors scoped to `.list-page-card` only - won't affect other Card/Table usages
9. **Specificity**: Child combinator (`>`) ensures rules don't leak to other areas
10. **Verification**: Confirmed Card usage in other views (dashboard, feedback, help) - all outside `.list-page-card` - safe

### What Needs Adjustment ⚠️

1. ✅ **CSS Selector Specificity**: **FIXED** - Updated to use child combinator selectors (`.list-page-card > div > div...`) - most specific, safest for launch

2. **Logs/Events Structure Change**: Converting Logs/Events to `list-page-container` structure is a structural change. While it should maintain visual appearance, need to ensure:

   - No visual regressions
   - Pagination still works correctly
   - Chart positioning in Events view remains correct

3. **Testing Strategy**: Need more specific test cases for:
   - Visual regression testing (compare before/after screenshots)
   - Edge cases (very long content, rapid scrolling)
   - Different screen sizes

### Remaining Questions - ANSWERED

1. **CSS Selector Robustness**: ✅ **USE CHILD COMBINATOR SELECTORS** (`.list-page-card > div > div...`) - Most specific, safest for launch timeline
2. **Visual Regression Testing**: ✅ **MANUAL PLAN** - User will share issues through screen captures
3. **Row Component Impact**: ✅ **USE BEST JUDGMENT** - Will remove Row wrapper when converting to `list-page-container` structure (Row only adds `mb-4`, which `list-page-container` handles)

### Concerns and Risks - UPDATED FOR LAUNCH SAFETY

**CRITICAL CONSTRAINT**: 3 weeks to launch - must not break other areas of the app

**Low Risk** (with proper implementation):

- ✅ CSS changes scoped to `.list-page-card` context ONLY
- ✅ Child combinator selectors (`>`) ensure rules don't leak to other Card/Table usages
- ✅ `.list-page-card` is ONLY used in the 12 affected list views
- ✅ No component API changes required initially
- ✅ Can test incrementally, one view at a time

**Medium Risk** (mitigated):

- ⚠️ CSS selectors must be child combinators, not attribute selectors (too broad)
- ⚠️ Structural changes to Logs/Events must maintain visual consistency
- ⚠️ Need to ensure pagination doesn't break

**Mitigation Strategies** (Enhanced for Launch Safety):

1. ✅ **Use child combinator selectors** (`.list-page-card > div > div...`) - most specific, safest
2. ✅ **Test incrementally** - one view at a time, verify no regressions
3. ✅ **Scope all CSS to `.list-page-card`** - ensures no impact on other Card/Table usages
4. ✅ **Manual visual verification** - user will provide screen captures for any issues
5. ✅ **Fallback plan** - if CSS selectors don't work, add className props (minimal component changes)
6. ✅ **Verify Card usage** - confirmed Card is used in dashboard, feedback, help, detail views - all OUTSIDE `.list-page-card` - safe

### Approval Status

**Status**: ✅ **READY TO PROCEED** - Launch-Safe Plan Approved

**Launch Safety Measures**:

- ✅ Child combinator CSS selectors (`.list-page-card > div...`) - most specific, won't affect other areas
- ✅ All CSS scoped to `.list-page-card` context only
- ✅ Verified Card usage in other views - all outside `.list-page-card` - safe
- ✅ Manual testing plan in place (user screen captures)
- ✅ Incremental testing approach - one view at a time

**Confidence Breakdown** (Updated):

- **Phase 1 (CSS fixes for list-page-container views)**: **97%** - Well understood, child combinator selectors ensure safety
- **Phase 2 (Logs/Events structure)**: **95%** - Straightforward conversion, verified structure matches
- **Overall Plan**: **96%** - Solid plan with launch-safe approach, child combinator selectors prevent regressions

**Ready to proceed with**:

- ✅ Phase 1: CSS fixes for existing `list-page-container` views
- ✅ Phase 2: Convert Logs/Events to `list-page-container` structure (they already have matching search bar structure)

**Refinement Strategy** (Launch-Safe):

- ✅ **Use child combinator selectors** (`.list-page-card > div > div...`) - most specific, safest
- ✅ **Scope all CSS to `.list-page-card`** - ensures no impact on other Card/Table usages
- ✅ **Test incrementally** - one view at a time, verify no regressions
- ✅ **Manual verification** - user will provide screen captures for any issues
- ✅ **Fallback plan** - if CSS selectors don't work, add className props (minimal component changes)

### Implementation Readiness Checklist

- ✅ Problem clearly identified and understood
- ✅ Root cause analyzed (broken flex layout chain)
- ✅ All affected views identified
- ✅ Solution approach defined (CSS-first, then component changes if needed)
- ✅ User requirements clarified (sticky headers, pagination, padding, empty state)
- ✅ Visual consistency requirement understood
- ✅ Implementation steps defined
- ✅ Testing checklist created
- ✅ Risk assessment completed
- ✅ CSS selector specificity addressed - using child combinator selectors for maximum safety

### Next Steps

1. **Proceed with Phase 1**: Update `list.css` with flex rules for `.list-page-container` views
2. **Test Phase 1**: Verify scrolling works in Users, Accounts, Boats, Orgs, Clubs
3. **Refine if needed**: If CSS selectors are too broad, add className props
4. **Proceed with Phase 2**: Convert Logs/Events structure
5. **Visual verification**: Compare before/after screenshots to ensure visual consistency
6. **Final testing**: Complete testing checklist across all views

### Final Notes

- ✅ Plan is comprehensive and ready for implementation
- ✅ CSS selector specificity addressed - using child combinator selectors for maximum launch safety
- ✅ Visual consistency is critical - will verify during implementation via user screen captures
- ✅ Can proceed incrementally: Phase 1 first, then Phase 2 after verification
- ✅ Launch-safe approach: All CSS scoped to `.list-page-card` only, won't affect other Card/Table usages
- ✅ Manual testing plan in place - user will provide screen captures for any issues
