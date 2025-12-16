# Implementation Plan: Reorganize Entity Management Dialogs

## Executive Summary

This plan outlines the reorganization of the "Manage Orgs, Clubs, and SVs" dialogs with **conditional UI behavior** based on whether the user has entities:

1. **Empty State (No Entities)**: NO CHANGES - UI remains exactly as currently implemented
2. **Non-Empty State (Has Entities)**: Move "[ + Add {Entity} ]" button below the list and add "[ Request New {Entity} ]" button next to it

### ⚠️ CRITICAL REQUIREMENTS

**Empty State (No Entities):**

- **ZERO CHANGES** - UI must remain exactly as shown in the reference image
- Help Section → Add Button (above) → Alert Box with Request button → Save Button
- The Alert box and its internal Request button must remain unchanged

**Non-Empty State (Has Entities):**

- Alert box does NOT appear
- Entity list is displayed
- Add button is moved BELOW the list
- New Request button appears NEXT TO Add button (side-by-side)
- Both buttons positioned between list and Save button

---

## Table of Contents

1. [Current State Analysis](#current-state-analysis)
2. [Proposed Changes](#proposed-changes)
3. [Affected Files](#affected-files)
4. [UI/UX Changes](#uiux-changes)
5. [Interface Contracts](#interface-contracts)
6. [User Stories](#user-stories)
7. [Implementation Steps](#implementation-steps)
8. [Diagrams](#diagrams)
9. [Questions for Clarification](#questions-for-clarification)
10. [Testing Strategy](#testing-strategy)
11. [Risk Assessment](#risk-assessment)

---

## Current State Analysis

### Components Affected

Three React components follow identical patterns:

1. **Organizations** (`client/src/views/account/organizations.jsx`)
2. **Clubs** (`client/src/views/account/clubs.jsx`)
3. **SVs** (`client/src/views/account/svs.jsx`)

### Current UI Structure

**When User Has NO Entities (Empty State) - CURRENT:**

```
┌─────────────────────────────────────────┐
│  Manage {Entity}                        │
├─────────────────────────────────────────┤
│  [About {Entity} Help Section]          │
│                                         │
│  [+ Add {Entity}] ← Currently HERE      │
│                                         │
│  [No {Entity}s Alert Box]               │
│  └─ [Request to Add {Entity}] Button   │ ← Inside Alert
│                                         │
│  [Save Button]                          │
└─────────────────────────────────────────┘
```

**This structure must remain UNCHANGED**

**When User Has Entities (Non-Empty State) - CURRENT:**

```
┌─────────────────────────────────────────┐
│  Manage {Entity}                        │
├─────────────────────────────────────────┤
│  [About {Entity} Help Section]          │
│                                         │
│  [+ Add {Entity}] ← Currently HERE      │
│                                         │
│  [List of User's {Entities}]            │
│  - Entity 1                    [X]      │
│  - Entity 2                    [X]      │
│  - Entity 3                    [X]      │
│                                         │
│  [Save Button]                          │
└─────────────────────────────────────────┘
```

**This structure WILL CHANGE**

### Current Functionality

1. **Add Button**: Opens a Popover with:

   - Search input
   - List of available entities (checkboxes)
   - Selected items section
   - "Add {count} Selected" button

2. **Request Functionality**: Currently only accessible via:

   - Empty state Alert component (when user has no entities)
   - Hidden from main UI when entities exist

3. **Entity List**: Displays user's current entities with remove (X) buttons

### Current Code Patterns

All three components share:

- Similar state management (`selectedIds`, `selected{Entities}`, `loading`)
- Identical Popover structure for adding entities
- `handleRequestNew()` function that opens a dialog
- Empty state handling with Alert component
- Conditional rendering: `current{Entity}s.length === 0` shows Alert, else shows list
- Save button that persists current state

---

## Proposed Changes

### New UI Structure

**When User Has NO Entities (Empty State) - NO CHANGES:**

```
┌─────────────────────────────────────────┐
│  Manage {Entity}                        │
├─────────────────────────────────────────┤
│  [About {Entity} Help Section]          │
│                                         │
│  [+ Add {Entity}] ← STAYS HERE          │
│                                         │
│  [No {Entity}s Alert Box]               │ ← UNCHANGED
│  └─ [Request to Add {Entity}] Button    │ ← UNCHANGED
│                                         │
│  [Save Button]                          │
└─────────────────────────────────────────┘
```

**This remains EXACTLY as-is**

**When User Has Entities (Non-Empty State) - NEW STRUCTURE:**

```
┌────────────────────────────────────────────┐
│  Manage {Entity}                           │
├────────────────────────────────────────────┤
│  [About {Entity} Help Section]             │
│                                            │
│  [List of User's {Entities}]               │
│  - Entity 1                    [X]         │
│  - Entity 2                    [X]         │
│  - Entity 3                    [X]         │
│                                            │
│  [+ Add {Entity}] [Request other {Entity}] │← NEW location, side-by-side
│                                            │
│  [Save Button]                             │
└────────────────────────────────────────────┘
```

**Alert box does NOT appear when list is non-empty**

### Key Changes

1. **Conditional Rendering**:

   - Empty state: Render Add button ABOVE Alert box (current behavior)
   - Non-empty state: Render Add button BELOW entity list (new behavior)

2. **New Request Button**:

   - Only appears when list is NON-EMPTY
   - Positioned next to Add button (side-by-side)
   - Label: "Request New {Entity}" (shorter, clear)

3. **Alert Box Behavior**:

   - Only appears when list is EMPTY
   - Completely hidden when list is NON-EMPTY

4. **Layout**:

   - Non-empty state: Both buttons displayed side-by-side in a flex container
   - Empty state: No changes to layout

5. **Consistency**: Apply same pattern to all three components

---

## Affected Files

### Primary Files (Direct Changes)

1. **`client/src/views/account/organizations.jsx`**

   - Modify conditional rendering logic for Add button
   - Add conditional Request button (only when `currentOrgs.length > 0`)
   - Ensure Alert box only renders when `currentOrgs.length === 0`
   - Move Add button section conditionally based on list state

2. **`client/src/views/account/clubs.jsx`**

   - Same changes as Organizations component
   - Apply consistent pattern

3. **`client/src/views/account/svs.jsx`**
   - Same changes as Organizations component
   - Apply consistent pattern

### Translation Files (May Need Updates)

4. **`client/src/locales/en/account/en_organizations.json`**

   - Add new key: `"request_new": { "button": "Request New Organization" }`

5. **`client/src/locales/en/account/en_clubs.json`**

   - Add new key: `"request_new": { "button": "Request New Club" }`

6. **`client/src/locales/en/account/en_svs.json`**
   - Add new key: `"request_new": { "button": "Request New Boat" }`

### No Backend Changes Required

- Entity request API (`/api/entity_request`) already exists and works
- No database schema changes needed
- No API endpoint modifications required

---

## UI/UX Changes

### Visual Layout

**Empty State (No Changes):**

```
[Help Section]
[+ Add Organization] ← Stays above
[No Organizations Alert Box]
 └─ [Request to Add Organization] ← Inside Alert
[Save]
```

**Non-Empty State (New Layout):**

```
[Help Section]
[List of Organizations]
 - Org 1                    [X]
 - Org 2                    [X]
[+ Add Organization]  [Request other Organization] ← NEW: side-by-side
[Save]
```

### Button Styling

**Add Button:**

- Current: `variant='outline'`, `icon='plus'`
- Keep existing styling
- Position: Conditional (above Alert when empty, below list when non-empty)

**Request Button (Non-Empty State):**

- New: `variant='outline'` or `variant='secondary'`
- Icon: `icon='plus'` or `icon='file-plus'` or `icon='request'`
- Label: "Request other {Entity}" (to differentiate from Alert button)
- Position: Right side of button pair (only when list is non-empty)

### Responsive Behavior

- **Desktop**: Buttons side-by-side with equal width (non-empty state only)
- **Mobile**: Stack vertically if screen width < 640px (sm breakpoint)
- Use Tailwind responsive classes: `flex flex-col sm:flex-row gap-2`
- Both buttons use `flex-1` for equal width
- Empty state: No responsive changes needed (unchanged)

### Conditional Rendering Logic

**Key Implementation Pattern:**

```jsx
{currentOrgs.length === 0 ? (
  // Empty State - NO CHANGES
  <>
    {/* Add Button - ABOVE Alert */}
    <Popover>...</Popover>

    {/* Alert Box */}
    <Alert button={{...}} />
  </>
) : (
  // Non-Empty State - NEW STRUCTURE
  <>
    {/* Entity List */}
    <div className='space-y-2'>...</div>

    {/* Action Buttons - BELOW list */}
    <div className='flex flex-col sm:flex-row gap-2'>
      <Popover>...</Popover>
      <Button onClick={handleRequestNew}>Request New...</Button>
    </div>
  </>
)}
```

---

## Interface Contracts

### Component Props

No changes to component props - all components use same signature:

```typescript
interface {Entity}Props {
  t?: Function; // Optional translation prop (uses useTranslation hook internally)
}
```

### State Management

No new state variables needed. Existing state remains:

- `selectedIds`: Array of selected entity IDs (for Add popover)
- `selected{Entities}`: Array of full entity objects
- `loading`: Boolean for loading states
- `searchTerm`: String for search input

### Function Signatures

**Existing functions (no changes):**

- `handleToggleSelection(entityId)`: Toggle selection in popover
- `handleAddSelected()`: Add selected entities to user
- `handleRemove(entityId)`: Remove entity from user
- `handleRequestNew()`: Open request dialog (used by both Alert button and new button)

**No new functions required** - existing `handleRequestNew()` will be called from new button

### API Contracts

**No API changes** - existing endpoints work as-is:

- `GET /api/{entity}`: Fetch entities (with search)
- `PATCH /api/user`: Update user's entity IDs
- `POST /api/entity_request`: Submit entity request

---

## User Stories

### Story 1: User Has No Entities (Empty State)

**As a** user with no entities
**I want to** see the existing empty state UI
**So that** I understand how to add or request entities

**Acceptance Criteria:**

- Empty state UI remains exactly as currently implemented
- Add button appears above Alert box
- Alert box contains Request button
- No visual or functional changes to empty state

### Story 2: User Adds First Entity

**As a** user
**I want to** add my first entity
**So that** I can start managing entities

**Acceptance Criteria:**

- After adding first entity, empty state disappears
- Entity list appears
- Add button moves below the list
- Request button appears next to Add button
- Alert box no longer appears

### Story 3: User Has Entities (Non-Empty State)

**As a** user with existing entities
**I want to** see Add and Request buttons below my entity list
**So that** I can easily add more entities or request new ones

**Acceptance Criteria:**

- Entity list is displayed
- Add button is below the list (not above)
- Request button appears next to Add button
- Both buttons are side-by-side on desktop
- Alert box does NOT appear

### Story 4: User Wants to Request New Entity (Non-Empty State)

**As a** user with existing entities
**I want to** request an entity that doesn't exist
**So that** administrators can add it

**Acceptance Criteria:**

- Request button is visible next to Add button
- Clicking Request button opens dialog with form
- Form submission creates entity request
- Success notification confirms request submission

### Story 5: User Removes All Entities

**As a** user
**I want to** remove all my entities
**So that** I can see the empty state again

**Acceptance Criteria:**

- After removing last entity, list disappears
- Empty state Alert box reappears
- Add button moves back above Alert box
- Request button disappears (only in Alert box now)
- UI matches original empty state exactly

### Story 6: Mobile User Experience

**As a** mobile user
**I want to** easily access Add and Request functionality
**So that** I can manage entities on mobile devices

**Acceptance Criteria:**

- Buttons stack vertically on small screens (non-empty state)
- Buttons remain easily tappable
- Popover/dialog work well on mobile
- Empty state remains unchanged on mobile

---

## Implementation Steps

### Phase 1: Organizations Component

1. **Read current file** (`organizations.jsx`)
2. **Identify current structure**:

   - Add button section (lines ~390-501)
   - Entity list/Alert conditional (lines ~503-539)
   - Save button (lines ~541-585)

3. **Refactor conditional rendering**:

   - Wrap Add button in conditional: only show ABOVE when `currentOrgs.length === 0`
   - Keep Alert box conditional: only show when `currentOrgs.length === 0`
   - Add new button section: only show when `currentOrgs.length > 0`

4. **Create new button section** (non-empty state):

   - Position after entity list (before Save button)
   - Create flex container: `flex flex-col sm:flex-row gap-2`
   - Add Add button (moved from above)
   - Add Request button next to it

5. **Verify structure**:

   - Empty: Help → Add → Alert → Save
   - Non-empty: Help → List → [Add] [Request] → Save

6. **Test functionality** in both states

### Phase 2: Clubs Component

1. **Apply same changes** as Organizations
2. **Ensure consistency** in styling and behavior
3. **Test functionality**

### Phase 3: SVs Component

1. **Apply same changes** as Organizations
2. **Note**: SVs uses "Boat" terminology in requests
3. **Ensure consistency** in styling and behavior
4. **Test functionality**

### Phase 4: Translation Updates

1. **Review translation files**
2. **Add new translation keys**:
   - `account.organizations.request_new.button`: "Request New Organization"
   - `account.clubs.request_new.button`: "Request New Club"
   - `account.svs.request_new.button`: "Request New Boat"
3. **Verify all text is translatable**

### Phase 5: Testing & Validation

1. **Test empty state** - verify NO changes
2. **Test non-empty state** - verify new layout
3. **Test state transitions** - empty ↔ non-empty
4. **Test mobile responsiveness**
5. **Test accessibility** (keyboard navigation, screen readers)

---

## Diagrams

### Component Structure Diagram

```
Organizations/Clubs/SVs Component
│
├── Help Section (About {Entity})
│
├── Conditional Rendering Block
│   │
│   ├── IF EMPTY (currentOrgs.length === 0):
│   │   ├── [+ Add {Entity}] Button ← ABOVE Alert
│   │   └── Alert Box
│   │       └── [Request to Add {Entity}] Button ← Inside Alert
│   │
│   └── IF NON-EMPTY (currentOrgs.length > 0):
│       ├── Entity List
│       │   └── Each: [Name] [Remove Button]
│       └── Action Buttons Section ← NEW
│           ├── [+ Add {Entity}] Button
│           │   └── Popover
│           └── [Request New {Entity}] Button ← NEW
│               └── Dialog
│
└── Save Button
```

### Layout Diagrams

**Empty State (NO CHANGES):**

```
┌─────────────────────────────────────────┐
│  [About {Entity} Help Section]          │
│                                         │
│  [+ Add {Entity}]                       │ ← Stays here
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ [No {Entity}s Alert Box]          │  │
│  │ └─ [Request to Add {Entity}]      │  │ ← Stays here
│  └───────────────────────────────────┘  │
│                                         │
│  [Save Button]                          │
└─────────────────────────────────────────┘
```

**Non-Empty State (NEW LAYOUT):**

```
┌─────────────────────────────────────────┐
│  [About {Entity} Help Section]          │
│                                         │
│  [List of {Entities}]                   │
│  - Entity 1                    [X]      │
│  - Entity 2                    [X]      │
│                                         │
│  [+ Add {Entity}]  [Request New...]    │ ← NEW location
│                                         │
│  [Save Button]                          │
└─────────────────────────────────────────┘
```

**Mobile View - Non-Empty State (< 640px):**

```
┌────────────────────────────────┐
│  [List of Entities]            │
│  - Entity 1          [X]       │
│  - Entity 2          [X]       │
│                                │
│  [+ Add Organization]          │
│  [Request other Organization]  │ ← Stacked
│                                │
│  [Save]                        │
└────────────────────────────────┘
```

### Data Flow Diagram

```
User Action: Add First Entity
│
├── Empty State → Non-Empty State Transition
│   ├── Alert box disappears
│   ├── Entity list appears
│   ├── Add button moves from above to below list
│   └── Request button appears next to Add button
│
User Action: Remove Last Entity
│
├── Non-Empty State → Empty State Transition
│   ├── Entity list disappears
│   ├── Alert box reappears
│   ├── Add button moves from below to above Alert
│   └── Request button disappears (only in Alert now)
```

### JSX Structure to Implement

```jsx
<Card>
  {/* Help Section */}
  <div className='mb-6'>...</div>

  {/* Conditional Rendering Based on List State */}
  {currentOrgs.length === 0 ? (
    // EMPTY STATE - NO CHANGES
    <>
      {/* Add Button - ABOVE Alert (current position) */}
      <div className='mb-4'>
        <Popover>
          <PopoverTrigger asChild>
            <Button
              text={t('account.organizations.add.button')}
              icon='plus'
              variant='outline'
            />
          </PopoverTrigger>
          <PopoverContent>...</PopoverContent>
        </Popover>
      </div>

      {/* Alert Box - UNCHANGED */}
      <div className='px-4'>
        <Alert
          variant='info'
          title={t('account.organizations.empty_state.title')}
          description={t('account.organizations.empty_state.description')}
          button={{
            text: t('account.organizations.empty_state.button'),
            action: handleRequestNew,
            size: 'full',
            className: 'w-full'
          }}
        />
      </div>
    </>
  ) : (
    // NON-EMPTY STATE - NEW STRUCTURE
    <>
      {/* Entity List */}
      <div className='space-y-2'>
        {currentOrgs.map(org => (
          <div key={org.id} className='flex items-center justify-between p-3 border...'>
            <div>
              <span className='font-medium'>
                {org.acronym ? `${org.acronym} - ` : ''}{org.name}
              </span>
            </div>
            <Button
              variant='ghost'
              icon='x'
              size='sm'
              action={() => handleRemove(org.id)}
            />
          </div>
        ))}
      </div>

      {/* Action Buttons - NEW LOCATION */}
      <div className='mt-4 flex flex-col sm:flex-row gap-2'>
        {/* Add Button - MOVED HERE */}
        <Popover>
          <PopoverTrigger asChild>
            <Button
              text={t('account.organizations.add.button')}
              icon='plus'
              variant='outline'
              className='flex-1'
            />
          </PopoverTrigger>
          <PopoverContent>...</PopoverContent>
        </Popover>

        {/* Request Button - NEW */}
        <Button
          text={t('account.organizations.request_new.button')}
          icon='message-square'
          variant='outline'
          onClick={handleRequestNew}
          className='flex-1'
        />
      </div>
    </>
  )}

  {/* Save Button */}
  <div className='mt-6 px-4'>
    <Button text={t('account.organizations.save')} ... />
  </div>
</Card>
```

---

## Questions for Clarification

### 1. Button Text for Request Button (Non-Empty State)

**Question**: What exact text should the Request button display when list is non-empty?

- **Option A**: "Request other Organization" / "Request other Club" / "Request other Boat"
- **Option B**: "Request to Add Organization" (same as Alert button)
- **Option C**: "Request New Organization" (shorter) ✅ **SELECTED**
- **Option D**: Use existing translation key `account.{entity}.request.button`

### 2. Translation Key Strategy

**Question**: Should we create new translation keys or reuse existing ones?

- **Option A**: Create new key: `account.{entity}.request_new.button` ✅ **SELECTED**
- **Option B**: Reuse existing: `account.{entity}.request.button`
- **Option C**: Use existing with different context

### 3. Button Icon Selection

**Question**: What icon should the Request button use (non-empty state)?

- **Option A**: Same as Add (`plus`)
- **Option B**: `file-plus` (document with plus)
- **Option C**: `message-square` (request/communication)
- **Option D**: `help-circle` (help/request)

**Recommendation**: Option B (`file-plus`) to differentiate while maintaining clarity

### 4. Button Styling Consistency

**Question**: Should Request button match Add button styling exactly?

- **Option A**: Same style (`variant='outline'`, same colors)
- **Option B**: Slightly different (`variant='secondary'`)
- **Option C**: Different color scheme

**Recommendation**: Option A - Consistency is important, differentiation via text/icon is sufficient

### 5. Button Spacing & Layout

**Question**: What spacing/gap between the two buttons (non-empty state)?

- **Option A**: Default gap (gap-2 = 0.5rem)
- **Option B**: Larger gap (gap-4 = 1rem)
- **Option C**: Equal width buttons (flex-1 each)

**Recommendation**: Option A with Option C (equal width for visual balance)

### 6. Mobile Breakpoint

**Question**: At what screen width should buttons stack vertically?

- **Option A**: `sm` breakpoint (640px) - standard Tailwind
- **Option B**: `md` breakpoint (768px) - tablets
- **Option C**: Custom breakpoint

**Recommendation**: Option A (sm = 640px)

### 7. Button Order

**Question**: Which button should be on the left (non-empty state)?

- **Option A**: Add on left, Request on right (primary action first)
- **Option B**: Request on left, Add on right (less common action first)

**Recommendation**: Option A (Add left, Request right) - primary action first

### 8. State Transition Animation

**Question**: Should there be animation when transitioning between empty/non-empty states?

- **Option A**: No animation (instant change)
- **Option B**: Fade transition
- **Option C**: Slide transition

**Implementation Note**: Slide transition will be implemented using CSS transitions or React animation library for smooth state changes

### 9. Accessibility

**Question**: Any specific accessibility requirements for the conditional buttons?

- **Option A**: Standard button accessibility (already handled by Button component)
- **Option B**: Additional ARIA labels needed?
- **Option C**: Focus management important?

**Recommendation**: Option A - Button component should handle this, but verify focus management during state transitions

### 10. Empty State Verification

**Question**: How should we verify the empty state remains unchanged?

- **Option A**: Visual regression testing (screenshot comparison)
- **Option B**: Manual testing checklist
- **Option C**: Automated tests comparing DOM structure

**Recommendation**: Option B + Option A - Manual verification with screenshot comparison

---

## Testing Strategy

### Unit Testing

**Components to Test:**

1. Organizations component conditional rendering
2. Clubs component conditional rendering
3. SVs component conditional rendering

**Test Cases:**

- Empty state renders Add button above Alert
- Empty state renders Alert box with Request button
- Non-empty state renders entity list
- Non-empty state renders Add button below list
- Non-empty state renders Request button next to Add button
- Non-empty state does NOT render Alert box
- State transitions work correctly (empty ↔ non-empty)

### Integration Testing

**User Flows to Test:**

1. **Empty State Flow**: User with no entities → Verify UI matches reference image exactly
2. **Add First Entity Flow**: Empty → Add entity → Verify transition to non-empty state
3. **Non-Empty State Flow**: User with entities → Verify new button layout
4. **Request Flow**: Non-empty state → Click Request → Fill form → Submit → Verify
5. **Remove Last Entity Flow**: Non-empty → Remove last → Verify transition to empty state
6. **Mobile Flow**: Mobile view → Verify button stacking → Test interactions

### Visual Regression Testing

**Screenshots to Compare:**

- Organizations page (empty state) - MUST match reference image exactly
- Organizations page (non-empty state) - Verify new layout
- Clubs page (empty state) - Verify unchanged
- Clubs page (non-empty state) - Verify new layout
- SVs page (empty state) - Verify unchanged
- SVs page (non-empty state) - Verify new layout
- Mobile views of all above

### Accessibility Testing

**Checks:**

- Keyboard navigation (Tab order)
- Screen reader announcements
- Focus management during state transitions
- ARIA labels (if needed)
- Button accessibility in both states

### State Transition Testing

**Critical Test Cases:**

1. Add first entity → Verify empty → non-empty transition
2. Remove last entity → Verify non-empty → empty transition
3. Multiple add/remove operations → Verify state consistency
4. Page refresh in empty state → Verify UI unchanged
5. Page refresh in non-empty state → Verify new layout

---

## Risk Assessment

### Low Risk

✅ **Empty State Preservation**: Simple conditional rendering ensures no changes
✅ **Non-Empty State Changes**: Straightforward button repositioning
✅ **No Backend Changes**: No API modifications needed
✅ **Existing Functionality**: All handlers already exist

### Medium Risk

⚠️ **State Transition Logic**: Need to ensure smooth transitions between states
⚠️ **Conditional Rendering Complexity**: Multiple conditionals need careful testing
⚠️ **Consistency**: Three components must match exactly
⚠️ **Mobile Responsiveness**: Need to test button stacking

### High Risk

🔴 **Empty State Verification**: Critical that empty state remains unchanged - requires thorough visual testing

### Mitigation Strategies

1. **Incremental Implementation**: Do one component first, verify empty state unchanged, then replicate
2. **Visual Regression Testing**: Screenshot comparison for empty state
3. **State Transition Testing**: Thorough testing of empty ↔ non-empty transitions
4. **Component Extraction**: Consider creating shared button group component (future refactor)
5. **User Acceptance Testing**: Verify empty state matches reference image exactly

---

## Future Considerations

### Potential Refactoring Opportunities

1. **Shared Component**: Extract conditional button group into reusable component

   ```jsx
   <EntityActionButtons
     isEmpty={currentOrgs.length === 0}
     addButtonText={t("account.{entity}.add.button")}
     requestButtonText={t("account.{entity}.request.button")}
     requestNewButtonText={t("account.{entity}.request_new.button")}
     onAddClick={handleAddClick}
     onRequestClick={handleRequestNew}
   />
   ```

2. **Custom Hook**: Extract common logic into `useEntityManagement` hook

   - State management
   - API calls
   - Selection handling
   - Conditional rendering logic

3. **TypeScript Migration**: Add types for better IDE support and type safety

### Not in Scope (But Worth Noting)

- Creating shared component (can be future refactor)
- Changing API contracts
- Modifying request submission flow
- Adding new features to request dialog
- Changing empty state design

---

## Summary

This implementation plan outlines a **conditional UI reorganization** that:

- ✅ **Preserves empty state exactly** - No changes when user has no entities
- ✅ **Improves non-empty state UX** - Better button placement when user has entities
- ✅ **Maintains all existing functionality** - No breaking changes
- ✅ **Requires no backend changes** - Frontend-only modification
- ✅ **Affects three similar components** - Consistent pattern across all

**Key Implementation Points:**

1. Empty state: Conditional rendering keeps current structure
2. Non-empty state: Conditional rendering shows new button layout
3. State transitions: Smooth switching between states
4. Visual verification: Empty state must match reference image exactly

**Key Implementation Decisions Made:**

✅ **Button Text**: "Request New {Entity}" (shorter, clear)
✅ **Translation Keys**: New keys `account.{entity}.request_new.button`
✅ **Icon**: `message-square` (request/communication)
✅ **Styling**: Same as Add button (`variant='outline'`)
✅ **Layout**: Equal width buttons (`flex-1` each)
✅ **Mobile**: Stack at `sm` breakpoint (640px)
✅ **Order**: Add left, Request right
✅ **Animation**: Slide transition for state changes
✅ **Accessibility**: Standard Button component handling
✅ **Testing**: Visual regression testing for empty state

**Next Steps:**

1. ✅ Design decisions approved
2. ⏳ Awaiting explicit command to proceed with implementation
3. ⏳ Implementation will follow this plan exactly

---

## Document History

- **Created**: [Current Date]
- **Author**: AI Assistant
- **Status**: Planning Complete - Design Decisions Made - Ready for Implementation
- **Last Updated**: [Current Date]
- **Revision**:
  - Updated to reflect conditional UI behavior based on empty/non-empty state
  - Design decisions documented (10 questions answered)
  - Implementation details finalized
