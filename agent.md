# Wazuh Monitor - AGENTS.md

## Project Overview
Aplikasi monitoring keamanan server berbasis Wazuh dengan Flutter frontend.

## Tech Stack
- **Backend**: Node.js + Express + TypeScript
- **Database**: PostgreSQL + Prisma ORM
- **Auth**: JWT + bcrypt (1 admin from seed)
- **Frontend**: Flutter + Riverpod + GoRouter
- **Notification**: Firebase Cloud Messaging
- **Real-time**: FCM + polling 15-30 detik
- **Wazuh Integration**: Custom Wazuh Integration Script
- **Active Response**: Dikonfigurasi langsung di Wazuh
- **Deployment**: Docker Compose + Nginx reverse proxy

## Project Structure

### Backend (`backend/`)
```
src/
├── index.ts                   # Entry point
├── app.ts                     # Express app setup
├── config/
│   ├── env.ts                 # Environment validation
│   └── firebase.ts            # FCM Admin SDK
├── controllers/
│   ├── auth.controller.ts     # POST /api/auth/login
│   ├── alert.controller.ts    # GET/PATCH /api/alerts
│   ├── agent.controller.ts    # GET /api/agents
│   ├── dashboard.controller.ts  # GET /api/dashboard
│   ├── device.controller.ts   # POST/DELETE /api/device-token
│   └── webhook.controller.ts  # POST /api/webhook/wazuh
├── services/
│   ├── auth.service.ts        # Login + JWT sign
│   ├── alert.service.ts       # CRUD + filter + pagination
│   ├── agent.service.ts       # Upsert + list agents
│   ├── dashboard.service.ts   # Aggregated stats
│   ├── fcm.service.ts         # Firebase push notification
│   └── webhook.service.ts     # Process Wazuh alerts
├── middleware/
│   ├── auth.ts                # JWT verification
│   ├── webhook-auth.ts        # API key for Wazuh
│   └── error-handler.ts       # Global error handler
├── routes/
│   └── index.ts               # All routes defined here
├── utils/
│   ├── prisma.ts              # Prisma singleton
│   └── logger.ts              # Winston logger
└── types/
    └── wazuh.ts               # Wazuh alert type definitions

prisma/
├── schema.prisma              # 4 tables (User, Agent, Alert, DeviceToken)
└── seed.ts                    # Admin seed (admin/admin123)

wazuh/
└── custom-wazuh.py            # Wazuh integration script

docker-compose.yml             # PostgreSQL + Backend
Dockerfile                     # Multi-stage build
```

### Flutter (`wazuh_app/`)
```
lib/
├── main.dart                  # Entry + Firebase init
├── app.dart                   # Export barrel
├── core/
│   ├── constants/
│   │   └── api_constants.dart # API endpoint paths
│   ├── theme/
│   │   ├── app_colors.dart    # Dark theme colors + severity colors
│   │   └── app_theme.dart     # ThemeData configuration
│   ├── router/
│   │   └── app_router.dart    # GoRouter (5 routes)
│   └── network/
│       └── api_client.dart    # Dio + JWT interceptor
├── features/
│   ├── auth/
│   │   ├── data/auth_repository.dart
│   │   ├── domain/auth_notifier.dart  # Riverpod state
│   │   └── presentation/login_page.dart
│   ├── dashboard/
│   │   ├── data/dashboard_repository.dart
│   │   ├── domain/dashboard_notifier.dart
│   │   └── presentation/dashboard_page.dart  # Stats + chart
│   ├── alerts/
│   │   ├── data/alert_repository.dart
│   │   ├── domain/alert_notifier.dart
│   │   └── presentation/
│   │       ├── alert_list_page.dart   # Infinite scroll
│   │       └── alert_detail_page.dart # Detail + acknowledge/resolve
│   ├── agents/
│   │   ├── data/agent_repository.dart
│   │   ├── domain/agent_notifier.dart
│   │   └── presentation/agent_list_page.dart
│   └── notifications/
│       └── presentation/
│           └── firebase_messaging_service.dart
└── shared/
    └── widgets/
        ├── alert_card.dart      # Reusable alert card
        ├── severity_badge.dart  # Level badge (color-coded)
        └── status_badge.dart    # Status indicator
```

