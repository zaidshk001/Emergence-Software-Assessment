## Emergence-Software Assessment
SaaS analytics project analyzing revenue, churn, and funnel performance using MySQL, Python, and Tableau. Includes true vs start-month metrics, event-based funnel analysis, and segment-level insights with clear assumptions and documentation.

### Task 1: Data Loading & Cleaning
Overview
The objective of Task 1 was to ingest three raw CSV datasets (customers, subscriptions, and events) into MySQL and prepare them for downstream SaaS analysis.
The datasets intentionally contained real-world issues such as missing values, duplicate records, inconsistent formats, and conflicting business signals.
A raw-to-clean table strategy was used to preserve data integrity while enabling reliable analysis.
________________________________________
Tools Used
•	MySQL (MySQL Workbench) – data ingestion, cleaning, and validation
•	Python (pandas, numpy) – initial inspection and sanity checks
________________________________________
Data Ingestion Strategy
All CSV files were first ingested into MySQL as raw tables using VARCHAR-only columns.
This approach prevents silent row loss during MySQL Workbench imports and ensures the original data is preserved exactly as received.
Raw tables:
•	customers_raw
•	subscriptions_raw
•	events_raw
Cleaned tables:
•	customers_clean
•	subscriptions_clean
•	events_clean
All data type enforcement and business logic were applied only in the cleaned tables.
________________________________________
Data Quality Issues & Handling
Missing and Invalid Values
•	Missing values were observed across multiple fields, including customers.signup_date.
•	Empty strings in date columns were treated as missing values and converted to NULL.
•	Dates were parsed using STR_TO_DATE; invalid or missing dates were retained as NULL rather than dropped.
Outcome: No records were removed due to missing or malformed non-critical fields.
________________________________________
Import-Related Row Loss
Initial imports resulted in fewer rows than present in the source CSVs.
Root Cause:
MySQL Workbench silently drops rows when importing into strict data types (e.g., DATE) if values are empty or malformed.
Resolution:
All raw tables were recreated using VARCHAR columns, and data types were explicitly normalized in cleaned tables.
This ensured 100% row preservation and full control over data normalization.
________________________________________
Duplicate Records
Duplicate records were identified in raw subscription and event data.
Resolution:
Exact duplicates were removed in cleaned tables using DISTINCT, assuming duplicates represent ingestion or tracking artifacts.
Logical primary keys (customer_id, subscription_id, event_id) were used for deduplication.
________________________________________
Inconsistent Business Signals
•	Churn appeared both as subscription status (canceled) and as an event (churned).
•	Customer segmentation was present in both segment and is_enterprise.
Resolution:
•	Subscription status was treated as the source of truth for revenue and churn metrics.
•	Event-based churn was used only for funnel analysis.
•	segment was used as the primary segmentation field; is_enterprise was retained but not used analytically.
________________________________________
Key Assumptions
•	Raw data is never altered or dropped during ingestion.
•	All data type enforcement occurs in cleaned tables.
•	Empty strings represent missing values and are converted to NULL.
•	customer_id uniquely identifies a customer.
•	Orphan records are retained to preserve behavioral and revenue signals.
•	Foreign key constraints are not enforced due to intentionally imperfect source data.
All assumptions are documented inline in SQL and referenced in downstream analysis.
________________________________________
Outcome
At the end of Task 1:
•	All source data was ingested without loss.
•	Data quality issues were identified and handled transparently.
•	Cleaned, analysis-ready tables were created.
•	The dataset was ready for accurate SaaS metrics and funnel analysis.
________________________________________


