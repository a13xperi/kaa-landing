# Next Steps - Implementation Roadmap

This document outlines the remaining implementation tasks for the KAA platform.

---

## 1. Google OAuth - App Integration

**Status:** Backend fixes in PR #82 (CI passing, ready to merge)

### What's Done
- TypeScript fixes for Google OAuth service (`googleAuthService.ts`)
- Metrics tracking for `google_login` and `google_token` events
- Type assertions for Google API responses

### What's Needed

#### A. Merge PR #82
```bash
# Merge the TypeScript fixes
gh pr merge 82 --merge
```

#### B. Frontend Google Sign-In Button

Add to `kaa-app/src/components/auth/LoginForm.tsx`:

```typescript
import { GoogleLogin } from '@react-oauth/google';

// In the component:
<GoogleLogin
  onSuccess={(credentialResponse) => {
    // Send to backend
    fetch('/api/auth/google', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: credentialResponse.credential }),
    })
      .then(res => res.json())
      .then(data => {
        localStorage.setItem('token', data.token);
        navigate('/dashboard');
      });
  }}
  onError={() => console.error('Google Login Failed')}
/>
```

#### C. Google OAuth Provider Setup

Wrap app in `kaa-app/src/main.tsx`:

```typescript
import { GoogleOAuthProvider } from '@react-oauth/google';

<GoogleOAuthProvider clientId={import.meta.env.VITE_GOOGLE_CLIENT_ID}>
  <App />
</GoogleOAuthProvider>
```

#### D. Environment Variables

```bash
# kaa-app/.env
VITE_GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com

# server/.env
GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_client_secret
```

#### E. Testing Checklist
- [ ] Google Sign-In button renders on login page
- [ ] Clicking button opens Google consent screen
- [ ] Successful auth creates/finds user in database
- [ ] JWT tokens issued correctly
- [ ] User redirected to dashboard
- [ ] Metrics recorded (`google_login` event)

---

## 2. Karen & Pam Admin View

**Purpose:** Filtered view within existing admin portal for key stakeholders (Karen & Pam) to efficiently manage clients and review documents.

### Concept

This is NOT a separate admin portal, but rather:
- A **preset filter/view** in the existing admin dashboard
- Optimized for stakeholder workflows
- Quick access to high-priority items

### Implementation Options

#### Option A: Saved Filter Presets (Recommended)

Add filter presets to the admin dashboard that Karen & Pam can quickly apply:

```typescript
// kaa-app/src/components/admin/FilterPresets.tsx

interface FilterPreset {
  id: string;
  name: string;
  icon: string;
  filters: {
    status?: string[];
    tier?: number[];
    assignedTo?: string[];
    dateRange?: { start: Date; end: Date };
    priority?: string[];
  };
}

const STAKEHOLDER_PRESETS: FilterPreset[] = [
  {
    id: 'pending-review',
    name: 'Pending My Review',
    icon: '📋',
    filters: {
      status: ['PENDING_REVIEW', 'AWAITING_APPROVAL'],
      assignedTo: ['karen', 'pam'], // Or by user ID
    },
  },
  {
    id: 'high-value-clients',
    name: 'High-Value Clients',
    icon: '⭐',
    filters: {
      tier: [3, 4], // Full Render and Custom tiers
      status: ['ACTIVE'],
    },
  },
  {
    id: 'recent-submissions',
    name: 'Recent Submissions',
    icon: '🆕',
    filters: {
      dateRange: { start: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), end: new Date() },
    },
  },
  {
    id: 'needs-attention',
    name: 'Needs Attention',
    icon: '⚠️',
    filters: {
      status: ['OVERDUE', 'BLOCKED', 'ESCALATED'],
    },
  },
  {
    id: 'all-documents',
    name: 'All Documents',
    icon: '📁',
    filters: {}, // Shows document-focused view
  },
];
```

#### Option B: Dedicated Stakeholder Dashboard Tab

Add a new tab in AdminDashboard specifically for Karen & Pam:

```typescript
// kaa-app/src/components/admin/StakeholderView.tsx

const StakeholderView: React.FC = () => {
  const { user } = useAuth();
  const isStakeholder = ['karen@kaa.com', 'pam@kaa.com'].includes(user?.email || '');

  if (!isStakeholder) return null;

  return (
    <div className="stakeholder-view">
      <h2>Stakeholder Dashboard</h2>

      {/* Quick Stats */}
      <div className="stats-row">
        <StatCard title="Pending Reviews" count={pendingCount} />
        <StatCard title="This Week's Submissions" count={weeklyCount} />
        <StatCard title="High-Priority" count={priorityCount} />
      </div>

      {/* Clients Requiring Attention */}
      <section>
        <h3>Clients Requiring Attention</h3>
        <ClientsTable
          filters={{ status: ['NEEDS_REVIEW', 'ESCALATED'] }}
          columns={['name', 'project', 'status', 'lastActivity', 'actions']}
        />
      </section>

      {/* Recent Documents */}
      <section>
        <h3>Recent Documents</h3>
        <DocumentsTable
          filters={{ uploadedWithin: '7d' }}
          columns={['name', 'client', 'type', 'uploadedAt', 'status']}
        />
      </section>

      {/* Quick Actions */}
      <section>
        <h3>Quick Actions</h3>
        <button onClick={() => navigate('/admin/clients?filter=all')}>
          View All Clients
        </button>
        <button onClick={() => navigate('/admin/documents?filter=pending')}>
          Review Pending Documents
        </button>
        <button onClick={() => exportReport('weekly')}>
          Export Weekly Report
        </button>
      </section>
    </div>
  );
};
```

