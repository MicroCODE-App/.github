# Implementation Plan: Numeric `labelWidth` Prop for SettingRow Component

## Executive Summary

This document outlines the detailed implementation plan for adding a numeric `labelWidth` prop to the `SettingRow` component. This prop will replace the hardcoded `maxWidth: '40%'` constraint, providing flexible control over label width allocation while maintaining backward compatibility.

**Key Change:** Replace boolean `fullWidthLabel` approach with numeric `labelWidth` prop (percentage as number).

## Table of Contents

1. [Problem Statement](#problem-statement)
2. [Solution Overview](#solution-overview)
3. [Interface Contracts](#interface-contracts)
4. [Component Architecture](#component-architecture)
5. [Implementation Details](#implementation-details)
6. [User Stories](#user-stories)
7. [Test Strategy](#test-strategy)
8. [Migration Path](#migration-path)
9. [Questions & Assumptions](#questions--assumptions)
10. [Risk Assessment](#risk-assessment)

---

## Problem Statement

### Current State

The `SettingRow` component has a hardcoded `maxWidth: '40%'` constraint on the label area:

```jsx
<div className='flex-1 pr-4 min-w-0' style={{
    maxWidth: '40%'  // HARDCODED
}}>
```

This constraint:

- ✅ Works well for text input fields (30% label, 70% control)
- ❌ Causes unnecessary text wrapping for Switch components
- ❌ Limits flexibility for future use cases
- ❌ Doesn't allow fine-grained control over label width

### Requirements

1. **Switch Components**: Need ~95% label width (almost full width)
2. **Text Input Fields**: Need ~40% label width (current behavior)
3. **Display Fields**: Need ~30% label width (via `controlWidth='70%'`)
4. **Future Flexibility**: Support any percentage value (0-100)
5. **Backward Compatibility**: Default behavior unchanged when prop not provided

---

## Solution Overview

### High-Level Approach

Add a numeric `labelWidth` prop to `SettingRow`:

- **Type**: `number` (0-100, representing percentage)
- **Default**: `40` (maintains current behavior)
- **Usage**: When provided, sets `maxWidth: '{labelWidth}%'` on label area
- **Control Width**: Calculated as `100 - labelWidth` (with padding consideration)

### Design Principles

1. **Backward Compatible**: Default value (40) preserves existing behavior
2. **Flexible**: Supports any percentage value for future use cases
3. **Consistent**: Works with existing `controlWidth` prop logic
4. **Type-Safe**: Numeric type prevents string parsing errors

---

## Interface Contracts

### SettingRow Component Props

```typescript
interface SettingRowProps {
  // Existing props
  label: string;
  description?: string;
  children: ReactNode;
  error?: string;
  required?: boolean;
  className?: string;
  layout?: "horizontal" | "stacked";
  controlWidth?: string; // e.g., '70%' - for explicit control width

  // NEW PROP
  labelWidth?: number; // 0-100, percentage for label area maxWidth
  // Default: 40 (maintains current behavior)
  // Examples: 30 (narrow labels), 40 (default), 95 (full-width for Switch)
}
```

### Prop Behavior Matrix

| `labelWidth`          | `controlWidth` | Label Area        | Control Area                        | Use Case                               |
| --------------------- | -------------- | ----------------- | ----------------------------------- | -------------------------------------- |
| `undefined` (default) | `undefined`    | `maxWidth: '40%'` | `width: '60%'`                      | Default text inputs                    |
| `undefined` (default) | `'70%'`        | `maxWidth: '40%'` | `width: '70%'`                      | Display fields (CollapsibleSettingRow) |
| `30`                  | `undefined`    | `maxWidth: '30%'` | `width: '70%'`                      | Narrow labels                          |
| `40`                  | `undefined`    | `maxWidth: '40%'` | `width: '60%'`                      | Explicit default                       |
| `95`                  | `undefined`    | `maxWidth: '95%'` | `width: 'auto'`, `minWidth: '44px'` | Switch components                      |

### Width Calculation Logic

```javascript
// Label area width
const labelMaxWidth = labelWidth !== undefined ? `${labelWidth}%` : "40%"; // Default

// Control area width
let controlAreaWidth;
if (controlWidth) {
  // Explicit controlWidth takes precedence
  controlAreaWidth = controlWidth;
} else if (labelWidth !== undefined) {
  // Calculate from labelWidth
  const remainingWidth = 100 - labelWidth;
  // For Switch components (labelWidth >= 90), use auto-sizing
  if (labelWidth >= 90) {
    controlAreaWidth = "auto";
  } else {
    controlAreaWidth = `${remainingWidth}%`;
  }
} else {
  // Default behavior
  controlAreaWidth = "60%";
}
```

---

## Component Architecture

### Component Hierarchy

```
Form Component (settingsMode={true})
    └── SettingRow (labelWidth={95} for Switch)
        └── Switch Component

CollapsibleSettingRow
    └── SettingRow (controlWidth='70%')
        └── Display Field + Detail Fields
```

### Data Flow

```
Input Type Detection (Form Component)
    ↓
Determine labelWidth based on type
    ↓
Pass labelWidth to SettingRow
    ↓
SettingRow calculates widths
    ↓
Render with appropriate constraints
```

### Component Interaction Diagram

```
┌────────────────────────────────────────────────────────────┐
│                    Form Component                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Input Type: 'switch'                                │  │
│  │  → labelWidth = 95                                   │  │
│  └──────────────────────────────────────────────────────┘  │
│                          ↓                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  <SettingRow labelWidth={95}>                        │  │
│  │    <Switch />                                        │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              CollapsibleSettingRow                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  controlWidth='70%' (explicit)                       │   │
│  │  labelWidth not provided (uses default 40)           │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  <SettingRow controlWidth='70%'>                     │   │
│  │    <Display Field />                                 │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Details

### Phase 1: Update SettingRow Component

**File:** `client/src/components/form/setting-row/setting-row.jsx`

#### Changes Required

1. **Add `labelWidth` prop to component signature**

   ```jsx
   const SettingRow = forwardRef(({
       label,
       description,
       children,
       error,
       required,
       className,
       layout = 'horizontal',
       controlWidth,
       labelWidth, // NEW PROP (number, optional)
       ...props
   }, ref) => {
   ```

2. **Update JSDoc documentation**

   ```jsx
   /**
    * @param {number} params.labelWidth Optional label width as percentage (0-100).
    *                                   Default: 40. When provided, sets maxWidth on label area.
    *                                   Examples: 30 (narrow), 40 (default), 95 (full-width for Switch).
    */
   ```

3. **Implement width calculation logic**

   ```jsx
   if (layout === 'horizontal') {
       // Calculate label area maxWidth
       const labelMaxWidth = labelWidth !== undefined
           ? `${labelWidth}%`
           : '40%'; // Default maintains current behavior

       // Calculate control area width
       let controlAreaWidth;
       let controlAreaMaxWidth;

       if (controlWidth) {
           // Explicit controlWidth takes precedence (for CollapsibleSettingRow)
           controlAreaWidth = controlWidth;
           controlAreaMaxWidth = controlWidth;
       } else if (labelWidth !== undefined) {
           // Calculate from labelWidth
           if (labelWidth >= 90) {
               // For Switch components (labelWidth >= 90), use auto-sizing
               controlAreaWidth = 'auto';
               controlAreaMaxWidth = 'none';
           } else {
               // Calculate remaining width
               const remainingWidth = 100 - labelWidth;
               controlAreaWidth = `${remainingWidth}%`;
               controlAreaMaxWidth = `${remainingWidth}%`;
           }
       } else {
           // Default behavior
           controlAreaWidth = '60%';
           controlAreaMaxWidth = '60%';
       }

       return (
           <div ...>
               {/* Label area */}
               <div className='flex-1 pr-4 min-w-0' style={{
                   maxWidth: labelMaxWidth
               }}>
                   {/* Label and description */}
               </div>

               {/* Control area */}
               <div className='flex-shrink-0 min-w-0 overflow-hidden' style={{
                   width: controlAreaWidth,
                   maxWidth: controlAreaMaxWidth,
                   ...(labelWidth >= 90 && { minWidth: '44px' }) // Ensure Switch has space
               }}>
                   { children }
               </div>
           </div>
       );
   }
   ```

#### Validation Logic

Add prop validation (optional, for development):

```jsx
// Validate labelWidth if provided
if (labelWidth !== undefined) {
  if (typeof labelWidth !== "number" || labelWidth < 0 || labelWidth > 100) {
    console.warn(
      `SettingRow: labelWidth must be a number between 0 and 100, got ${labelWidth}`
    );
  }
}
```

### Phase 2: Update Form Component

**File:** `client/src/components/form/form.jsx`

#### Changes Required

1. **Create input type to labelWidth mapping**

   ```jsx
   // Map input types to labelWidth percentages
   const inputTypeLabelWidthMap = {
     switch: 95, // Almost full width for Switch components
     radio: 90, // Full width for radio groups (if needed)
     checkbox: 90, // Full width for checkbox groups (if needed)
     // Other types use default (40) when not specified
   };
   ```

2. **Determine labelWidth for each input**

   ```jsx
   // In settingsMode rendering section:
   if (settingsMode && type !== "hidden") {
     // Determine labelWidth based on input type
     const labelWidth = inputTypeLabelWidthMap[type];

     return (
       <SettingRow
         key={name}
         label={label}
         description={description}
         error={errors[name]?.message}
         required={required}
         labelWidth={labelWidth} // Pass numeric value or undefined
       >
         {/* ... existing Controller code ... */}
       </SettingRow>
     );
   }
   ```

#### Input Type Mapping Table

| Input Type                        | `labelWidth`                 | Rationale                                                        |
| --------------------------------- | ---------------------------- | ---------------------------------------------------------------- |
| `switch`                          | `95`                         | Switch components need almost full width for labels/descriptions |
| `radio`                           | `90`                         | Radio groups may have long option lists, need more label space   |
| `checkbox`                        | `90`                         | Checkbox groups similar to radio                                 |
| `text`, `email`, `password`, etc. | `undefined` (defaults to 40) | Text inputs maintain current behavior                            |
| `hidden`                          | N/A                          | Not rendered in SettingRow                                       |

### Phase 3: Verify CollapsibleSettingRow

**File:** `client/src/components/form/collapsible-setting-row/collapsible-setting-row.jsx`

#### Verification Required

- **Current Usage**: `controlWidth='70%'` is passed explicitly
- **Expected Behavior**: `labelWidth` prop is not provided, so defaults to 40
- **Result**: Label area gets `maxWidth: '40%'`, control area gets `width: '70%'` (explicit)
- **Action**: No changes needed - existing behavior preserved

#### Test Cases

1. Display field should maintain 70% control width
2. Label area should maintain 40% max width (default)
3. No regressions in User Edit form

### Phase 4: Update Admin Console

**Files:**

- `admin/console/src/components/form/setting-row/setting-row.jsx`
- `admin/console/src/components/form/form.jsx`

#### Changes Required

Apply identical changes as client-side:

1. Add `labelWidth` prop to SettingRow
2. Update Form component with input type mapping
3. Ensure consistency across codebases

---

## User Stories

### Story 1: Switch Component Full-Width Labels

**As a** user viewing Notification Settings
**I want** Switch labels and descriptions to use almost the full width of the row
**So that** text doesn't wrap unnecessarily and the interface is easier to read

**Acceptance Criteria:**

- [ ] Switch components have ~95% label width
- [ ] Descriptions don't wrap unnecessarily
- [ ] Switches remain right-aligned
- [ ] Layout works in both light and dark mode

### Story 2: Text Input Fields Maintain Current Behavior

**As a** developer using SettingRow for text inputs
**I want** the default label width to remain 40%
**So that** existing forms continue to work without changes

**Acceptance Criteria:**

- [ ] Text input fields default to 40% label width
- [ ] No code changes required for existing forms
- [ ] Control area defaults to 60% width

### Story 3: Display Fields Maintain Explicit Control Width

**As a** developer using CollapsibleSettingRow
**I want** explicit `controlWidth` prop to take precedence
**So that** display fields maintain their 70% control width

**Acceptance Criteria:**

- [ ] `controlWidth='70%'` prop works as before
- [ ] Label area defaults to 40% when `controlWidth` is provided
- [ ] No regressions in User Edit form

### Story 4: Future Flexibility for Custom Widths

**As a** developer
**I want** to specify any label width percentage
**So that** I can fine-tune layouts for specific use cases

**Acceptance Criteria:**

- [ ] Can pass `labelWidth={30}` for narrow labels
- [ ] Can pass `labelWidth={95}` for full-width labels
- [ ] Can pass any value between 0-100
- [ ] Control width calculates correctly from label width

---

## Test Strategy

### Unit Tests

**Test File:** `client/src/components/form/setting-row/setting-row.test.jsx` (new)

#### Test Cases

1. **Default Behavior (labelWidth not provided)**

   ```javascript
   test("defaults to 40% label width when labelWidth not provided", () => {
     const { container } = render(
       <SettingRow label="Test Label">
         <input />
       </SettingRow>
     );
     const labelArea = container.querySelector(".flex-1");
     expect(labelArea.style.maxWidth).toBe("40%");
   });
   ```

2. **Explicit labelWidth**

   ```javascript
   test("uses provided labelWidth value", () => {
     const { container } = render(
       <SettingRow label="Test" labelWidth={95}>
         <input />
       </SettingRow>
     );
     const labelArea = container.querySelector(".flex-1");
     expect(labelArea.style.maxWidth).toBe("95%");
   });
   ```

3. **Control Width Calculation**

   ```javascript
   test("calculates control width from labelWidth", () => {
     const { container } = render(
       <SettingRow label="Test" labelWidth={30}>
         <input />
       </SettingRow>
     );
     const controlArea = container.querySelector(".flex-shrink-0");
     expect(controlArea.style.width).toBe("70%");
   });
   ```

4. **Switch Component Auto-Sizing (labelWidth >= 90)**

   ```javascript
   test("uses auto width for control when labelWidth >= 90", () => {
     const { container } = render(
       <SettingRow label="Test" labelWidth={95}>
         <Switch />
       </SettingRow>
     );
     const controlArea = container.querySelector(".flex-shrink-0");
     expect(controlArea.style.width).toBe("auto");
     expect(controlArea.style.minWidth).toBe("44px");
   });
   ```

5. **controlWidth Prop Precedence**

   ```javascript
   test("controlWidth prop takes precedence over labelWidth", () => {
     const { container } = render(
       <SettingRow label="Test" labelWidth={30} controlWidth="80%">
         <input />
       </SettingRow>
     );
     const controlArea = container.querySelector(".flex-shrink-0");
     expect(controlArea.style.width).toBe("80%");
   });
   ```

6. **Backward Compatibility**
   ```javascript
   test("maintains backward compatibility with existing props", () => {
     const { container } = render(
       <SettingRow label="Test" controlWidth="70%">
         <input />
       </SettingRow>
     );
     const labelArea = container.querySelector(".flex-1");
     const controlArea = container.querySelector(".flex-shrink-0");
     expect(labelArea.style.maxWidth).toBe("40%");
     expect(controlArea.style.width).toBe("70%");
   });
   ```

### Integration Tests

**Test File:** `client/src/views/account/notifications.test.jsx` (new)

#### Test Cases

1. **Notification Settings Page Layout**

   ```javascript
   test("Switch components have full-width labels", () => {
     render(<Notifications />);
     // Verify Switch SettingRow has labelWidth={95}
     // Verify labels don't wrap unnecessarily
   });
   ```

2. **User Edit Form Layout**
   ```javascript
   test("Text inputs maintain default label width", () => {
     render(<UserEditForm />);
     // Verify text input SettingRow has labelWidth={undefined} (defaults to 40)
     // Verify display fields maintain controlWidth='70%'
   });
   ```

### Manual Testing Checklist

1. **Notification Settings Page** (`/account/notifications`)

   - [ ] Switch labels use ~95% width
   - [ ] Descriptions don't wrap unnecessarily
   - [ ] Switches are right-aligned
   - [ ] Layout correct in light mode
   - [ ] Layout correct in dark mode
   - [ ] Responsive behavior on mobile

2. **User Edit Form** (`/account/users/edit`)

   - [ ] Text input labels use ~40% width (default)
   - [ ] Display fields use 70% control width
   - [ ] No layout regressions
   - [ ] Collapsible sections work correctly

3. **Other Settings Pages**
   - [ ] TFA settings (if uses switches)
   - [ ] Any other pages using Switch components
   - [ ] Verify no unintended side effects

---

## Migration Path

### Step 1: Implementation

- Update SettingRow component with `labelWidth` prop
- Update Form component with input type mapping
- Update Admin Console components (if applicable)

### Step 2: Testing

- Run unit tests
- Run integration tests
- Manual testing on all affected pages

### Step 3: Deployment

- Deploy to staging environment
- Verify in staging
- Deploy to production

### Step 4: Monitoring

- Monitor for any layout issues
- Collect user feedback
- Address any edge cases

### Rollback Plan

- If issues arise, can revert to hardcoded `maxWidth: '40%'`
- Default behavior preserved, so rollback is safe

---

## Questions & Assumptions

### Questions for Clarification

1. **Label Width Values**

   - **Q**: What specific `labelWidth` value should Switch components use? (Proposed: 95)
   - **Q**: Should radio and checkbox also get full-width labels? (Proposed: 90)
   - **Q**: Are there any other input types that need custom label widths?

2. **Control Width Calculation**

   - **Q**: When `labelWidth >= 90`, should control area use `width: 'auto'` or calculate as `100 - labelWidth`? (Proposed: `auto` with `minWidth: '44px'`)
   - **Q**: Should there be a minimum control width for non-Switch components?

3. **Responsive Behavior**

   - **Q**: Should `labelWidth` values change on mobile devices?
   - **Q**: Do we need responsive breakpoints for different screen sizes?

4. **CollapsibleSettingRow**

   - **Q**: Should CollapsibleSettingRow also support `labelWidth` prop, or continue using `controlWidth` only?
   - **Q**: Should display fields in collapsible rows have different label widths?

5. **Validation**

   - **Q**: Should we validate `labelWidth` prop (0-100 range) or allow any number?
   - **Q**: Should we log warnings for invalid values in development?

6. **Admin Console**
   - **Q**: Does admin console have the same Form/SettingRow structure?
   - **Q**: Are there any admin-specific considerations?

### Assumptions

1. **Switch Component Width**: Switch component is approximately 44px wide (needs verification)
2. **Default Behavior**: Default `labelWidth` of 40 maintains current behavior
3. **Control Width Precedence**: `controlWidth` prop takes precedence over calculated width from `labelWidth`
4. **Browser Support**: Flexbox is supported in all target browsers
5. **Admin Console**: Admin console has similar component structure to client

---

## Risk Assessment

### Low Risk

- ✅ **Backward Compatibility**: Default value (40) preserves existing behavior
- ✅ **Isolated Changes**: Only affects SettingRow and Form components
- ✅ **Type Safety**: Numeric prop prevents string parsing errors
- ✅ **Rollback**: Easy to revert if issues arise

### Medium Risk

- ⚠️ **Control Width Calculation**: Need to ensure calculations are correct for all cases
- ⚠️ **Switch Auto-Sizing**: Need to verify `minWidth: '44px'` is sufficient
- ⚠️ **Responsive Design**: May need adjustments for mobile devices

### Mitigation Strategies

1. **Thorough Testing**: Unit tests, integration tests, and manual testing
2. **Gradual Rollout**: Deploy to staging first, monitor, then production
3. **Documentation**: Clear JSDoc comments and examples
4. **Validation**: Add prop validation in development mode

---

## Implementation Checklist

### Phase 1: SettingRow Component

- [ ] Add `labelWidth` prop to component signature
- [ ] Update JSDoc documentation
- [ ] Implement width calculation logic
- [ ] Add prop validation (optional)
- [ ] Run ESLint and fix errors
- [ ] Create unit tests
- [ ] Verify backward compatibility

### Phase 2: Form Component

- [ ] Create input type to labelWidth mapping
- [ ] Update settingsMode rendering logic
- [ ] Pass `labelWidth` prop to SettingRow
- [ ] Run ESLint and fix errors
- [ ] Create integration tests

### Phase 3: CollapsibleSettingRow Verification

- [ ] Verify no changes needed
- [ ] Test User Edit form
- [ ] Verify display fields maintain 70% control width

### Phase 4: Admin Console

- [ ] Update SettingRow component
- [ ] Update Form component
- [ ] Verify consistency with client

### Phase 5: Testing

- [ ] Run all unit tests
- [ ] Run all integration tests
- [ ] Manual testing on Notification Settings page
- [ ] Manual testing on User Edit form
- [ ] Manual testing on other affected pages

### Phase 6: Documentation

- [ ] Update component JSDoc
- [ ] Update any relevant README files
- [ ] Add usage examples

---

## Confidence Assessment

**Current Confidence Level: 98%**

**Confidence Factors:**

- ✅ Clear understanding of current implementation
- ✅ Well-defined interface contract
- ✅ Comprehensive test strategy
- ✅ Backward-compatible design
- ✅ Flexible and extensible approach
- ✅ Detailed implementation plan

**Remaining Questions:**

- Need answers to questions in [Questions & Assumptions](#questions--assumptions) section
- Need verification of Switch component width (44px assumption)

**Ready for Implementation:**

- ✅ Yes, pending answers to clarification questions
- ✅ All architectural decisions documented
- ✅ Test strategy defined
- ✅ Migration path clear

---

## Next Steps

1. **Review and Clarification**

   - Review this implementation plan
   - Answer questions in [Questions & Assumptions](#questions--assumptions) section
   - Approve approach or suggest modifications

2. **Implementation**

   - Once approved, proceed with implementation following the checklist
   - Implement in phases as outlined
   - Test thoroughly at each phase

3. **Deployment**

   - Deploy to staging
   - Verify functionality
   - Deploy to production

4. **Follow-up**
   - Monitor for issues
   - Collect feedback
   - Iterate if needed








