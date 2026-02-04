# NexH System Architecture

## Overview

NexH follows a modern cloud-native architecture optimized for:
- **Scalability**: Serverless (Cloud Run) auto-scales to demand
- **Security**: Multi-tenant isolation at database level (RLS)
- **Performance**: Async Python + Async DB drivers
- **Reliability**: Graceful degradation with AI fallbacks

## Data Flow

### 1. Authentication Flow

```
User → Firebase Auth → ID Token → Backend validates → Custom claims (tenant_id)
```

- Firebase handles password storage, OAuth, MFA
- Backend validates token on every request
- `tenant_id` from custom claims enforces data isolation

### 2. AI Analysis Flow

```
User uploads image
    ↓
Frontend (Flutter) → POST /assets/{id}/analyze_image
    ↓
Backend validates auth + uploads to GCS
    ↓
Gemini 3.0 processes (Image + CO-STAR Prompt)
    ↓
JSON response → Saved to DB → Returned to Frontend
```

### 3. Daily Briefing Flow

```
Cron Job (Daily 6 AM)
    ↓
Backend fetches tenant data
    ↓
SQL identifies "strategic candidates" (dormant customers, etc.)
    ↓
Gemini generates briefing with tactical actions
    ↓
Cached in daily_reports table
    ↓
User opens app → Instant display
```

## Database Schema (Simplified)

```
tenants
├── id (UUID)
├── industry_type (enum)
├── config_rules (JSONB)     ← Industry-specific field definitions
├── industry_skills (JSONB)  ← AI behavior customization
└── output_language (varchar)

universal_assets
├── id (UUID)
├── tenant_id (FK) ← Multi-tenant isolation
├── attributes (JSONB)
├── is_deleted (bool)
└── created_at

maintenance_events
├── tenant_id (FK)
├── asset_id (FK)
├── event_type (varchar)
├── event_data (JSONB)
└── occurred_at

daily_reports
├── tenant_id (FK)
├── report_date
└── analysis_result (JSONB) ← Cached AI output
```

## Security Layers

| Layer | Implementation |
|-------|----------------|
| **Transport** | HTTPS only (Cloud Run default) |
| **Authentication** | Firebase Auth + JWT validation |
| **Authorization** | Custom claims (tenant_id) in JWT |
| **Data Isolation** | SQL WHERE clause enforced in ORM |
| **Rate Limiting** | IP-based + tenant-based limits |
| **Input Validation** | Pydantic models + InputGuard |
| **CORS** | Whitelist of allowed origins |

## AI Safety

1. **Prompt Injection Defense**
   - User data wrapped in triple-quotes
   - "End of Data Block" markers
   - XML/HTML tag stripping

2. **PII Protection**
   - Email/phone masking in logs
   - No PII sent to Gemini (only aggregates)

3. **Fallback Strategy**
   - If AI fails → Return safe JSON structure
   - Frontend always gets valid, parseable response

## Deployment Architecture

```
                    ┌─────────────────────────────────────┐
                    │         Google Cloud Platform        │
                    │                                      │
    Internet        │  ┌─────────────┐  ┌──────────────┐  │
       │            │  │ Cloud Run   │  │  Cloud SQL   │  │
       ▼            │  │ (Backend)   │──│ (PostgreSQL) │  │
  ┌─────────┐       │  └─────────────┘  └──────────────┘  │
  │Firebase │───────│         │                           │
  │Hosting  │       │         ▼                           │
  │(Flutter)│       │  ┌─────────────┐  ┌──────────────┐  │
  └─────────┘       │  │ Vertex AI   │  │     GCS      │  │
                    │  │ (Gemini)    │  │   (Images)   │  │
                    │  └─────────────┘  └──────────────┘  │
                    │                                      │
                    └─────────────────────────────────────┘
```

## Performance Optimizations

1. **Async Everything**
   - FastAPI async endpoints
   - asyncpg for PostgreSQL
   - async Gemini API calls

2. **Token Cost Reduction**
   - Only send aggregates to AI (not full customer lists)
   - Strategic candidates identified by SQL first
   - Cached daily reports (one AI call per day per tenant)

3. **Frontend**
   - Riverpod for efficient state management
   - Lazy loading of heavy widgets
   - Image compression before upload