### Task 2: Core SaaS Metrics
Why “True” Metrics Are Used
For SaaS analytics, leadership decisions are typically driven by retention, revenue stability, and long-term growth, rather than short-term acquisition spikes.
While start-month (“Normal”) metrics are useful for understanding GTM performance and new revenue inflow, they do not accurately represent the health of the existing customer base.
Therefore, for each metric, True (active-base) versions are treated as the primary metrics, with Normal versions included for comparison and growth context.
All metrics in this section are derived exclusively from subscriptions_clean, as event-based churn signals may not align with actual revenue state.
________________________________________
Key Assumptions
•	Revenue and churn metrics are calculated only from subscriptions_clean
•	monthly_price represents full MRR per active subscription (no proration)
•	A subscription is considered active in a month if:
start_date ≤ month_end AND (end_date IS NULL OR end_date ≥ month_start)
•	Customers with multiple subscriptions are treated as a single logo for customer-level metrics
________________________________________
1. Monthly Recurring Revenue (MRR)
Normal MRR (Start-Month MRR)
Definition
Sum of monthly subscription prices for subscriptions starting in a given month.
Use case
•	New revenue added
•	Sales and GTM performance
Limitations
•	Excludes existing customers
•	Ignores churn impact
•	Highly volatile month-to-month
________________________________________
True MRR (Active MRR)
Definition
Sum of monthly prices of all subscriptions active during a calendar month.
Primary use case
•	Ongoing recurring revenue
•	Revenue stability and retention tracking
Assumptions
•	Full monthly price counted in any active month
•	No partial-month proration
________________________________________
2. Annual Recurring Revenue (ARR)
Normal ARR (New ARR)
Definition
Annualized value of Normal MRR (Normal MRR × 12).
Use case
•	GTM velocity
•	Revenue added from new subscriptions
Limitations
•	Not representative of total run-rate
•	Ignores churn and renewals
________________________________________
True ARR (Run-Rate ARR)
Definition
Annualized value of True MRR (True MRR × 12).
Primary use case
•	Total recurring revenue run-rate
•	Business size and financial health
Assumptions
•	ARR represents a run-rate, not contracted revenue
•	Retention and churn directly impact ARR
________________________________________
3. Customer (Logo) Churn Rate
Normal Customer Churn Rate
Definition
Churned customers in a month divided by customers who started in that month.
Use case
•	Churn relative to newly acquired customers
Limitations
•	Not a true retention metric
•	Can exceed 100%
•	Ignores existing customer base
________________________________________
True Customer (Logo) Churn Rate
Definition
Customers churned during a month divided by customers active at the start of that month.
Primary use case
•	Customer retention
•	Long-term customer health
Assumptions
•	A customer is churned when their final active subscription ends
________________________________________
4. Revenue Churn Rate
Normal Revenue Churn Rate
Definition
Revenue lost in a month divided by revenue from subscriptions starting in the same month.
Use case
•	Revenue loss relative to new bookings
Limitations
•	Not retention-focused
•	Can exceed 100%
•	Not comparable across months
________________________________________
True Revenue Churn Rate
Definition
Revenue lost during a month divided by recurring revenue active at the start of that month.
Primary use case
•	Revenue retention
•	Stability of recurring revenue
Assumptions
•	Revenue measured using monthly subscription prices
•	No proration applied
________________________________________
5. Average Revenue per Customer (ARPC)
Normal ARPC
Definition
Revenue from subscriptions starting in a month divided by customers starting in that month.
Use case
•	Deal quality of newly acquired customers
Limitations
•	Not representative of active customer base
•	Sensitive to acquisition volume
________________________________________
True ARPC
Definition
Recurring revenue from active subscriptions divided by active customers in the same month.
Primary use case
•	Monetization efficiency
•	Pricing and upsell effectiveness
Assumptions
•	Customers with multiple subscriptions contribute multiple revenue components
•	Each customer is counted once in the denominator
________________________________________
Summary of Metric Usage
Metric Type	Best Used For
Normal Metrics	Sales, GTM, acquisition analysis
True Metrics	Retention, revenue health, business reporting
Using both perspectives provides a complete view of short-term growth dynamics and long-term business sustainability.