## API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/login` | ✗ | Login admin → JWT |
| GET | `/api/dashboard` | JWT | Dashboard statistics |
| GET | `/api/alerts` | JWT | Alert list (paginated, filterable) |
| GET | `/api/alerts/:id` | JWT | Alert detail |
| PATCH | `/api/alerts/:id` | JWT | Update status (acknowledge/resolve) |
| GET | `/api/agents` | JWT | Agent list with status |
| POST | `/api/device-token` | JWT | Register FCM token |
| POST | `/api/webhook/wazuh` | API Key | Webhook from Wazuh Manager |

## Database Schema (PostgreSQL)

### users
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| username | VARCHAR | Unique |
| password_hash | VARCHAR | bcrypt |
| role | VARCHAR | Default: 'admin' |
| created_at | TIMESTAMP | |
| updated_at | TIMESTAMP | |

### agents
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| wazuh_agent_id | VARCHAR | Unique, from Wazuh |
| name | VARCHAR | Agent name |
| ip | VARCHAR | |
| status | VARCHAR | active/disconnected/never_connected |
| os_name | VARCHAR | |
| os_version | VARCHAR | |
| last_seen | TIMESTAMP | |
| created_at / updated_at | TIMESTAMP | |

### alerts
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| wazuh_alert_id | VARCHAR | Unique, for dedup |
| rule_id | INT | Wazuh rule ID |
| rule_description | VARCHAR | |
| rule_level | INT | 0-15 severity |
| rule_groups | VARCHAR | Comma-separated groups |
| source_ip | VARCHAR | Attacker IP |
| source_port | INT | |
| destination_ip | VARCHAR | |
| destination_port | INT | |
| protocol | VARCHAR | |
| agent_id | VARCHAR | FK to agents |
| agent_name | VARCHAR | |
| location | VARCHAR | |
| full_log | VARCHAR | Raw log text |
| raw_data | JSONB | Full Wazuh payload |
| timestamp | TIMESTAMP | Alert time |
| status | VARCHAR | new/acknowledged/resolved |
| created_at | TIMESTAMP | |

### device_tokens
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK to users |
| token | VARCHAR | FCM token |
| platform | VARCHAR | android/ios/web |
| created_at / updated_at | TIMESTAMP | |
| UNIQUE(user_id, token) | | |

## Flutter Routes

| Route | Page | Description |
|-------|------|-------------|
| `/login` | LoginPage | Username + password form |
| `/` | DashboardPage | Stats, chart, top IPs, recent alerts |
| `/alerts` | AlertListPage | Infinite scroll alert list |
| `/alerts/:id` | AlertDetailPage | Alert detail + acknowledge/resolve |
| `/agents` | AgentListPage | Agent status list |

## Wazuh Integration

### Custom Integration Script (`backend/wazuh/custom-wazuh.py`)
- Placed in `/var/ossec/integrations/` on Wazuh Manager
- Reads alert JSON from stdin
- Forwards to backend webhook with API key header
- Configured via environment variables:
  - `WEBHOOK_URL`: Backend webhook URL
  - `API_KEY`: Shared secret for authentication

### Wazuh Manager Configuration (`ossec.conf`)
```xml
<integration>
  <name>custom-wazuh</name>
  <hook_url>https://your-domain.com/api/webhook/wazuh</hook_url>
  <level>7</level>
  <alert_format>json</alert_format>
</integration>
```

## Testing Scenarios

### Skenario 1 — Port Scanning
1. Run `nmap` from agent/target to VPS
2. Wazuh detects port scan (rule 5710/5715)
3. Alert sent to backend via webhook
4. Alert stored in database
5. FCM notification to Flutter
6. Alert displayed on dashboard
7. Active Response works (if configured)

### Skenario 2 — SSH Brute Force
1. Run `hydra` for SSH brute force from agent to VPS
2. Wazuh detects multiple failed SSH (rule 5716/5763)
3-7. Same as scenario 1

## Running the Project

### Backend Development
```bash
cd backend
cp .env.example .env    # Edit environment variables
npm install
npx prisma migrate dev  # Run database migrations
npx prisma db seed      # Seed admin (admin/admin123)
npm run dev             # Start development server
```

### Flutter Development
```bash
cd wazuh_app
flutter pub get
flutter run              # Choose web/android/ios
```

### Docker Production
```bash
cd backend
docker compose up -d
```

## Environment Variables

### Backend (.env)
```
PORT=3000
DATABASE_URL=postgresql://wazuh:wazuh123@localhost:5432/wazuh_monitor
JWT_SECRET=change-this-to-random-secret
JWT_EXPIRES_IN=24h
WEBHOOK_API_KEY=change-this-webhook-api-key
FCM_CREDENTIALS_PATH=./firebase-service-account.json
```
