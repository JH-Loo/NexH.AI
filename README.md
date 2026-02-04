# NexH.AI
# NexH.AI - The AI Manager that Sees, Thinks & Acts

## Inspiration

Every day, small business owners in service industries face the same painful challenge: **customer churn happens silently**. A loyal customer who visited every month suddenly disappears, and by the time anyone notices, they've already found a competitor.

Small and Medium Enterprises (SMEs) are the lifeblood of the global economy, but they are often paralyzed by "Data Gravity"—the sheer weight of manual entry and fragmented records. We were inspired by a simple but powerful realization: Business owners don’t need more data; they need solutions. Our mission was to leverage Gemini 3.0 to transform raw business clutter into a high-definition decision pipeline, turning "what happened" into "what to do now".

The question that sparked NexH.AI was simple:

> *"In the era of Agentic AI, what if AI could be the manager that never sleeps - one that watches over every customer relationship and tells you exactly who to call today?"*

## What it does

NexH.AI is a Strategic Business Hub that serves as an impartial AI consultant for service-based industries.

**Multimodal Logic Extraction** : Goes beyond simple object recognition—uses Gemini's vision capabilities to extract structured business logic from unstructured physical data (receipts, handwritten forms, condition photos), automatically updating SQL databases and triggering industry-specific workflows. Vision isn't the endpoint; it's the bridge from analog chaos to digital action.

**Automated Workflow Triggers** : AI doesn't just "see"—it "acts". A photo of a service receipt instantly becomes a timestamped asset update in PostgreSQL, triggering maintenance alerts and customer follow-up sequences.

**Daily Intelligence** : Pinpoints the "Top" highest-value actions every day, generating personalized care scripts ready for one-click sharing.

**Weekly Strategic Audits** : Benchmarks performance against industry standards and identifies cross-state emerging trends.

### Core Capabilities

| Feature | Description | Why It's Not Simple Vision |
|---------|-------------|----------------------------|
| **Multimodal Business Logic Extraction** | Photograph a handwritten service form → AI extracts structured data → Updates `UniversalAsset` table in SQL → Triggers next maintenance alert | Uses vision to **populate databases and trigger workflows**, not just identify objects |
| **Document-to-Database Pipeline** | Snap a receipt/invoice → OCR extracts date, items, amount → Creates timestamped business records → Feeds into churn prediction model | Vision is the **data entry automation layer**, feeding into complex business intelligence |
| **Condition Analysis → Action Scheduling** | Photo of customer condition (skin/vehicle/equipment) → AI assesses severity + timing → Generates follow-up schedule + personalized message → Updates CRM status | Vision triggers **multi-step business processes**, not just returns labels |
| **Sub-Second Intelligence** | Gemini 3.0 Flash completes full analysis (OCR + logic extraction + JSON structuring) in under 10 seconds. For busy shop owners juggling customers, 30-second waits are dealbreakers. This speed makes AI feel like an instant teammate, not a batch-processing tool. | Performance enables **real-time business process integration**—owners complete customer check-ins with live AI assistance during service, not post-facto offline analysis |
| **Fatigue-Aware Outreach** | Prevents over-contacting customers with a specific cooldown algorithm tracked in `AIActionLog` table | AI manages **temporal business rules** across customer lifecycle |

### The Intelligence Formula

Our priority customer detection uses a two-layer filtering system. **The formula adapts to each industry** - below is an example for a Beauty Salon:

$$
\text{Focus List} = \text{Strategy Candidates} - \text{Fatigue Set} - \text{Excluded Status}
$$

Where:
- **Strategy Candidates**: Customers matching industry-specific rules (e.g., \\( \text{days\_absent} > 60 \\) for salons)
- **Fatigue Set**: Customers contacted within the cooldown period
- **Result**: Top priority customers per day

> **Industry Adaptability**: An auto workshop might trigger at 90 days with mileage thresholds, while a F&B outlet might focus on loyalty program engagement. The core algorithm remains the same, but parameters are tailored to each vertical.

## How we built it

### Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Flutter Web    │────▶│  Cloud Run API   │────▶│  Gemini 3.0     │
│  (Frontend)     │     │  (FastAPI)       │     │  Flash Preview  │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │
                               ▼
                        ┌──────────────────┐
                        │  Cloud SQL       │
                        │  (PostgreSQL)    │
                        └──────────────────┘