#### Python Usage: Data Validation & Sanity Checks
Purpose
Python was used to validate data integrity and SQL outputs, not to replicate the full analysis.
The objective was to confirm row counts, detect data quality issues early, and sanity-check a small subset of key metrics.
________________________________________
Step 1: Load Raw CSV Files
All raw CSV files were loaded into pandas to:
•	Confirm record counts
•	Inspect missing values
•	Identify formatting inconsistencies
•	Validate the decision to ingest raw data as VARCHAR in MySQL
This initial inspection revealed missing values and inconsistent formats, supporting the raw-to-clean table strategy used in SQL.
________________________________________
Step 2: Initial Data Exploration
Basic exploratory checks were performed, including:
•	Missing value counts per column
•	Distribution of categorical fields such as:
o	Customer segment
o	Subscription status
o	Event type
These checks helped validate downstream SQL assumptions around segmentation, churn logic, and funnel construction.
________________________________________
Step 3: Validate SQL Ingestion Results
Python was connected to MySQL to verify that data ingestion and cleaning steps did not result in unintended row loss.
Row counts from:
•	Raw CSV files
•	Cleaned MySQL tables
were compared to confirm 100% record preservation after ingestion and cleaning.
________________________________________
Step 4: Metric Sanity Checks
A small subset of core metrics was validated in Python to ensure SQL logic was directionally correct.
For example:
•	Monthly MRR was recomputed at a high level using pandas
•	Results were compared against SQL outputs to confirm consistency in trends and magnitudes
The goal was logical validation, not exact numerical replication.
________________________________________
Step 5: Business Logic Validation
Python was also used to validate key business assumptions, such as churn definition.
For example:
•	The number of customers with churned events was compared to customers with canceled subscriptions
•	This mismatch supported the decision to treat subscription status as the source of truth for churn metrics, while using churn events only for funnel analysis
________________________________________
Outcome
Python validation confirmed:
•	No unintended row loss during ingestion
•	Correct handling of missing and inconsistent values
•	Alignment between SQL metrics and raw data trends
•	Sound business assumptions for churn and revenue calculations


### Task 3: Funnel Analysis
Objective
The objective of Task 3 was to analyze user progression through the product funnel, identify conversion rates and drop-off points, and evaluate funnel performance by acquisition source and customer segment.
The funnel analyzed was:
Signup → Trial → Activated → Paid → Churned
________________________________________
Why Event-Based Funnel Analysis
Funnel analysis focuses on user behavior and progression, which is best captured through event data rather than subscription records.
Therefore, the funnel is built using event-level data, while revenue and churn metrics continue to rely on subscription status (as defined in Task 2).
________________________________________
Data Preparation & Key Assumptions
Event Deduplication
The events dataset contained duplicate funnel events, including multiple signup records for the same customer on the same date.
Because event timestamps were available only at the date level (no time component), duplicates could not be meaningfully ordered.
To ensure accurate funnel counts:
•	Events were deduplicated by customer_id and event_type
•	Only one occurrence per funnel stage per customer was retained
•	A dedicated table (events_funnel) was created for funnel analysis
This guarantees that each customer contributes at most one event per funnel stage.
________________________________________
Funnel Stage Definitions
•	Signup / Trial / Activated / Churned stages are derived from events_funnel
•	Paid stage is inferred from the presence of a subscription record in subscriptions_clean
•	Funnel progression is treated as stage-based, not strictly time-ordered, due to date-level granularity
________________________________________
Churn Handling
•	Churn events are used only for funnel visibility
•	Subscription status remains the source of truth for churn metrics
•	This avoids inconsistencies between behavioral events and revenue state
________________________________________
Segment Handling
Some customer records contained missing or empty values in the segment field.
For segment-level funnel analysis:
•	Customers with NULL or empty ('') segment values were excluded
•	This prevented misleading or ambiguous segment groupings
________________________________________
Funnel Metrics Calculated
1. Overall Funnel Counts
•	Total number of customers at each funnel stage
•	High-level visibility into user drop-off across the funnel
________________________________________
2. Conversion Rates
Conversion rates were calculated between successive funnel stages:
•	Signup → Trial
•	Trial → Activated
•	Activated → Paid
These metrics highlight where the largest friction exists in the user journey.
________________________________________
3. Drop-Off Analysis
Drop-offs were explicitly measured at key stages:
•	Users who signed up but never started a trial
•	Users who started a trial but never activated
This helped identify primary bottlenecks in onboarding and product adoption.
________________________________________
4. Funnel Performance by Acquisition Source
The funnel was segmented by acquisition source to compare:
•	Signup volume
•	Activation rates
•	User quality across channels
This analysis identifies which sources drive higher-intent and higher-quality users.
________________________________________
5. Funnel Performance by Customer Segment
The funnel was also segmented by customer segment (SMB, Mid-Market, Enterprise) to analyze:
•	Differences in activation behavior
•	Segment-level conversion efficiency
Customers with missing segment data were excluded from this analysis.
________________________________________
Key Observations (Illustrative)
•	A noticeable drop-off occurs between Signup and Trial, suggesting onboarding or trial initiation friction
•	Activation rates vary meaningfully by acquisition source, indicating differences in channel quality
•	Mid-Market and SMB customers show higher activation rates compared to Enterprise users
(Exact insights are expanded in Task 5.)
________________________________________
Limitations
•	Funnel ordering is inferred at the stage level due to lack of event timestamps
•	Multiple subscriptions per customer are treated as a single “Paid” outcome
•	Funnel analysis focuses on customer progression, not revenue contribution
________________________________________
Outcome
By deduplicating events and applying clear funnel rules, the analysis provides a reliable and realistic view of user progression, conversion efficiency, and drop-off points.
These insights support product optimization, onboarding improvements, and acquisition channel prioritization.