### Document Viewing Features

For Karen & Pam to efficiently review documents:

```typescript
// Enhanced document viewer with stakeholder features

interface DocumentViewerProps {
  documentId: string;
}

const StakeholderDocumentViewer: React.FC<DocumentViewerProps> = ({ documentId }) => {
  return (
    <div className="document-viewer">
      {/* Document Preview */}
      <DocumentPreview id={documentId} />

      {/* Quick Actions */}
      <div className="review-actions">
        <button onClick={() => approve(documentId)}>✓ Approve</button>
        <button onClick={() => requestChanges(documentId)}>↩ Request Changes</button>
        <button onClick={() => escalate(documentId)}>⚠ Escalate</button>
      </div>

      {/* Comments/Notes */}
      <CommentThread documentId={documentId} />

      {/* Document History */}
      <DocumentHistory id={documentId} />

      {/* Related Client Info */}
      <ClientSummary clientId={document.clientId} />
    </div>
  );
};
```

### Backend Support

Add endpoints for stakeholder-specific queries:

```typescript
// server/src/routes/admin.ts

// Get stakeholder dashboard data
router.get('/api/admin/stakeholder-dashboard', requireAdmin, async (req, res) => {
  const [pendingReviews, recentSubmissions, highPriority] = await Promise.all([
    prisma.project.count({ where: { status: 'PENDING_REVIEW' } }),
    prisma.document.findMany({
      where: { createdAt: { gte: subDays(new Date(), 7) } },
      take: 10,
      orderBy: { createdAt: 'desc' },
    }),
    prisma.client.findMany({
      where: { priority: 'HIGH', status: { in: ['ACTIVE', 'NEEDS_ATTENTION'] } },
    }),
  ]);

  res.json({ pendingReviews, recentSubmissions, highPriority });
});

// Get filtered clients for stakeholder view
router.get('/api/admin/stakeholder-clients', requireAdmin, async (req, res) => {
  const { preset } = req.query;

  const filters = getPresetFilters(preset as string);
  const clients = await prisma.client.findMany({
    where: filters,
    include: { projects: true, documents: true },
    orderBy: { updatedAt: 'desc' },
  });

  res.json({ clients });
});
```

### UI/UX Considerations

1. **Quick Access Toggle**: Add a "Stakeholder View" toggle in the admin header that Karen & Pam can use to switch between full admin and their optimized view.

2. **Keyboard Shortcuts**: Add shortcuts for common actions:
   - `A` = Approve
   - `R` = Request Changes
   - `N` = Next Document
   - `P` = Previous Document

3. **Bulk Actions**: Allow selecting multiple items for batch approval/review.

4. **Notifications**: Real-time notifications when new items need review.

### Implementation Priority

1. **Phase 1**: Add filter presets to existing admin dashboard
2. **Phase 2**: Create StakeholderView component
3. **Phase 3**: Add document review quick actions
4. **Phase 4**: Add bulk actions and keyboard shortcuts

---

## Integration with Landing Page

The landing page integration we just completed will feed into this flow:

```
Landing Page CTA → Typeform/Contact → Lead Created → Admin Dashboard
                                                          ↓
                                            Karen/Pam Stakeholder View
                                                          ↓
                                            Review → Approve → Client Onboarded
```

---

## Timeline Suggestion

| Task | Dependencies | Effort |
|------|--------------|--------|
| Merge PR #82 | None | 5 min |
| Google OAuth frontend | PR #82 merged | 2-3 hrs |
| Filter presets | None | 2-3 hrs |
| Stakeholder view component | Filter presets | 3-4 hrs |
| Document review actions | Stakeholder view | 2-3 hrs |

---

## Files to Create/Modify

### Google OAuth
- `kaa-app/src/components/auth/GoogleSignInButton.tsx` (new)
- `kaa-app/src/components/auth/LoginForm.tsx` (modify)
- `kaa-app/src/main.tsx` (modify)
- `kaa-app/.env` (add GOOGLE_CLIENT_ID)

### Karen & Pam View
- `kaa-app/src/components/admin/FilterPresets.tsx` (new)
- `kaa-app/src/components/admin/StakeholderView.tsx` (new)
- `kaa-app/src/components/admin/StakeholderDocumentViewer.tsx` (new)
- `kaa-app/src/components/admin/AdminDashboard.tsx` (modify - add tab)
- `server/src/routes/admin.ts` (modify - add endpoints)