```

### Tech Stack

- **Frontend**: Flutter Web with responsive design
- **Backend**: Python FastAPI on Cloud Run (auto-scaling)
- **AI Engine**: Vertex AI with Gemini 3.0 Flash Preview
- **Database**: Cloud SQL PostgreSQL with JSONB for flexible schemas
- **Auth**: Firebase Authentication with custom claims
- **Storage**: Google Cloud Storage for image processing

### Key Design Decisions

1. **Multi-tenant Row-Level Security**: Every query is automatically scoped by `tenant_id` extracted from JWT claims - not request body (security first!)

2. **Industry-Adaptive Prompts**: We use the CO-STAR framework to dynamically inject industry context:
   ```
   [CONTEXT] Beauty Salon | Skills: Acne Treatment, Anti-aging
   [OBJECTIVE] Analyze skin condition from uploaded image
   [STYLE] Professional dermatology terminology
   [RESPONSE] JSON: {recommend_days, severity, confidence, observations[]}
   ```

3. **Image Compression Pipeline**: All uploaded images are compressed to 800px max dimension before AI processing - reducing costs by 60% while maintaining accuracy.

4. **Flutter for Cross-Platform Consistency**: Built with Flutter to ensure seamless experience across all devices (mobile, tablet, desktop). SME owners need to access AI insights anywhere—on a phone between appointments, on a tablet at the counter, or on desktop during end-of-day reviews. Single codebase, universal experience.

### Why This Isn't "Simple Vision Analysis"

**NexH.AI doesn't just recognize objects—it executes business logic.**

Traditional vision apps stop at labels: "This is a receipt" or "Confidence: 87%". We go three steps further:

1. **Vision → Structured Data**
   OCR extracts text, Gemini parses intent, outputs JSON matching our SQL schema

2. **Structured Data → Database State Change**
   ```sql
   UPDATE universal_assets
   SET last_service_date = '2026-01-15',
       next_maintenance_due = '2026-02-15',
       ai_risk_score = 0.72
   WHERE asset_id = 'extracted_from_receipt'
   ```

3. **Database State → Workflow Trigger**
   New risk score triggers the Daily Focus algorithm → Customer appears in tomorrow's outreach list → Personalized message auto-generated → Business owner approves & sends

**Example Flow**: A beauty salon owner photographs a handwritten appointment card:
- ❌ Simple Vision: "Detected: handwriting, Date: 2025-12-20"
- ✅ NexH.AI: Updates client's `last_visit` → Calculates days_absent (45 days) → Triggers churn risk alert → Generates personalized re-engagement script → Schedules AI reminder for owner

The vision API is our **data entry automation layer**, not our product. The product is the closed-loop business intelligence system.

## Challenges we ran into

### 1. The "List vs Dict" Config Migration Crisis
Mid-development, we migrated our tenant config schema from dictionary to list format. This broke OCR functionality with:
```
ERROR: 'list' object has no attribute 'get'
```
**Solution**: Created a centralized `get_tenant_schema_rules()` function that handles both formats gracefully.

### 2. Customer Fatigue Prevention
Early testing showed the AI was recommending the same "high-risk" customers every single day, leading to annoying over-contact.
**Solution**: Implemented a 30-day fatigue filter using `AIActionLog` tracking:
```python
fatigued_ids = SELECT target_id FROM ai_action_logs
               WHERE created_at >= (TODAY - 30 days)
```

### 3. Cold Start Performance
Cloud Run cold starts were causing 8-10 second delays on first request.
**Solution**: Configured minimum instances and optimized container image size.

### 4. The Complexity of Domain Specificity
Our greatest challenge was the ambition to span diverse fields—from beauty salons to automotive detailing. We quickly realized that there is no "one-size-fits-all" solution. Different industries, geographic regions, and customer demographics operate on entirely different logics. To provide truly actionable advice, we had to perform intensive research into each sector, as understanding the subtle nuances of a specific industry is the only way to define meaningful AI requirements.

## Accomplishments that we're proud of

- **Zero-Config Onboarding**: New tenants can start using AI features immediately with sensible industry defaults - no complex setup required

- **Sub-10-Second AI Analysis**: From photo upload to structured JSON response in under 10 seconds, including image compression and Gemini processing

- **Production-Ready Security**:
  - Firebase token verification on every request
  - 64-character cryptographic secrets for internal endpoints
  - Rate limiting (30 req/min on AI endpoints)
  - Per-tenant daily quotas

- **Cost-Optimized AI Pipeline**: Smart compression pipeline delivers enterprise-grade AI analysis at startup-friendly costs

## What we learned

### Technical Insights

1. **Gemini 3.0's multimodal capabilities enable true logic extraction, not just object detection** - With structured prompting (CO-STAR framework), it reliably converts unstructured physical artifacts (receipts, forms, condition photos) into database-ready JSON that maps directly to our SQL schema. This isn't vision for recognition—it's vision for **business process automation**.

2. **Vision APIs become transformative when chained with database triggers and workflow engines** - The real innovation isn't in the OCR accuracy (though Gemini excels at it), but in treating vision as the first step in a multi-stage business logic pipeline: Image → Structured Data → SQL Update → Risk Calculation → Action Recommendation → Human-in-the-Loop Approval.

3. **"AI Proposes, Expert Approves" drives adoption** - SMEs are far more likely to embrace high-tech solutions when they retain final creative control over their professional voice. Our AI generates personalized message scripts, but the business owner always decides when and how to reach out.

### Product Insights

1. **Small business owners don't want dashboards - they want answers** - "Who should I call today?" beats fancy analytics every time

2. **AI confidence matters** - Showing "85% confidence" alongside recommendations builds trust

3. **Contact fatigue is real, but the threshold varies by industry** - Over-contacting customers damages relationships, but the ideal outreach cycle differs dramatically: a beauty salon might follow up monthly, while an auto workshop operates on quarterly or annual service intervals. Smart AI must adapt to each vertical's natural rhythm.

## What's next for NexH.AI

**Validate** — Launch a beta for interested users to gather real-world feedback and refine the product-market fit.

**Deepen** — Enhance our cross-state trend analysis ("Federated Intelligence") while maintaining strict tenant data isolation.

**Expand** — Extend to more service verticals, so business owners across industries can focus on delivering quality service while NexH.AI handles strategy, decisions, and customer relationships.

---

> *"The best CRM is the one you don't have to think about. It just tells you what to do."*

**Built with Gemini 3.0 Flash Preview for the Google AI Hackathon 2026**

---

## Legal

By using NexH.AI, you agree to our [Terms of Use & Privacy Policy](TERMS.md).

**Key Privacy Features:**
- 🔒 All data encrypted and stored on Google Cloud
- 🗑️ Images are **permanently deleted** after AI analysis
- 📝 Only text-based analysis results are retained
- 🤖 AI recommendations require human approval

See [LICENSE](LICENSE) for copyright information.

---

## Contact

- **Team**: nexfarm30@gmail.com
- **Developer**: jinghongloo@gmail.com

---

*© 2026 NexH.AI. All Rights Reserved.*