### Task 4: SaaS Metrics Dashboard (Tableau)
Overview
This dashboard provides an executive-level view of core SaaS performance metrics for Emergence Software.
It is designed to help stakeholders quickly assess revenue health, funnel efficiency, churn behavior, and customer mix, while enabling consistent month-level analysis through parameter controls.
The focus is on analytical correctness and insight, rather than heavy visual styling.
________________________________________
Data Sources
The dashboard is built using cleaned datasets generated in Tasks 1–3:
•	customers_clean – customer attributes and segmentation
•	subscriptions_clean – subscription lifecycle and pricing
•	events_clean / events_funnel – user lifecycle and funnel events
Core SaaS metrics (MRR, ARR, churn, ARPC) are calculated using true point-in-time logic based on subscription start and end dates.
________________________________________
Dashboard Structure & Key Sections
1. Business-at-a-Glance Numbers (BANs)
High-level KPIs summarizing overall SaaS health, controlled by a month parameter:
•	MRR – recurring revenue from active subscriptions
•	ARR – annualized MRR (MRR × 12)
•	Customer Churn Rate – churned customers ÷ customers active at month start
•	Revenue Churn – MRR lost due to churn
•	ARPC – MRR ÷ active customers
These KPIs allow leadership to immediately assess scale, retention, and monetization efficiency.
________________________________________
2. Funnel Conversion Analysis
A cohort-based funnel anchored on signup month:
Signup → Trial → Activated → Paid → Churned
Key characteristics:
•	Funnel stages derived from deduplicated event data
•	Conversion rates and drop-offs shown at each stage
•	Cohort month parameter enables comparison across signup cohorts
•	Churn is allowed to occur after activation, reflecting real SaaS behavior
This section highlights where users drop off and how effectively acquisition converts to revenue.
________________________________________
3. Monthly Recurring Revenue Trend
A time-series view of True MRR, calculated using active subscription logic.
This view highlights:
•	Growth trajectory
•	Revenue stability vs volatility
•	Alignment between historical trends and current BAN values
________________________________________
4. Churn Overview
A calendar-month view showing the number of customers who churned each month.
This perspective answers:
•	When are we losing customers?
•	Supports operational monitoring and leadership reporting
(Cohort-based churn is analyzed separately in the funnel section.)
________________________________________
5. Source & Segment Breakdown
a. Paid Users by Acquisition Source
Shows how paid customers are distributed across acquisition channels (organic, ads, referral, outbound), helping identify high-quality sources.
b. MRR by Customer Segment
Displays MRR contribution by segment (SMB, Mid-Market, Enterprise), highlighting revenue concentration and segment mix.
________________________________________
Parameters & Interactivity
•	Cohort / Month Parameter
o	Controls BANs, funnel analysis, and revenue views
o	Enables consistent point-in-time analysis without removing historical context
•	Charts are readable without interaction; parameters act as optional drill-down controls.
________________________________________
Key Design Decisions
•	True MRR logic: revenue calculated from active subscriptions
•	Clear separation of concepts:
o	Funnel & cohort analysis → signup month
o	Churn overview → calendar month
•	Minimal, high-signal KPIs to avoid clutter
•	Clarity-first visuals optimized for interpretation
________________________________________
How to Use the Dashboard
1.	Select a month using the Cohort Month parameter
2.	Review BANs for revenue and churn health
3.	Analyze funnel conversion and drop-offs
4.	Review churn trends over time
5.	Use source and segment views to understand customer and revenue mix
________________________________________
Outcome
This dashboard connects acquisition, conversion, revenue, and retention into a single, coherent SaaS performance narrative.
It is designed to support data-driven decision-making for product, growth, and leadership teams.


