# ChartSense

ChartSense is a mobile-first investment companion that distills market sentiment into actionable insight. The iOS application aggregates trusted financial news and social media commentary, applies natural language processing to surface bullish or bearish trends, and presents the results in a format tailored for everyday investors.

## Key Capabilities

- **Sentiment intelligence** – Consolidates news headlines, long-form articles, and social streams to score tickers by positive, neutral, or negative momentum.
- **Digestible market views** – Highlights the metrics that matter through curated dashboards, watchlists, and alerting flows designed for clarity.
- **AI-powered assistance** – Provides conversational guidance to help investors interpret market shifts and explore new ideas.
- **Seamless premium experience** – Supports subscription management and gated content to differentiate free and premium feature sets.

## Screenshots

> Replace the placeholders below with final assets before release.

- ![Mobile dashboard placeholder](docs/images/dashboard-placeholder.png)
- ![Sentiment detail placeholder](docs/images/sentiment-placeholder.png)
- ![AI assistant placeholder](docs/images/assistant-placeholder.png)

## Architecture Overview

ChartSense couples a modern SwiftUI client with a cloud-ready backend to ensure real-time insights and reliable delivery:

- **iOS application** – Built with SwiftUI, Combine, and async/await patterns for responsive interfaces, live charting, and smooth navigation.
- **Supabase integration** – Manages authentication, profiles, and ancillary data storage to accelerate iteration.
- **Custom API layer** – A TypeScript Fastify service backed by PostgreSQL centralizes ticker, sentiment, and user data. Redis is available for low-latency caching and rate limiting.
- **Ingestion and AI services** – Scheduled workers collect market data, refresh pricing, and run sentiment models that power the in-app experience.

## Technology Stack

| Layer | Technologies |
| --- | --- |
| Mobile client | SwiftUI, Combine, WidgetKit, StoreKit |
| Backend services | Fastify (TypeScript), Node.js, Supabase Functions |
| Data & infrastructure | PostgreSQL, Redis, Docker Compose (local), Supabase |
| Intelligence | Python-based NLP pipelines, OpenAI integrations |
| Tooling | Xcode, npm, pnpm, Supabase CLI |

## Getting Started

### Prerequisites

- Xcode 15 or later with the iOS 17 SDK
- Node.js 20+ and npm for backend services
- Docker Desktop for local databases and caching layers
- Supabase project credentials (URL, anon key, service role key)

### Mobile App Setup

1. Copy `ChartSense/Config.plist.example` to `ChartSense/Config.plist` and populate the API, Supabase, and subscription keys.
2. Open `ChartSense.xcodeproj` in Xcode.
3. Select the `ChartSense` scheme and run on a simulator or device.

### Backend Setup (Optional for Local Testing)

1. `cd backend` and run `docker compose up -d` to provision PostgreSQL and Redis.
2. Apply database migrations: `psql postgres://chartsense:chartsense@localhost:5432/chartsense -f sql/0001_init.sql`.
3. Duplicate `env.example` to `.env`, then add API secrets and provider tokens.
4. In separate terminals, install dependencies and start the services:
   - `cd backend/api && npm install && npm run dev`
   - `cd backend/worker && npm install && npm run dev`

### Supabase Project Sync

1. Install the Supabase CLI and authenticate with your project.
2. Run `supabase db push` to align local schema changes.
3. Use `supabase functions deploy` to ship edge functions as needed.

## Repository Structure

```
ChartSense/
├─ ChartSense/                # SwiftUI application source
├─ backend/                   # Fastify API, worker services, database migrations
├─ database/                  # Supabase policies, seeds, and SQL utilities
├─ docs/                      # Operational guides and troubleshooting references
└─ supabase/                  # Local Supabase configuration and migrations
```

## Quality and Compliance

- **Security first** – Secrets are stored outside source control, and role-based policies govern data access.
- **Performance monitoring** – API endpoints and workers expose structured logs for observability.
- **App Store readiness** – The project follows Apple Human Interface Guidelines and supports subscription compliance through StoreKit.

## Roadmap Highlights

- Expand coverage to global equity markets and thematic indexes.
- Deepen AI explanations with scenario analysis and natural language summaries.
- Introduce collaborative watchlists and shared sentiment boards.

## Contributing

1. Fork the repository and create a feature branch.
2. Run formatting and linting scripts before submitting changes.
3. Open a pull request describing the problem, proposed solution, and testing strategy.

The team reviews contributions for clarity, maintainability, and alignment with our product vision.

## Licensing

ChartSense is a proprietary project. Please contact the maintainers for licensing inquiries.

