# Team Portal - Diagnosis Report

## Problem Summary
The team portal is "not reflecting correctly" - changes made to team data don't appear in the UI without manual refresh, and some data may not persist at all.

## Root Causes Identified

### 1. Missing `useTeam` Hook ❌
**Location:** `kaa-app/src/hooks/`

Unlike other features (projects, deliverables, messages, etc.) that have dedicated React Query hooks with proper cache management, the team feature has **no dedicated hook**.

| Feature | Has Hook | Cache Invalidation |
|---------|----------|-------------------|
| Projects | ✅ useProjects | ✅ Automatic |
| Deliverables | ✅ useDeliverables | ✅ Automatic |
| Messages | ✅ useMessages | ✅ Automatic |
| **Team** | ❌ None | ❌ None |

### 2. TeamLogin Uses Hardcoded Demo Data ❌
**Location:** `kaa-app/src/components/TeamLogin.tsx`

```typescript
// PROBLEM: Hardcoded credentials, not connected to API
const demoTeamMembers: { [key: string]: { role: string; password: string } } = {
  'alex': { role: 'Project Manager', password: 'team123' },
  'sarah': { role: 'Designer', password: 'team123' },
  'mike': { role: 'Developer', password: 'team123' },
  'demo': { role: 'Project Manager', password: 'demo123' }
};
```

**Impact:** Team members cannot authenticate with real credentials.

### 3. TeamDashboard Uses Demo Data ❌
**Location:** `kaa-app/src/components/TeamDashboard.tsx`

The `loadTeamData()` function populates state with fake/demo data instead of fetching from the API.

**Impact:** Dashboard shows placeholder data, not real team information.

### 4. TeamManagement Uses Raw fetch() ❌
**Location:** `kaa-app/src/components/TeamManagement.tsx`

Uses direct `fetch()` calls with `localStorage` token management instead of the React Query pattern.

```typescript
// PROBLEM: No automatic cache invalidation
const response = await fetch('/api/team/members', {
  headers: { Authorization: `Bearer ${localStorage.getItem('token')}` }
});
```

**Impact:** After mutations (add member, change role, etc.), the UI doesn't automatically refresh.

### 5. No Real-time Updates ❌
The team portal doesn't integrate with `useRealtimeNotifications` or WebSocket events for team changes.

**Impact:** Multi-user scenarios don't sync (e.g., Admin A adds member, Admin B doesn't see it).

---

## Data Flow Comparison

### Current (Broken) Flow:
```
User Action → fetch() → API → Response → Manual setState()
                                              ↓
                                    UI doesn't update on re-fetch
                                    Other components don't know
```

### Expected (Working) Flow:
```
User Action → useMutation() → API → Response → Cache Invalidation
                                                      ↓
                                              All useQuery() hooks refetch
                                              All components update
```

---

## Fix Strategy

1. **Create `useTeam.ts` hook** - Following the established pattern with React Query
2. **Update `TeamLogin.tsx`** - Use real auth API endpoints
3. **Update `TeamDashboard.tsx`** - Replace demo data with hook
4. **Update `TeamManagement.tsx`** - Replace fetch() with mutations
5. **Add WebSocket integration** - For real-time team updates

---

## Files to Modify

| File | Change Type | Priority |
|------|-------------|----------|
| `kaa-app/src/hooks/useTeam.ts` | **CREATE** | P0 |
| `kaa-app/src/hooks/index.ts` | UPDATE (export) | P0 |
| `kaa-app/src/components/TeamLogin.tsx` | UPDATE | P1 |
| `kaa-app/src/components/TeamDashboard.tsx` | UPDATE | P1 |
| `kaa-app/src/components/TeamManagement.tsx` | UPDATE | P1 |

---

## Testing Checklist

After applying fixes:
- [ ] Team login works with real credentials
- [ ] Team dashboard shows real data
- [ ] Adding a team member reflects immediately
- [ ] Changing a role reflects immediately
- [ ] Removing a member reflects immediately
- [ ] Multiple browser tabs stay in sync
- [ ] Page refresh shows current state