### Task 5: Insights & Recommendations
Key Growth Bottlenecks
1. Largest Drop-Off Occurs Early in the Funnel (Signup → Trial)
•	Only ~67.6% of signed-up users start a trial.
•	This represents the single biggest volume loss in the funnel.
•	Indicates friction in onboarding, trial initiation, or unclear value proposition immediately after signup.
Improving early activation would have the largest downstream impact on paid users and revenue.
________________________________________
2. Trial → Activated Conversion Is a Secondary Bottleneck
•	Trial-to-activation conversion is ~59.8%, meaning ~40% of trial users never activate.
•	Suggests users struggle to reach “first value” during the trial experience.
•	This limits the effectiveness of acquisition spend, even when trials are started.
________________________________________
3. Post-Payment Retention Is Relatively Strong but Not Negligible
•	Paid → Churned rate is ~23–24%, indicating reasonable but improvable retention.
•	Revenue churn is present but not extreme, suggesting churn is more logo-driven than price-driven.
•	Retention improvements here would stabilize ARR growth rather than drive explosive growth.
________________________________________
Strongest and Weakest Acquisition Channels
Strongest Channels (by Funnel Quality)
•	Outbound and Organic show the highest signup-to-activated rates:
o	Outbound ≈ 44.8%
o	Organic ≈ 46.4%
•	These channels attract higher-intent users who progress deeper into the funnel.
These channels appear to deliver quality over quantity.
________________________________________
Weakest Channel
•	Ads has the lowest signup-to-activated rate (~33.3%).
•	While signup volume is comparable, fewer users reach activation.
•	Suggests mismatch between ad messaging and actual product value, or low-intent traffic.
Ads may be inflating top-of-funnel volume without proportional revenue impact.
________________________________________
Segment-Level Observations
•	SMB and Mid-Market customers show higher activation rates than Enterprise.
•	Enterprise users convert more slowly, likely due to:
o	Longer evaluation cycles
o	Higher setup complexity
o	Multi-stakeholder decision-making
Enterprise growth likely requires different activation and sales motions, not just more acquisition.
________________________________________
What to Investigate Next
1.	Signup-to-Trial Friction
o	Where do users drop immediately after signup?
o	Are there mandatory steps blocking trial start?
o	Is value communicated clearly on Day 0?
2.	Trial Usage Behavior
o	Which product actions correlate most strongly with activation?
o	Do activated users reach a specific feature or milestone?
3.	Ad Channel Quality
o	Break down ads by campaign or creative (if available)
o	Compare trial usage and activation behavior vs organic users
4.	Enterprise Activation Lag
o	Measure time-to-activation by segment
o	Identify whether Enterprise users activate later or not at all
________________________________________
Actionable Recommendations for Leadership
Recommendation 1: Prioritize Signup-to-Trial Optimization
Focus product and growth efforts on reducing friction immediately after signup:
•	Simplify trial start flow
•	Improve onboarding messaging
•	Highlight “first value” actions clearly
Even a small lift here would cascade into more activations, more paid users, and higher ARR.
________________________________________
Recommendation 2: Reallocate Spend Toward High-Quality Channels
•	Increase focus on Organic and Outbound, which show stronger funnel performance.
•	Audit and refine Ads strategy to improve user intent and messaging alignment.
This improves ROI by shifting focus from volume-driven growth to conversion-efficient growth.
________________________________________
Summary
The analysis shows that growth is primarily constrained by early funnel friction, not late-stage monetization.
Addressing onboarding and trial activation, while prioritizing high-quality acquisition channels, offers the most impactful path to sustainable revenue growth.

