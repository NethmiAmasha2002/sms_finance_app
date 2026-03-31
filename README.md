# 📱 SMS Finance Tracker — Flutter MVP

A Flutter application that parses bank SMS / OTP transaction messages, extracts key financial information, auto-categorizes transactions, and presents them in a clean finance dashboard.

---

## ✅ Features

| Feature | Status |
|---|---|
| SMS parsing (LKR debit/credit format) | ✅ |
| Auto-categorization by merchant keywords | ✅ |
| Transaction list with summary card | ✅ |
| Transaction detail screen | ✅ |
| Category update (reflects instantly on list) | ✅ |
| Paste & parse custom SMS via bottom sheet | ✅ |
| Riverpod state management | ✅ |
| Clean folder structure | ✅ |

---

## 📁 Folder Structure

```
lib/
├── main.dart                          # App entry point, ProviderScope
├── models/
│   └── transaction_model.dart         # TransactionModel, enums, extensions
├── services/
│   ├── sms_parser_service.dart        # Core SMS parsing logic (regex-based)
│   └── sample_sms_service.dart        # Mock/sample SMS messages for demo
├── providers/
│   └── transaction_provider.dart      # Riverpod StateNotifier + derived providers
├── screens/
│   ├── transaction_list_screen.dart   # Home screen: list + summary
│   └── transaction_detail_screen.dart # Detail view + category picker
└── widgets/
    ├── transaction_tile.dart          # List item card widget
    ├── summary_card.dart              # Income/Expense/Balance overview
    └── add_sms_sheet.dart             # Bottom sheet to paste & parse SMS
```

---

## 🏗️ Architecture

```
UI (Screens/Widgets)
       │
       │  ref.watch / ref.read
       ▼
  Providers (Riverpod)           ← StateNotifier holds List<TransactionModel>
       │
       │  calls
       ▼
  Services / Parsers             ← SmsParserService (pure Dart, no Flutter deps)
       │
       │  returns
       ▼
  Models                         ← TransactionModel (immutable, copyWith)
---
---
## 🔍 SMS Parsing

The parser (`SmsParserService`) uses regex to extract:

| Field | Example extracted |
|---|---|
| Amount | `LKR 1,692.00` → `1692.00` |
| Type | `debited` → Expense, `credited` → Income |
| Account | `AC **1114` |
| Merchant | `KEELLS SUPER - KOTTAWA` (cleaned) |
| Date/Time | `25/03/2026 17:46:49` → `DateTime` |

**Supported format:**
```
LKR {amount} debited/credited from/to AC **{last4} via POS at {merchant} {ref}
{dd/MM/yyyy HH:mm:ss}
```

---

## 🗂️ Auto-Categorization

| Keyword match | Category |
|---|---|
| `interchange`, `highway`, `taxi`, `bus` | 🚌 Transport |
| `fuel`, `petrol`, `filling`, `fuel mart` | ⛽ Fuel |
| `super`, `keells`, `cargills`, `grocery` | 🛒 Groceries |
| `restaurant`, `cafe`, `kfc`, `pizza` | 🍽️ Food & Dining |
| `dialog`, `electric`, `water`, `ceb` | 💡 Utilities |
| `cinema`, `netflix`, `gaming` | 🎬 Entertainment |
| `pharmacy`, `hospital`, `clinic` | 💊 Health |
| `shop`, `fashion`, `mall` | 🛍️ Shopping |
| Credited transactions | 💰 Income |
| (no match) | 📋 Other |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart ≥ 3.0.0

### Run the app

```bash
git clone https://github.com/YOUR_USERNAME/sms_finance_app.git
cd sms_finance_app
flutter pub get
flutter run
```

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod ^2.4.9` | State management |
| `riverpod_annotation ^2.3.3` | Riverpod code generation support |
| `intl ^0.18.1` | Date/currency formatting |
| `uuid ^4.2.2` | Unique transaction IDs |

---

## 🧪 Sample SMS Messages Used

```
LKR 150.00 debited from AC **1111 via POS at KOTTAWA INTERCHANGE 10500302
28/03/2026 14:19:13

LKR 1,692.00 debited from AC **1114 via POS at KEELLS SUPER - KOTTAWA 10402483
25/03/2026 17:46:49

LKR 5,970.00 debited from AC **1114 via POS at P AND B FUEL MART 10000759
25/03/2026 18:58:40

LKR 85,000.00 credited to AC **2201 Salary Transfer from XYZ PVT LTD
31/03/2026 09:00:00

... (+ 6 more mock messages)
```

---

## 📸 Demo

> See screen recording in repository root: `demo.mp4`
https://drive.google.com/drive/folders/1ydk1tpl2wG6PAfDw_EP_3ZSG-emrLUqU?usp=sharing
---

## 📝 Notes

- No backend required — all parsing is done locally
- SMS reading permission (`READ_SMS`) is **not** used; messages are mocked for demo safety
- Category updates are reflected **immediately** across screens via Riverpod reactive state
